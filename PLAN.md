# PLAN.md

## Status

- **Date:** 2026-10-12
- **Phase:** Gate 0 passed (2026-10-12) → **Phase 1: Idea 1 shrunk kill-test**, steps 1–2 DONE (~90 min vs 45 min estimate = 2× limit, stopped to report). **Stop rule 1 not met: streamed OLMoE Q8_0 is ~54× slower than in-RAM (0.19 vs 10.36 tok/s, clean cgroup run).** Tangible improvement confirmed with 5 reps: WSL2 `read_ahead_kb` 8192 → 128/256 gives 0.19 → 3.2–3.4 tok/s (~12–18x). Step 3 DONE: real-text routing replay measured LRU hit 90.8% at the lab cache (not 95–98%), oracle ~3x fewer misses (unattainable upper bound), cache size dominates, LFU worse than LRU. **Gate 1 (Opus, 2026-10-12): predictor-driven prefetcher STOPPED (parked with a written re-entry criterion); publish Phases 0–1; go to Phase 1b.** Key correction: after read-ahead tuning the lab disk already runs at its sequential ceiling (~300–400 MB/s effective vs 285 measured), so only fewer misses or I/O/compute overlap remain, and neither clears the 2x bar on this hardware. Phase 1 effort: ~4 h of 8 h. Phase 0 task 5 (owner quality scoring) still open.
- **Gate 0 decision:** Idea 1 = MAYBE → GO on a shrunk, measurement-first kill-test only (F 11/15, B 9/18). Ideas 2, 3, 4 = NO (scorecards and reasons in `IDEAS.md`). Driver: every engine runs at ~85–100% of the bandwidth ceiling, CPU sparsity gave no gain, SSD is SATA, and llama.cpp mmap already streams MoE experts through the page cache.
- **PowerInfer (8bd56d6), ReluLLaMA-7B Q4_0 (quantized locally from the FP16 PowerInfer GGUF), CPU-only, 4 threads:** pp 4.22 (674-token prompt) / tg 3.05 tok/s, peak RAM 5.11 GB, median of 3. Sparse inference is active but gives **no gain over dense on this CPU**: 3.05 tok/s is ~89% of the dense bandwidth ceiling for a 4.3 GB model (3.44), and prompt processing is half of llama.cpp's. Different base model from Qwen, so compare against the ceiling, not Qwen's number. PowerInfer's `llama-bench` cannot load `.powerinfer.gguf`; `run_powerinfer.sh` parses `main` timings. Build took ~5 min, model prep ~25 min (15 GB download + 8.6 min quantize).
- **bitnet.cpp (0b341e5), BitNet-b1.58-2B-4T i2_s, 4 threads:** pp 42.77 / tg 10.94 tok/s, peak RAM 1.33 GB. Generation at ~88% of its bandwidth ceiling (14.8 / 1.19 GB). Per parameter it is NOT faster than Qwen Q4 (26 vs 23 B-params/s); the gain comes from being a 2.4B model with a 1.2 GB footprint. Quality vs Qwen 7B is unmeasured (needs owner scoring).
- **Results (llama.cpp f2cc728, 4 threads, ctx 2048, Qwen2.5-7B-Instruct):** Q4_K_M pp 8.22 / tg 2.99 tok/s; Q8_0 pp 5.74 / tg 1.83 tok/s. Generation matches the bandwidth ceiling (14.8 GB/s / model size): Q8_0 at 100%, Q4_K_M at ~95%. Run-to-run spread on Q4 was 2.61–2.99 tg (one contaminated run, 1.78, discarded); take more reps before publishing.
- **Done this session:** `HARDWARE.md` filled; `.wslconfig` 14 GB; working copy on `C:`, `G:` is backup via `sync.ps1`; llama.cpp built CPU-only; Ollama models removed on owner's instruction (C: free 27 GB).
- **Next task (Phase 1 step 3, on Sonnet, needs owner OK):** build `llama-eval-callback`, log `ffn_moe_topk` per layer/token for ~5 prompts of 64–128 tokens, replay through (a) LRU at the cgroup-equivalent cache size, (b) frequency-based, (c) Belady oracle; report hit rates and implied tok/s at 285 MB/s. Also test an I/O-pattern fix (large expert-sized reads / `madvise`) against the 0.19 baseline. Stop rules in `IDEAS.md`. Open: owner quality scoring (task 5); re-download Qwen Q8_0 if scoring includes it.
- **Queued after Phase 1 step 3:** Phase 1b — native-Linux reproduction on the owner's VPS (see its section below); prerequisite is parameterising `benchmarks/setup/`, `MODELS.md`, `Dockerfile`.
- **Method note:** limit cache with a cgroup v2 (`/sys/fs/cgroup/<g>/memory.max`, `memory.swap.max=0`), not `.wslconfig` (swap confound, restarts). `.wslconfig` is back at 14 GB.
- **Storage (2026-10-12):** C: dropped to 6.9 GB free because the WSL virtual disk keeps its peak size after deletions. Fixed with `diskpart compact vdisk` (elevated, owner approved UAC): ext4.vhdx 51.65 → 37.53 GB, C: free 21.1 GB. Sparse mode was NOT used (WSL disables it over data-corruption risk). Repeat after any large model churn: `wsl --shutdown`, then diskpart `select vdisk file=<ext4.vhdx>` / `attach vdisk readonly` / `compact vdisk` / `detach vdisk`. Nothing of the owner's was deleted.
- **Lessons (put in the write-up):** WSL inherits the Windows PATH, which broke the build via PostgreSQL's OpenSSL/gettext headers; `llama-cli` needs `-st --simple-io -c 2048` for scripted runs; peak RSS (7.5 GB for a 4.7 GB model) includes llama.cpp's weight repacking.
- **Storage rule:** `D:\models` and anything else the owner has not named stays untouched. Before any large download, check C: free; if < 10 GB free, ask what to remove.
- **Blockers:** none

