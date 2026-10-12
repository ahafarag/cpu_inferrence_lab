# IDEAS.md — scored ideas and decisions

Every idea gets a scorecard from `BENEFIT_GATE.md` before any work. Scores below are **preliminary** (set on 2026-10-12, before Phase 0 numbers) and must be re-scored at Gate 0 with real benchmark data.

---

## Idea 1 — MoE expert prefetch from NVMe

**One line:** Predict which experts the next layer needs from the current hidden state, stream them from SSD asynchronously, so a 100B+ MoE runs on 16–32 GB RAM.

**Kill-test:** Instrument a small MoE (e.g. a Qwen/DeepSeek MoE that fits in RAM) in llama.cpp or Python; log routed experts per layer; train a tiny predictor (hidden state of layer L → experts of layer L+1). Question: hit rate ≥ 80%? If no, the idea is dead.

| Part | Prelim score | Notes |
|---|---|---|
| Feasibility | 11/15 | A1 3 (CPU + NVMe), A2 3, A3 2 (needs a MoE that fits), A4 2 (llama.cpp has MoE, no prefetch), A5 1 — **must verify**: search "MoE expert prefetch SSD", "Fiddler", "MoE-Infinity", "PowerInfer-2" before Gate 0 |
| Benefit | 13/18 | B1 3 (very shareable: "DeepSeek-class model on a laptop"), B2 3, B3 1, B4 3, B5 2, B6 1 |
| Cost | C1 0 EUR; C2 ~16 h; C3 ~80 h | |

**Status:** candidate. Highest expected visibility. Gap verification is the risk.

---

## Idea 2 — Sparsity + quantization + speculative decoding, one CPU path

**One line:** Combine three existing techniques in one inference path and measure whether speedups multiply.

**Kill-test:** On llama.cpp, measure Q4 alone, Q4 + speculative (draft model) alone. Then check whether activation sparsity can be added at all for the chosen model (SwiGLU models are not naturally sparse — this may kill it unless a ReLU model is used).

| Part | Prelim score | Notes |
|---|---|---|
| Feasibility | 10/15 | A1 3, A2 2, A3 2, A4 3, A5 0–1 — llama.cpp already does Q4 + speculative; the only new part is sparsity, which depends on Idea 3 |
| Benefit | 9/18 | B1 2, B2 2, B3 0, B4 2, B5 2, B6 1 |
| Cost | C1 0 EUR; C2 ~10 h; C3 unclear | |

**Status:** candidate but weakest standalone. Likely collapses into "a benchmark post about what llama.cpp already does", which is still fine content.

---

## Idea 3 — ReLUfication pipeline

**One line:** Tool that converts an existing Llama/Qwen into a sparse-activation model with light (LoRA-scale) fine-tuning, with a benchmark of quality vs CPU speed.

**Kill-test:** Take a small model (1–3B). Replace SwiGLU gating with ReLU-style gating, fine-tune briefly on the owner's machine, measure activation sparsity and perplexity delta. Question: can we get >70% sparsity with <5% quality loss on CPU-feasible compute?

| Part | Prelim score | Notes |
|---|---|---|
| Feasibility | 7/15 | A1 1 (fine-tuning even 1B on CPU is slow; small GPU helps), A2 2, A3 1, A4 2 (papers exist: ReLU Strikes Back, TurboSparse, ProSparse), A5 1 |
| Benefit | 12/18 | B1 2, B2 2, B3 0, B4 2, B5 3 (strong academic fit), B6 3 (feeds Idea 2) |
| Cost | C1 0–? EUR (may need a GPU session); C2 ~20 h; C3 ~120 h | |

**Status:** best academic fit, worst feasibility on this hardware. Re-score after `HARDWARE.md` is filled. If there is no GPU, likely NO for now.

---

## Idea 4 — KV cache on SSD with semantic eviction

**One line:** Keep long-context KV cache on SSD, evict by attention importance (H2O / StreamingLLM style), so long contexts work on small RAM.

