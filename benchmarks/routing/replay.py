#!/usr/bin/env python3
"""Replay recorded MoE expert routing through cache policies (LRU, LFU, Belady oracle).

Input : benchmarks/routing/logs/*.routes.txt  (lines "ROUTE <layer> <tok> e0..e7", from llama-moe-routing)
Model : OLMoE-1B-7B, 16 MoE layers x 64 experts, top-8. One cache entry = one (layer, expert) slice = 3 matrices.
        Non-expert weights (attention, embeddings, ~0.5 GB) are assumed always resident.
Metric: slice-level hit rate, and implied generation tok/s using the calibrated model of project_streaming.py.

Usage: replay.py [capacity_slices ...]    (default sweep around the 5 GB lab cache)
"""
import glob, heapq, os, sys
from collections import OrderedDict, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
N_LAYERS, N_EXPERTS, TOPK = 16, 64, 8
SLICE_MB = 3 * 2048 * 1024 * 34 / 32 / 1e6          # Q8_0 = 34 bytes per 32 weights -> 6.685 MB
T_RAM = 1 / 10.36                                    # s/token fully in RAM (measured)
DISK_GBPS = (0.086, 0.285)                           # lab disk: random 128 KB / sequential (measured)


def load(path):
    per_tok = defaultdict(lambda: defaultdict(list))   # tok -> layer -> experts
    with open(path) as f:
        for line in f:
            if not line.startswith("ROUTE "):
                continue
            p = line.split()
            layer, tok = int(p[1]), int(p[2])
            per_tok[tok][layer] = [int(x) for x in p[3:]]
    # llama.cpp prunes the last layer to the output token only, so that layer has 1 row, not n_tokens.
    # Keep only layers present for every token; the replay then covers N_LAYERS-1 layers.
    count = defaultdict(int)
    for tok in per_tok:
        for layer in per_tok[tok]:
            count[layer] += 1
    full = {l for l, c in count.items() if c == len(per_tok)}
    seq = []
    for tok in sorted(per_tok):
        for layer in sorted(per_tok[tok]):
            if layer not in full:
                continue
            for e in per_tok[tok][layer]:
                seq.append((layer, e))
    return seq, len(per_tok)


def sim_lru(seq, cap):
    c, hits, flags = OrderedDict(), 0, []
    for k in seq:
        if k in c:
            c.move_to_end(k); hits += 1; flags.append(1)
        else:
            flags.append(0)
            c[k] = 1
            if len(c) > cap:
                c.popitem(last=False)
    return flags


def sim_lfu(seq, cap):
    cnt, c, flags = defaultdict(int), set(), []
    for k in seq:
        cnt[k] += 1
        if k in c:
            flags.append(1)
        else:
            flags.append(0)
            if len(c) >= cap:
                victim = min(c, key=lambda x: cnt[x])
                c.discard(victim)
            c.add(k)
    return flags


def sim_belady(seq, cap):
    n = len(seq)
    nxt, last = [n] * n, {}
    for i in range(n - 1, -1, -1):
        nxt[i] = last.get(seq[i], n)
        last[seq[i]] = i
    in_cache, heap, flags = {}, [], []     # key -> next use ; max-heap by next use (lazy)
    for i, k in enumerate(seq):
        if k in in_cache:
            flags.append(1)
        else:
            flags.append(0)
            if len(in_cache) >= cap:
                while True:
                    neg, v = heapq.heappop(heap)
                    if v in in_cache and in_cache[v] == -neg:
                        del in_cache[v]
                        break
            in_cache[k] = nxt[i]
            heapq.heappush(heap, (-nxt[i], k))
            continue
        in_cache[k] = nxt[i]
        heapq.heappush(heap, (-nxt[i], k))
    return flags


def rate(flags, lo=0.0):
    a = flags[int(len(flags) * lo):]
    return sum(a) / len(a)


def main():
    caps = [int(x) for x in sys.argv[1:]] or [256, 512, 680, 800]
    files = sorted(glob.glob(os.path.join(HERE, "logs", "*.routes.txt")))
    if not files:
        sys.exit("no routing logs found; run run_routing.sh first")
    streams, names, ntoks = [], [], []
    for f in files:
        seq, nt = load(f)
        streams.append(seq); names.append(os.path.basename(f).replace(".routes.txt", "")); ntoks.append(nt)
        print(f"{names[-1]:16s} tokens={nt:4d} accesses={len(seq)} distinct slices={len(set(seq))}/{N_LAYERS*N_EXPERTS}")
    session = [k for s in streams for k in s]
    n_session_tok = sum(ntoks)
    print(f"session (all prompts concatenated): tokens={n_session_tok} accesses={len(session)}\n")

    per_token_mb = TOPK * N_LAYERS * SLICE_MB
    layers_seen = len({l for l, _ in session})
    print(f"expert bytes touched per token = {per_token_mb:.0f} MB (slice = {SLICE_MB:.2f} MB); "
          f"replay covers {layers_seen}/{N_LAYERS} layers (last layer pruned by llama.cpp), hit rate applied to all {N_LAYERS}\n")
    # cache capacity applies to the 15 replayed layers' share of the cache
    caps = [max(1, round(c * layers_seen / N_LAYERS)) for c in caps]
    print("Session stream, steady state (second half), slice hit rate and implied tok/s on the lab laptop")
    print(f"{'cap(slices)':>11s} {'cap(GB)':>8s} | {'LRU':>14s} | {'LFU':>14s} | {'oracle':>14s} | oracle/LRU miss ratio")
    for cap in caps:
        out = {}
        for name, fn in (("LRU", sim_lru), ("LFU", sim_lfu), ("ORACLE", sim_belady)):
            fl = fn(session, cap)
            out[name] = rate(fl, 0.5)
        def tps(h):
            miss_mb = (1 - h) * per_token_mb
            lo = 1 / (T_RAM + miss_mb / 1000 / DISK_GBPS[1])
            hi = 1 / (T_RAM + miss_mb / 1000 / DISK_GBPS[0])
            return hi, lo
        cells = []
        for name in ("LRU", "LFU", "ORACLE"):
            h = out[name]; a, b = tps(h)
            cells.append(f"{h*100:5.1f}% {a:4.1f}-{b:4.1f}")
        ratio = (1 - out["ORACLE"]) / max(1e-9, (1 - out["LRU"]))
        print(f"{cap:11d} {cap*SLICE_MB/1000:8.2f} | {cells[0]:>14s} | {cells[1]:>14s} | {cells[2]:>14s} | {ratio:.2f}")

    print("\nPer-prompt, cold cache (each prompt alone), LRU hit rate, whole stream:")
    for cap in caps:
        print(f"  cap={cap}: " + "  ".join(f"{n.split('_',1)[-1]}={rate(sim_lru(s, cap))*100:.1f}%"
                                           for n, s in zip(names, streams)))


if __name__ == "__main__":
    main()