(Update this block at the end of every session.)

---

## Why this project exists

The owner wants a project that (1) is technically real, (2) produces public, measurable results fast, and (3) creates value for him: visibility as an AI/infra engineer, audience, opportunities, income. Many past AI projects produced neither results nor income. This one is structured so that even Phase 0 alone produces publishable output.

Rule of the project: **every phase ends with a gate, and every gate can say STOP.**

---

## Phase 0 — Baseline measurement (target: 1–2 weeks, evenings)

Goal: know, with numbers, what the owner's machine can do today with the best existing CPU-first engines.

Tasks:
1. `HARDWARE.md`: CPU model, cores, RAM size and speed, measured memory bandwidth (e.g. `sysbench memory` or a simple numpy copy test), GPU + VRAM if any, SSD type and sequential read speed, WSL version.
2. Build **llama.cpp** in WSL. Run Qwen2.5-7B (or Llama-3.1-8B) at Q4_K_M and Q8_0. Record prompt tok/s, generation tok/s, peak RAM.
3. Build **bitnet.cpp**. Run the official BitNet-b1.58-2B-4T and, if RAM allows, a larger 1.58-bit model. Same metrics.
4. Try **PowerInfer**. If it does not build cleanly on this machine within 2 hours, record "did not build" and move on. Do not sink time here.
5. **Quality check**: the same 10 prompts (5 reasoning, 3 code, 2 writing) on each engine/model, scored 1–5 by the owner. Store prompts in `benchmarks/prompts.txt`.
6. `benchmarks/compare.py` prints one table.
7. **Content**: one LinkedIn post draft in `content/` — "What a 7B/100B model really does on a laptop CPU in 2026: numbers". This is deliverable regardless of what happens next.

**Gate 0:** With the numbers in hand, score ideas 1–4 using `BENEFIT_GATE.md`. Pick at most ONE. Or stop here with a published benchmark post, which is already a win.

---

## Phase 1 — One idea, smallest proof (target: 3–4 weeks)

Only the idea that passed Gate 0. Candidate list (details in `RESEARCH_NOTES.md` and `IDEAS.md`):

1. **MoE expert prefetch from NVMe** — predict next-layer experts, stream them from SSD asynchronously, run a large MoE on 16–32 GB RAM.
2. **Sparsity + quantization + speculative decoding in one CPU path** — combine three existing techniques, measure whether gains multiply.
3. **ReLUfication pipeline** — convert an existing Llama/Qwen into a sparse model with light training; benchmark quality vs CPU speed.
4. **KV cache on SSD with semantic eviction** — long-context on small RAM.

For the chosen idea:
- Write the smallest experiment that can prove or kill the core assumption (e.g. for idea 1: "can we predict next-layer experts with >80% hit rate from the current hidden state?"). Nothing else.
- Time-box: 2 weekends for the kill-test.
- Record result in `IDEAS.md` and `benchmarks/results.csv`.

**Gate 1:** Did the kill-test pass? If no → write it up honestly in `content/` (negative results are publishable and build credibility), go back to Gate 0 or stop.

---

## Phase 1b — Independent reproduction on native Linux (owner's VPS) (target: 1 weekend, ~3 h)

Why: the headline finding so far (WSL2's 8 MB `read_ahead_kb` makes a streamed MoE ~12–15x slower than 128–256 KB) is WSL2-specific as far as tested. Native Linux defaults to 128 KB. A second, different environment is also what makes the results publishable as *reproducible*. Cost: 0 EUR (owner's existing VPS); no paid instances.

**Prerequisite (do first, on the lab laptop, ~1–1.5 h):** parameterise `benchmarks/setup/*.sh` (no hard-coded `/root`, `/mnt/c/...`), add `benchmarks/setup/run_all.sh`, write `MODELS.md` with source URL + SHA256 for every model, and a `Dockerfile` that builds the three engines. Without this the VPS run is not a reproduction, just another one-off.