**Kill-test:** Measure KV cache size vs context length for a 7B Q4 in llama.cpp; check what llama.cpp already offers (KV quantization, cache offload). Question: is there a real gap, and is long context something the owner's audience cares about?

| Part | Prelim score | Notes |
|---|---|---|
| Feasibility | 10/15 | A1 3, A2 3, A3 2, A4 2, A5 0–1 — must verify what llama.cpp / vLLM / LMCache already do |
| Benefit | 8/18 | B1 2, B2 1, B3 0, B4 2, B5 2, B6 1 |
| Cost | C1 0 EUR; C2 ~12 h; C3 ~80 h | |

**Status:** candidate, lowest benefit. Narrow audience.

---

## Preliminary ranking (to be re-scored at Gate 0)

1. Idea 1 — if the gap is confirmed, best visibility and benefit.
2. Idea 3 — if a small GPU is available; otherwise park.
3. Idea 2 — mostly becomes content.
4. Idea 4 — park unless Phase 0 shows a surprising gap.

## Pre-gate feasibility read (2026-10-12, after llama.cpp Q4/Q8; NOT the Gate 0 scorecard)

Evidence: own llama.cpp numbers (Q4_K_M pp 8.22 / tg 2.99; Q8_0 pp 5.74 / tg 1.83, generation at the 14.8 GB/s bandwidth ceiling), SATA SSD (~0.5 GB/s), 14 GB WSL RAM, MX150 4 GB, plus quick literature searches (secondary summaries, repos not opened). Re-score properly at Gate 0 after bitnet.cpp and PowerInfer.

| Idea | Read | Reason |
|---|---|---|
| 1 MoE prefetch | **Narrowed, still possible** | Gap is partly occupied (ProMoE, MoBiLE, DALI papers; `bounded-moe` experimental SSD/llama.cpp project). Kill-test (expert-prediction hit rate ≥ 80%) needs no fast disk and is doable. The "100B MoE on a laptop" headline is out: at SATA 0.5 GB/s even 90% hit rate gives ~1 tok/s on a 10B-active model. |
| 2 Sparsity + quant + spec-decode | **Possible, mostly measurement** | Own data caps speculation: prompt processing runs at 8.2 tok/s vs 3.0 tok/s generation, so batch verification is compute-bound; best case ~2.7x, realistic 1.3–1.8x. Novelty is low; value is an honest benchmark. |
| 3 ReLUfication | **NO as a build; YES as a measurement** | Fine-tuning needs a GPU (MX150 4 GB is not enough) = rubric red flag. Converted models already exist (ProSparse-Llama2, TurboSparse-Mistral). Benchmarking them under PowerInfer on CPU is feasible and is Phase 0 task 4. |
| 4 KV cache on SSD | **NO / park** | GQA keeps KV small (Qwen2.5-7B ≈ 56 KB/token → ~1.9 GB at 32k ctx), so RAM is not the bottleneck at this size. SSD-KV is I/O-bound even in vLLM (Tutti, 2026). |

## Gate 0 scorecards (2026-10-12, Opus, with Phase 0 data)

Inputs: `benchmarks/results.csv` (llama.cpp Q4_K_M 2.99 / Q8_0 1.83 tg tok/s; bitnet.cpp 2B 10.94; PowerInfer ReluLLaMA-7B Q4_0 3.05), `HARDWARE.md` (14.8 GB/s RAM, 14 GB WSL RAM, SATA SSD ~0.5 GB/s, MX150 4 GB). Quality scoring (task 5) still open.

Key facts that drive the scores:
1. Every engine generates at ~85–100% of `bandwidth / bytes read per token`. Speed = fewer bytes per token, nothing else.
2. Activation sparsity (PowerInfer, CPU-only) gave **no** gain: 3.05 tok/s = 89% of the dense ceiling for its 4.3 GB file; prompt speed halved. On this CPU the sparsity lever is closed.
3. The SSD is SATA (~0.5 GB/s), ~30x slower than RAM. Anything that streams weights from disk pays that.
4. llama.cpp already mmaps weights, so a MoE larger than RAM *already* streams experts from SSD through the OS page cache (an LRU cache for free). Idea 1's real competitor is that baseline, not "nothing".

