# RESEARCH_NOTES.md

Living notes. The `research` agent updates this; every claim about a paper or repo should carry a link once verified. Entries marked **[verify]** were written from memory on 2026-10-12 and need a check against the current repo/paper.

## The constraint

Token generation is memory-bandwidth bound, not compute bound. Each token requires reading all *active* weights once.
- DDR5 desktop CPU: ~50–100 GB/s
- GPU HBM: ~1–3 TB/s
- 7B FP16 = 14 GB per token → ~4 tok/s ceiling at 60 GB/s.

So the only question that matters: **how many bytes must be read per generated token, and how many tokens come out of each read.** Three levers.

## Lever 1 — Read fewer weights (sparsity)

- **Mixture of Experts** — only a fraction of weights active per token. DeepSeek, Mixtral, Qwen-MoE. llama.cpp supports MoE inference **[verify current offload/prefetch features]**.
- **DejaVu** (Liu et al., 2023) — contextual sparsity; predict which FFN neurons / attention heads fire, skip the rest. **[verify]**
- **PowerInfer** (SJTU, 2023) — hot neurons on GPU, cold on CPU, predictor-driven. **PowerInfer-2** (2024) — phones, 47B. Repo: SJTU-IPADS/PowerInfer **[verify build status on WSL]**
- **LLM in a flash** (Apple, 2023) — weights on flash, windowing + row-column bundling. **[verify]**
- **ReLU Strikes Back** (Apple, 2023), **TurboSparse**, **ProSparse** — making SwiGLU models sparse via ReLUfication. **[verify]**
- Open gap (as of these notes): modern SwiGLU models aren't naturally sparse; no easy tool to convert them; MoE expert prefetch from SSD exists in papers (MoE-Infinity, Fiddler **[verify]**) but not as a mature consumer tool.

## Lever 2 — Fewer bits per weight (quantization)

- llama.cpp GGUF Q4_K_M / Q8_0 — standard baseline.
- **BitNet b1.58** (Microsoft, 2024) — ternary weights {-1,0,1}; matmul becomes add/sub. **bitnet.cpp** repo: microsoft/BitNet. Official model: BitNet-b1.58-2B-4T **[verify larger public 1.58-bit models available]**
- Open gap: post-training conversion of existing models to ~1.58-bit without large quality loss. Below 2-bit, PTQ collapses for standard models **[verify latest 2-bit PTQ results, e.g. QuIP#, AQLM]**.

## Lever 3 — More tokens per weight read

- **Speculative decoding** (Leviathan et al.; Chen et al., 2023) — small draft, big verifier. llama.cpp has `--draft` support **[verify flags]**.
- **Medusa** heads, **multi-token prediction** (Meta 2024, DeepSeek-V3 MTP). **[verify]**
- **EAGLE** family — feature-level drafting. **[verify]**

## Engines to benchmark in Phase 0

| Engine | Lever | Repo | Notes |
|---|---|---|---|
| llama.cpp | 2, 3 | ggml-org/llama.cpp | baseline; `llama-bench` gives tok/s directly |
| bitnet.cpp | 2 | microsoft/BitNet | needs its own 1.58-bit models |
| PowerInfer | 1 | SJTU-IPADS/PowerInfer | may not build on WSL; 2-hour cap |

## Questions Phase 0 must answer

1. Measured RAM bandwidth on the owner's machine (not spec sheet).
2. Real tok/s: 7B Q4, 7B Q8, BitNet-2B, (PowerInfer if it builds).
3. Does quality at Q4 / 1.58-bit satisfy the owner for his actual use (code, reasoning, writing)?
4. Which of the 4 ideas has a verified gap (search GitHub + arXiv + HN for each before Gate 0)?