**Steps on the VPS:**
1. Record the environment into `HARDWARE-vps.md`: `lscpu`, `free -g`, `lsblk -d -o NAME,ROTA,SIZE,MODEL`, `cat /sys/block/*/queue/read_ahead_kb`, kernel (`uname -a`), virtualisation (`systemd-detect-virt`), `benchmarks/membw.py`, and raw disk speed (`dd` sequential 2 GB cold, random 128 KB `pread` as in `09_moe_readahead_sweep.sh`).
2. Run the Phase 0 baselines that fit its RAM (llama.cpp Q4_K_M; bitnet.cpp 2B) with the same scripts — checks that the scripts are portable and gives a second hardware data point.
3. Run the MoE streaming test (OLMoE Q8_0, same cgroup method): in-RAM, then cache limited to ~68% of the file, with `read_ahead_kb` at the VPS default and at 256 / 1024 / 8192.
4. Run `benchmarks/project_streaming.py` with the VPS's measured RAM bandwidth and disk speeds and compare prediction vs measurement (this validates, or breaks, the projection model).

**Record:** one row per run in `results.csv` with `notes` naming the host (`vps-<provider>`), plus the environment file. Same schema, same scripts, same commit hashes.

**VPS caveats (state them in any write-up):** shared vCPUs and noisy neighbours (use 5 reps, report spread); virtualised or network-attached disks (rated IOPS/throughput caps can dominate, so disk numbers are the VPS's, not "NVMe in general"); no GPU; unknown RAM bandwidth until measured. Never put credentials or private data on the box for this; download models directly there to avoid a 7 GB upload.

**Gate 1b — claim check (Opus, ~20 min):**
- Default `read_ahead_kb` on the VPS is already small and 128–256 KB ≈ default → "WSL2-specific" confirmed; publish it as a WSL2 tuning note.
- Default is large (cloud images sometimes are) and tuning helps → finding generalises; publish as a general Linux note.
- Tuning makes no difference → finding is a WSL2 artefact only; say so plainly.
- Projection model off by more than 2x from the measurement → recalibrate before it is quoted anywhere.

**Stop rule:** if the VPS has < 20 GB free disk or < 8 GB RAM (cannot hold a meaningful in-RAM vs streamed comparison for OLMoE Q8_0 at 7.4 GB), run only steps 1 and 4 and record why.

**Amendment 2026-10-12 (owner's Hostinger VPS: 3.9 GB RAM, ~1.8 GB available, no swap, 21 GB free disk, Docker present):** the stop rule would
allow only steps 1 and 4. Because the VPS is *naturally* in the "model bigger than RAM" regime, the read-ahead sweep is still the most
informative test, so the plan is changed to: env record + BitNet 2B baseline + streamed-only OLMoE Q4_K_M (4.2 GB) with a 2 GiB cache
(48% of file; lab used 68%) over `read_ahead_kb` 128/256/1024/8192, no in-RAM ratio, report absolute tok/s and the ratio between
settings, then run `project_streaming.py` with the measured disk speeds. `JOBS=2` for compiles (no swap). Qwen 7B baseline skipped
(would stream and be mislabelled). Runbook: `benchmarks/setup/VPS.md`. Repo reaches the VPS as a `git archive` tarball via `scp`
(no GitHub needed).

**Status 2026-10-12:** prerequisites done — portable pinned setup scripts, `models.tsv` + `MODELS.md` (SHA256), `run_all.sh`,
`Dockerfile` (UNTESTED, daemon was down), `VPS.md`. Fresh pinned llama.cpp build verified from an empty directory (7m47s). Not yet
exercised end to end: BitNet/PowerInfer setup scripts, `50_moe_streamed.sh`, `run_all.sh`. Waiting on the owner to deliver the repo to the VPS.

**Needs from the owner:** SSH access for me is NOT requested; run the scripts yourself and paste or commit the `results.csv` rows and `HARDWARE-vps.md`. Tell me the VPS RAM/disk first so I can size the test.

---

## Phase 2 — Make it usable and public (target: 4–6 weeks)

Only if Gate 1 passed.
- Turn the proof into a small tool with a README, install instructions, and a benchmark table.
- Publish on GitHub. Post on LinkedIn, r/LocalLLaMA, Hacker News. Short demo video (the owner already has a local reels pipeline).
- If academically relevant: draft as a workshop paper / technical report.

**Gate 2:** Did it get traction (stars, replies, inbound messages, a freelance lead)? Measure for 4 weeks. Decide: continue, pivot to consulting on it, or close with a final write-up.

---

## What this project must NOT become

- A new model architecture.
- A competitor to llama.cpp.
- A reason to buy a GPU or rent cloud GPUs "to test properly".
- A fourth open-ended research thread with no public output.

---

## Decision log

| Date | Decision | Why |
|---|---|---|
| 2026-10-12 | Project started; Phase 0 first, benefit gate mandatory | Prior projects wasted effort without measurement or public output |
| 2026-10-12 | Gate 1: stop the predictor (parked, re-entry if I/O ≈ compute on NVMe); publish Phases 0–1; Phase 1b next | Disk at its ceiling after read-ahead tuning; oracle gain unattainable in practice; overlap ≤ ~1.4x on the lab |
| 2026-10-12 | Gate 0: Idea 1 shrunk kill-test only; Ideas 2, 3, 4 rejected | Bandwidth-bound everywhere; CPU sparsity measured no gain; SATA SSD; mmap is the baseline to beat |