### Idea 1 — MoE expert prefetch from SSD → **MAYBE: shrink to a measurement-first kill-test**

| | Score | Why |
|---|---|---|
| A1 own machine | 2 | Kill-test runs here; the payoff (big MoE from SATA) is weak on this disk |
| A2 skills | 2 | Measurement and Python predictor: yes. Async prefetch inside llama.cpp C++: new territory |
| A3 kill-test ≤ 2 weekends | 3 | Shrunk test below is ~8 h |
| A4 base exists | 3 | llama.cpp MoE + mmap + `--n-cpu-moe`; HF transformers for routing logs |
| A5 gap real | 1 | Crowded research (ProMoE, MoBiLE, DALI, Fiddler, MoE-Infinity) and an experimental `bounded-moe`; mmap/page-cache streaming is the free baseline. Repos not opened yet |
| **Feasibility** | **11/15** | |
| B1 visibility | 2 | "MoE bigger than RAM on a 2018 laptop: the real number and where the time goes" is shareable even if negative |
| B2 audience fit | 3 | Infra + cost reduction, exactly the positioning |
| B3 money direct | 0 | |
| B4 money indirect | 2 | Profile piece for inference/infra roles and consulting |
| B5 academic | 1 | Crowded; only a workshop-level negative or characterisation result |
| B6 reuse | 1 | |
| **Benefit** | **9/18** | |
| C1 / C2 / C3 | 0 EUR / ~8 h (shrunk) / ~80 h | C4: delays the owner's other projects by ~1 evening per week |

Decision: passes thresholds narrowly. **GO only on the shrunk kill-test below**, not on building a prefetcher.

**Shrunk kill-test (Phase 1, ≤ 8 h, two evenings):**
1. Pick a small MoE that llama.cpp supports (e.g. OLMoE-1B-7B or Qwen1.5-MoE-A2.7B, ~7–9 GB at Q8_0). Run it in RAM: baseline tok/s.
2. Lower WSL memory (`.wslconfig memory=` below model size) so the same file must stream from SSD via mmap. Measure tok/s again. No new download, no code.
3. Log expert routing per token (HF transformers or llama.cpp debug) and replay it through an LRU cache of the RAM-sized budget: hit rate = what page cache already gets; an oracle prefetcher is the upper bound.

**Stop rules:** if streamed tok/s is within 1.5x of in-RAM → page cache already handles it, no gap, STOP and publish the measurement. If the oracle-prefetch upper bound is < 1.5x better than LRU → prediction cannot pay on this disk, STOP and publish. Only if both gaps are large does a predictor (original kill-test) start.

### Idea 2 — Sparsity + quant + speculative, one CPU path → **NO as a project**

Feasibility 12/15 (A1 3, A2 3, A3 3, A4 3, A5 0) / Benefit 6/18 (B1 2, B2 2, B3 0, B4 1, B5 0, B6 1). The sparsity leg is dead on this CPU (PowerInfer: no gain), and quant + speculative is already in llama.cpp. Kept only as an optional single benchmark row (Qwen2.5-7B Q4 + 0.5B draft), capped at 2 h, after Phase 1. Measured cap for any batch-verification gain here: pp/tg = 8.22/2.99 ≈ 2.7x.

### Idea 3 — ReLUfication pipeline → **NO**

Red flag: needs a GPU for fine-tuning (MX150 4 GB is not enough). And even a perfect conversion would not pay here: sparse inference gave no speedup on this CPU. Converted models (ProSparse, TurboSparse) already exist.

### Idea 4 — KV cache on SSD → **NO**

GQA keeps KV small (Qwen2.5-7B ≈ 56 KB/token → ~1.9 GB at 32k ctx), so RAM is not the bottleneck at this size; SSD-backed KV is I/O-bound even in vLLM (Tutti, 2026), and this disk is SATA. Benefit ≤ 6/18.

