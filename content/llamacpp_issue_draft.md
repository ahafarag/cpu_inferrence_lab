# llama.cpp discussion / issue draft — DRAFT (native Linux now measured)

**Title:** mmap streaming of a model larger than RAM on WSL2: default read_ahead_kb=8192 costs 17–35x; and `--repack` (default) makes Q4 models un-streamable

**Setup:** llama.cpp f2cc7282ce0042641df55e0e563b75e824e2b647, CPU-only, 4 threads, WSL2 Ubuntu 24.04 (kernel 6.18), i7-8550U, SATA SSD,
model files from `allenai/OLMoE-1B-7B-0924-Instruct-GGUF` (SHA256 in MODELS.md of the linked repo). Page cache limited with cgroup v2 `memory.max`
and `memory.swap.max=0`; `llama-bench -p 32 -n 16`, 5 reps, sd stored.

**Observation 1 (read-ahead):**

| Model, cache | read_ahead_kb 8192 (WSL2 default) | 128–256 |
|---|---|---|
| Q8_0 7.4 GB, 5 GB cache | 0.19 tok/s | 3.2–3.4 tok/s |
| Q4_K_M 4.2 GB, 3 GiB cache, `--repack 0` | 0.14 tok/s | 4.91 tok/s |

When the file fits in the cache the setting has no clear effect (14.6–16.7 tok/s; one outlier run at 10.4 with repack on and 128 KB, not explained).

**Native Linux replication** (EC2 m6id.xlarge, Ubuntu 24.04, kernel 6.17.0-aws, ext4 on local NVMe instance store, 2 threads, `llama-bench -p 32 -n 16`, 3 reps, cgroup v2 `memory.max`, swap 0):

| Model, cache | in RAM | 8192 KB | 1024 KB | 256 KB | 128 KB (Linux default) |
|---|---|---|---|---|---|
| Q4_K_M 4.2 GB, 3 GiB, `--repack 0` | 22.9 | 0.10 | 2.84 | 9.9 | 11.8 |
| Q8_0 7.4 GB, 5 GiB | 14.7 | 0.22 | 1.97 | 6.0 | 6.7 |

So the penalty is a function of the read-ahead value, not WSL2-specific; WSL2 just ships 8192 KB by default. Disk: 430 MB/s sequential, 146 MB/s random 128 KB.

**Observation 2 (repack):** with the default `--repack 1`, `RssAnon` for OLMoE Q4_K_M is 3,063 MB (weights copied into private memory) vs 57 MB with
`--repack 0`; under a 3 GiB cgroup limit the process is OOM-killed (`memory.events: oom_kill 1`) instead of streaming. Q8_0 shows 55 MB anonymous either way
(not repacked on this AVX2 CPU). On this MoE model `--repack 0` showed no measurable speed loss (14.98 vs 14.64 tok/s in RAM); dense models not tested.

**Questions:**
1. Is a per-tensor `madvise(MADV_RANDOM)` / `posix_fadvise` on expert tensors a reasonable direction, so users do not need a system-wide setting? (Not tested by me.)
2. Should the docs mention that repack must be disabled to stream Q4 types larger than RAM?

**Reproduce:** https://github.com/ahafarag/cpu_inferrence_lab: `benchmarks/setup/50_moe_streamed.sh`, raw rows in `benchmarks/results.csv`.

---
Ready to post. Edit the repo link first.
