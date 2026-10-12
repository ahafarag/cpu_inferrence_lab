# Post draft — publish-ready (WSL2 + native Linux both measured)

## Reddit (r/LocalLLaMA)

**Title:** On WSL2, a model bigger than your RAM runs ~35x slower than it should. One line fixes it (I checked native Linux too).

I was measuring what limits LLM inference on an old laptop (i7-8550U, 20 GB RAM, SATA SSD, WSL2) and found this by accident:

**WSL2 sets `read_ahead_kb` to 8192 on the root disk. When a model is larger than the page cache (mmap streaming), that makes generation crawl.**

[chart: content/readahead.png]

| OLMoE-1B-7B | cache | default (8192 KB) | read_ahead 128 KB |
|---|---|---|---|
| Q8_0 (7.4 GB) | 5 GB | 0.19 tok/s | **3.2-3.4 tok/s** |
| Q4_K_M (4.2 GB) | 3 GiB | 0.14 tok/s | **4.9 tok/s** |

I repeated the sweep on native Linux (EC2 m6id.xlarge, 16 GiB, NVMe, kernel 6.17, ext4). Same shape: Q4_K_M streamed at 3 GiB cache = **11.8 tok/s at 128 KB vs 0.10 at 8192 KB** (22.9 fully in RAM); Q8_0 at 5 GiB = **6.7 vs 0.22** (14.7 in RAM). Linux defaults to 128 KB, so this is mainly a WSL2 default problem, but the mechanism is general: any setup with large read-ahead pays it.

Fix (resets on reboot):

```bash
dev=$(df --output=source / | tail -1 | xargs basename); dev=${dev%%[0-9]*}
echo 128 | sudo tee /sys/block/$dev/queue/read_ahead_kb
```

Second trap: llama.cpp's default `--repack` copies Q4 weights into private RAM (3.1 GB for a 4.2 GB file), so a Q4 model can't stream and gets OOM-killed under a memory limit. `--no-repack` fixes it, no measurable speed loss on this MoE.

Also measured: llama.cpp, bitnet.cpp and PowerInfer all land at 85-100% of RAM bandwidth / bytes per token on this machine. PowerInfer's sparsity gave no gain here.

Scope: one laptop (WSL2) + one EC2 instance (native Linux), one MoE family, 3-5 reps. If it fits in RAM the setting changes nothing. Scripts, pinned commits, SHA256-verified models, all raw rows (including my wrong early runs, flagged): <repo link>

Question for llama.cpp people: would `madvise(MADV_RANDOM)` on expert tensors be the right fix at the source instead of a system setting?

## LinkedIn (short)

I tried to make LLMs run faster on a 2018 laptop. Most ideas did nothing (activation sparsity, expert prefetch). One setting gave 35x, and it reproduces on native Linux.

On WSL2, the default disk read-ahead is 8 MB. When a model is bigger than RAM, that makes it 17-35x slower. Setting it to 128 KB: 0.14 -> 4.9 tok/s, no code change.

Chart (WSL2 laptop vs native Linux EC2), numbers and scripts to reproduce: <repo link>

---
**Stop rule:** no meaningful engagement within a week -> close the project (PLAN.md).