### Phase 1 kill-test log (2026-10-12)

OLMoE-1B-7B-0924-Instruct Q8_0 (7.36 GB, 64 experts, top-8, ~1.3B active), llama.cpp f2cc728, 4 threads. All rows in `results.csv`.

| Condition | Gen tok/s | vs in-RAM | Notes |
|---|---|---|---|
| In RAM (WSL 14 GB) | **10.36** | 1x | At the bandwidth ceiling (~10.6) |
| Streamed, cgroup 5 GB, swap off (CLEAN) | **0.19** | **~54x slower** | 0 swapped, 19,776 major faults, pp32 1.11 tok/s |
| Streamed, WSL 5 GB limit (swap confounded) | 0.07 | ~150x | ~0.8 GB swapped; first two runs, do not cite |

Disk (inside WSL, cold): sequential 285 MB/s, random 128 KB reads 86 MB/s. Experts are ~2.2 MB contiguous slices per matrix, so large-read I/O should approach the sequential rate; mmap page faults do not.

**Read-ahead sweep (same clean cgroup setup, 5 GB cache, swap off, pp32 tg16, 3 reps; WSL2 default is 8192 KB):**

| read_ahead_kb | gen tok/s | vs default |
|---|---|---|
| 8192 (WSL2 default) | 0.18, 0.19 | 1x |
| 4096 | 0.57 | 3x |
| 2048 | 1.26, 1.32 | 7x |
| 1024 | 1.82 | 10x |
| 512 | 1.82 | 10x |
| 256 | **2.81** | **15x** |
| 128 (native Linux default) | 2.32 | 12x |
| 64 | 2.12 | 11x |
| 32 | 1.80 | 10x |

**5-rep confirmation (independent invocations, mean of 5 reps each):** 256 KB → 3.21 tok/s; 128 KB → 3.44 tok/s; 8192 KB (default) → 0.19 tok/s. Across all invocations the default is rock-stable (0.18, 0.19, 0.19), while 128–256 KB varies 2.3–3.4 tok/s between invocations (±~15%). Headline: **~12–18x over the WSL2 default**, best setting 128–256 KB, optimum not resolved within noise. No per-rep stddev is stored yet (only `avg_ts`).

Smaller read-ahead wins until ~128–256 KB, then flattens. Native Linux's default (128 KB) already sits in the good region, so this is a **WSL2-specific** finding. Tangible-improvement threshold (>= 2x) met: 15x with no code. 5-rep confirmation of 256 / 128 / 8192 pending. Absolute speed is still ~3.7x below in-RAM; see `benchmarks/project_streaming.py` for the projection model and its limits.

**Routing replay on real text (step 3, 2026-10-12).** 5 varied prompts (code, science, narrative, SQL, Spanish; 994 tokens), expert routing logged with `benchmarks/routing/` (`llama-moe-routing` built from `moe_routing.cpp`), replayed through cache policies at expert-slice granularity (6.68 MB per (layer, expert)); output in `benchmarks/routing/replay_output.txt`. Replay covers 15 of 16 layers (llama.cpp prunes the last layer to the output token).

| Cache for experts | LRU hit | LFU hit | Belady oracle hit | oracle misses / LRU misses |
|---|---|---|---|---|
| 3.2 GB (480 slices) | 80.2% | 70.6% | 92.5% | 0.38 |
| **4.3 GB (638) ≈ the 5 GB lab cache** | **90.8%** | 83.9% | 96.9% | 0.33 |
| 5.0 GB (750) | 95.8% | 91.4% | 98.7% | 0.31 |
| 5.6 GB (844) | 98.4% | 96.6% | 99.5% | 0.30 |

