# llama.cpp discussion / issue draft — DRAFT

**Title:** mmap streaming of a model larger than RAM on WSL2: default read_ahead_kb=8192 costs 17–35x; and `--repack` (default) makes Q4 models un-streamable

**Setup:** llama.cpp f2cc7282ce0042641df55e0e563b75e824e2b647, CPU-only, 4 threads, WSL2 Ubuntu 24.04 (kernel 6.18), i7-8550U, SATA SSD,
model files from `allenai/OLMoE-1B-7B-0924-Instruct-GGUF` (SHA256 in MODELS.md of the linked repo). Page cache limited with cgroup v2 `memory.max`
and `memory.swap.max=0`; `llama-bench -p 32 -n 16`, 5 reps, sd stored.

**Observation 1 (read-ahead):**

| Model, cache | read_ahead_kb 8192 (WSL2 default) | 128–256 |
|---|---|---|
| Q8_0 7.4 GB, 5 GB cache | 0.19 tok/s | 3.2–3.4 tok/s |
| Q4_K_M 4.2 GB, 3 GiB cache, `--repack 0` | 0.14 tok/s | 4.91 tok/s |

When the file fits in the cache the setting has no clear effect (14.6–16.7 tok/s; one outlier run at 10.4 with repack on and 128 KB, not explained). Native Linux default is 128 KB (not yet tested by me).

**Observation 2 (repack):** with the default `--repack 1`, `RssAnon` for OLMoE Q4_K_M is 3,063 MB (weights copied into private memory) vs 57 MB with
`--repack 0`; under a 3 GiB cgroup limit the process is OOM-killed (`memory.events: oom_kill 1`) instead of streaming. Q8_0 shows 55 MB anonymous either way
(not repacked on this AVX2 CPU). On this MoE model `--repack 0` showed no measurable speed loss (14.98 vs 14.64 tok/s in RAM); dense models not tested.

**Questions:**
1. Is a per-tensor `madvise(MADV_RANDOM)` / `posix_fadvise` on expert tensors a reasonable direction, so users do not need a system-wide setting? (Not tested by me.)
2. Should the docs mention that repack must be disabled to stream Q4 types larger than RAM?

**Reproduce:** <repo link>: `benchmarks/setup/50_moe_streamed.sh`, raw rows in `benchmarks/results.csv`.

---
Post only after the native-Linux result is in, and edit the "not yet tested" parts.
