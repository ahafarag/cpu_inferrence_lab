# Post draft (LinkedIn / r/LocalLLaMA) — DRAFT, do not publish before the native-Linux check

**Title options**
1. WSL2's default disk read-ahead makes a model bigger than RAM ~35x slower. One setting fixes it.
2. I tried to make LLMs faster on a 2018 laptop. Most ideas failed. One setting gave 35x.

---

I spent a few days measuring what actually limits LLM inference on an old laptop (i7-8550U, 20 GB RAM, SATA SSD, WSL2), and tried to find one real thing to improve. Most of what I tried did not help, which is its own result:

- Every engine I tested (llama.cpp, bitnet.cpp, PowerInfer) generates at 85–100% of `RAM bandwidth / bytes read per token`. Only reading fewer bytes makes it faster.
- CPU activation sparsity (PowerInfer) gave no speedup here.
- Predicting MoE experts to prefetch from SSD: not worth building. After the fix below the disk is already at its sequential ceiling.

What did work, by accident: when a model is **bigger than the page cache** (MoE streamed from SSD via mmap), **WSL2's default `read_ahead_kb` of 8192 is the problem**.

[chart: content/readahead.png]

- OLMoE Q8_0, 5 GB cache (68% of the file): **0.19 → 3.2–3.4 tok/s**
- OLMoE Q4_K_M, 3 GiB cache (76%): **0.14 → 4.9 tok/s** (~35x)
- If the model fits in the cache, the setting changes nothing that I could measure (~15 tok/s; one unexplained 10 tok/s outlier)

Why: an expert is ~2 MB; 8 MB read-ahead pulls in ~4x more than needed and evicts experts that are about to be used.

One more trap: llama.cpp's default `--repack` copies Q4 weights into private RAM, so a Q4 model can't be streamed at all and gets OOM-killed under a memory limit. `--no-repack` fixes it, and cost no measurable speed on this MoE.

Caveats, honestly: one laptop, WSL2 only (native Linux defaults to 128 KB so probably unaffected — checking now), one MoE family, and my first attempts at this were wrong in three different ways (cold cache, a script bug, swap contamination). Those rows are still in the CSV, flagged.

Everything is reproducible from pinned commits and SHA256-verified models: <repo link>

Question for people who know llama.cpp internals: would `madvise(MADV_RANDOM)` / `posix_fadvise` on the expert tensors be the right fix at the source, rather than a system-wide setting? I haven't tested it.

---

**Where to post:** r/LocalLLaMA (title 1), LinkedIn (title 2, shorter, chart first). Only after the VPS check: add one line "native Linux: default 128 KB, effect X".
**Stop rule:** if the post gets no meaningful engagement within a week, close the project (decision already taken, PLAN.md).