Findings:
1. **The benchmark's 95–98% hit-rate assumption was optimistic for the realistic cache size.** On real text the kernel-style LRU gets ~91% at the lab's cache; implied lab speed 1.0–2.7 tok/s (measured on the benchmark workload: 2.8–3.4).
2. **Cache size dominates.** +0.7 GB of cache moves LRU from 90.8% to 95.8%; +1.3 GB to 98.4%. Cache capacity (lower-bit experts, less resident overhead) is a bigger lever than policy.
3. **Recency beats frequency.** LFU is worse than LRU at every size, so a static "popular experts" scheme does not help; temporal locality is what the OS cache already exploits.
4. **Oracle upper bound: ~3x fewer misses (~2-2.6x tok/s) at the lab cache.** That is perfect future knowledge; a real next-layer predictor is bounded well below it, and prefetch can hide at most the ~0.1 s of compute per token (the run is I/O-bound). Predictor accuracy was NOT measured.

**Stop rule 2 (oracle beats LRU by < 1.5x): technically NOT met (oracle ~3x fewer misses).** But the oracle is not attainable; the practical gain of a predictor is unmeasured and bounded by (4). This is the Gate 1 judgement call (Opus).

**Stop rule 1 (streamed within 1.5x of in-RAM): NOT met, so the idea continues.** The free OS cache does not rescue a model larger than RAM on this SATA SSD.

*[SUPERSEDED by the read-ahead sweep, routing replay and Gate 1 below — kept for the record. The 40%-miss / 0.5 tok/s bound here was wrong: real-text misses are ~9% and the tuned lab run reaches 3.4 tok/s.]*

Open and NOT yet measured (this is what step 3 decides):
- Cache hit rate of the kernel's LRU vs an oracle for the real routing trace (stop rule 2).
- Time per token is ~5.3 s against ~0.1 s of compute, so the run is >98% I/O-bound: prefetch *overlap* can save at most ~2%. Only a better *miss rate* (what is cached) or a better *I/O pattern* (large reads instead of page faults) can help.
- The disk bound: at 285 MB/s, even a zero-overhead scheme with ~40% misses of ~1.4 GB/token tops out near 0.5 tok/s, still ~20x below RAM. Usable "big MoE on a small laptop" is therefore NOT on the table on this SATA disk; the realistic deliverable is the characterisation plus an I/O-pattern fix.

### Finding after Gate 1: llama.cpp weight repacking defeats mmap streaming for Q4 models (2026-10-12)

Found while testing OLMoE Q4_K_M under a 3 GiB cgroup: `llama-bench` was **OOM-killed holding 3.1 GB of anonymous memory** (`memory.events: oom_kill 1`).
Measured peak memory per model and `--repack` setting (`llama-bench -p 32 -n 16 -r 2`, no cgroup; speeds in that run are cache-order noise and not used):

| Model | `--repack` | RssAnon (not evictable) | RssFile (evictable page cache) |
|---|---|---|---|
| OLMoE Q4_K_M (4.2 GB) | 1 (default) | **3,063 MB** | 4,028 MB |
| OLMoE Q4_K_M | 0 | 57 MB | 4,027 MB |
| OLMoE Q8_0 (7.4 GB) | 1 or 0 | 55 MB | ~7,020 MB |

Interpretation: with the default `--repack 1`, llama.cpp's CPU backend re-lays out Q4_K weights at load into **private (anonymous) RAM**. That memory
cannot be evicted or streamed from disk, so a Q4_0/Q4_K model with repack on needs its weights resident (+ the mmapped file cache on top), and a cache
limit below ~3.2 GB kills the process instead of streaming. **Q8_0 is not repacked on this x86 AVX2 CPU**, so all Q8 streaming results are unaffected.
This also explains the 7.45 GB peak RSS of the 4.7 GB Qwen Q4_K_M run (verified, previously only suspected).

Consequences for the write-up:
1. "Use a lower-bit quant that fits" holds, but a Q4 model that *doesn't* fit must be run with `--no-repack` (llama.cpp `-nr`, bench `--repack 0`) to stream at all, at a compute cost.
2. The dense-baseline numbers for Q4_K_M (2.99 tok/s) are llama.cpp **default** behaviour and stay valid as such.
3. Rows 'OLMoE Q4_K_M in-RAM / streamed (first attempt)' in `results.csv` are marked contaminated (cold cache, repack=1) and must not be cited; the corrected matrix replaces them.
4. A second measurement flaw fixed: the "in-RAM" reference must be warmed with a full file read first (`cat file > /dev/null`), not just a cache drop.

**Corrected Q4_K_M matrix (repack really off, warm references, 5 reps, spread = sd across reps; OLMoE-1B-7B Q4_K_M 4.2 GB, WSL2):**

| Cache (cgroup, swap off) | `--repack` | read_ahead_kb | gen tok/s | sd |
|---|---|---|---|---|
| none (in RAM, warm) | 0 | 8192 | 14.98 | 1.17 |
| 5 GiB (file fits, 127%) | 0 | 8192 | 14.56 | 0.77 |
| 5 GiB | 0 | 128 | 16.73 | 1.65 |
| **3 GiB (76% of file)** | 0 | **8192 (WSL2 default)** | **0.14** | 0.04 |
| **3 GiB (76% of file)** | 0 | **128** | **4.91** | 1.23 |
| 3 GiB | **1 (default)** | 128 | **OOM-killed** (exit 137, `oom_kill=1`) | – |
| in RAM / 5 GiB (file fits) | 1 | 8192 / 128 | 14.64 / 14.83 / 10.36 | 0.5 / 0.5 / 1.5 |

What this establishes (and its limits):
1. **The read-ahead effect replicates on a second quantisation of the model: 0.14 → 4.91 tok/s (~35x) at 76% cached.** Combined with Q8_0 (0.19 → 3.2–3.4 tok/s, ~17x at 68% cached) the effect is not specific to one file.
2. **When the file fits in the cache, nothing clearly matters**: 14.6–16.7 tok/s across read-ahead and repack settings, with one unexplained outlier (10.36 tok/s, repack=1, read_ahead 128, sd 1.5).
3. **`--repack` (default on) makes Q4 models un-streamable**: killed at a 3 GiB limit; with `--repack 0` the same model streams at 4.9 tok/s. For this MoE model repack gives no measurable speed gain (in-RAM 14.64 vs 14.98 ± ~1, prompt 25.8 vs 26.2); dense models are NOT tested.
4. **Smaller quant at a smaller cache beats larger quant at a larger cache**: Q4_K_M at 3 GiB (4.9 tok/s) vs Q8_0 at 5 GiB (3.2–3.4).
5. Limits: WSL2 only (native Linux untested), one model family (OLMoE), `llama-bench` generation from a near-empty context (routing is more repetitive than real chat; the routing replay says ~91% hit rate on real text), 16 tokens x 5 reps.
6. Process notes kept for honesty: the first Q4 rows were cold-cache contaminated; a script bug ignored `--repack 0` in one run (relabelled as repack=1 replicates); both are flagged in `results.csv`.

### Gate 1 decision (2026-10-12, Opus)

**Correction to the step-3 note above.** The benchmark measurement is NOT "too optimistic": with 90.8% LRU hits at the lab cache, ~79 MB/token comes from disk; measured 2.8–3.4 tok/s implies 0.19–0.26 s disk wait per token = ~300–400 MB/s effective, at or above the 285 MB/s measured sequential rate. So (a) the benchmark is consistent with a ~91–93% hit rate on real text, and (b) **with read-ahead at 128–256 KB the disk already runs at its sequential ceiling.** On this machine only two levers remain: fewer misses, or overlapping disk I/O with compute.

**Caveat on the disk numbers (added 2026-10-12 after the Phase 1b env report):** the raw disk speed is not stable on this laptop. Same file, same method: sequential 285 MB/s and random 128 KB 86 MB/s in the morning's test, 174 MB/s and 28 MB/s in `HARDWARE-lab-laptop.md` (the env report ran right after SHA256-hashing 12 GB, so Windows-side activity or SSD housekeeping may have been competing; not investigated). Consequences: "the disk is at its sequential ceiling" holds only to roughly ±40%, projections that use 0.285 GB/s inherit that spread, and the streamed benchmark numbers (0.19 → 3.2–3.4 tok/s) should be read as ranges across runs, which the replicate runs already show (2.3–3.4). Any published disk figure needs several measurements, not one.

**Why the predictor is NOT built now:**
1. *Fewer misses* needs eviction informed by future use. Belady shows the ceiling (~3x fewer misses), but a next-layer predictor gives little eviction information; reaching a meaningful fraction of Belady is a research project in a crowded field (ProMoE, MoBiLE, DALI, Fiddler, MoE-Infinity). Feasibility A5 stays 1/3.
2. *Overlap* can hide at most the compute time. On the lab laptop compute is ~0.1 s against ~0.2–0.26 s of I/O, so overlap is worth ≤ ~1.4x here.
3. Overlap matters most where disk time ≈ compute time (fast NVMe). The lab cannot measure that; the owner's VPS might.
4. Owner's rule: continue only with tangible improvement. The predictor has none measured, and its realistic ceiling on this hardware is below the 2x bar used for read-ahead.

**Verdict: Idea 1 as "build a predictor-driven prefetcher" = STOP (parked, not rejected).** The kill-test did its job: it replaced the hypothesis with measured facts and produced one real, cheap, user-facing win.

**Re-entry criterion (fixed now):** reopen only if Phase 1b (or any NVMe machine) shows the in-RAM compute share of streamed time per token ≥ 40% (I/O ≈ compute), so overlap alone could give ≥ 1.5x. First test then: naive prefetch (`madvise(WILLNEED)` of the current token's experts for the next token, no learned predictor) vs the read-ahead-tuned baseline.

**What gets published (deliverable of Phases 0–1):**
1. Four-engine CPU baseline on a 2018 laptop: every engine at 85–100% of `RAM bandwidth / bytes per token`; CPU activation sparsity gave no gain.
2. WSL2 finding: streamed MoE 0.19 → 3.2–3.4 tok/s (12–18x) via `read_ahead_kb` 8192 → 128–256 KB. Scoped to WSL2 until Phase 1b.
3. MoE streaming on real text: LRU hit 80 → 98% as expert cache grows 3.2 → 5.6 GB; recency beats frequency; Belady bound ~3x fewer misses. Practical advice: cache capacity (lower-bit experts; OLMoE Q4 at 4.2 GB fits a 5 GB budget entirely) beats cache cleverness.
4. Projection model (`project_streaming.py`), quoted at its 90–95% hit-rate rows with its limits. Its lab row in section B assumes 0.15 GB/s; the tuned lab actually achieves ~0.3–0.4 GB/s effective.

**Next:** Phase 1b (VPS), which now also carries the re-entry measurement. Candidate for later (needs a scorecard first): a small "local LLM fit-and-tune" check script reporting RAM bandwidth, disk speed, `read_ahead_kb`, and which model/quant fits vs must stream.

### Gate 0 decision

**Pursue Idea 1, shrunk kill-test only (≤ 8 h). Everything else: no.** If the kill-test stops it, the project ends with two public results: the Phase 0 engine benchmark and the MoE-streaming measurement. That is an acceptable outcome, not a failure.

## Rejected

| Idea | Date | Why |
|---|---|---|
| "Make CPU as fast as GPU" in general | 2026-10-12 | Memory-bandwidth bound; only hardware (compute-in-memory) breaks it. Not this owner's field. |
| Train a new 1.58-bit model from scratch | 2026-10-12 | Needs pretraining compute. Red flag. |
| Idea 3 — ReLUfication pipeline | 2026-10-12 (Gate 0) | Needs GPU fine-tuning (red flag), and measured CPU sparse inference gave no speedup on this machine. |
| Idea 4 — KV cache on SSD | 2026-10-12 (Gate 0) | GQA keeps KV small at 7B; SSD-KV is I/O-bound even in vLLM; SATA disk; low benefit. |
| Idea 2 as a project | 2026-10-12 (Gate 0) | Sparsity leg measured dead on this CPU; the rest already exists in llama.cpp. Optional single benchmark row only. |
