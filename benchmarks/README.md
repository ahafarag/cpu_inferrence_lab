# benchmarks/

All numbers in this project come from here. Nothing else counts.

## Files

- `results.csv` — append-only. One row per (engine, model, quant, setting) run.
- `prompts.txt` — the fixed 10-prompt quality set. Do not change after the first run.
- `membw.py` — quick memory-bandwidth estimate.
- `run_llamacpp.sh <model.gguf>` — runs `llama-bench`, parses tok/s, appends a row.
- `run_bitnet.sh`, `run_powerinfer.sh` — same pattern; write them during Phase 0.
- `compare.py` — prints a comparison table from `results.csv`.

## results.csv columns

```
date,engine,engine_commit,model,params_B,quant,size_GB,threads,ctx,prompt_tps,gen_tps,peak_ram_GB,quality_1to5,notes
```

Rules:
- Same `threads` setting across engines for a fair comparison (physical cores, not hyperthreads, as a default).
- Run each config 3 times, record the median.
- `quality_1to5` is the owner's manual score over `prompts.txt`, averaged. Leave blank if not scored.
- `engine_commit` = `git rev-parse --short HEAD` inside the engine repo.

## Setup (WSL)

```bash
mkdir -p ~/engines ~/models
cd ~/engines
git clone https://github.com/ggml-org/llama.cpp && cd llama.cpp && cmake -B build && cmake --build build -j
# bitnet.cpp: follow microsoft/BitNet README (needs clang + cmake)
# PowerInfer: follow SJTU-IPADS/PowerInfer README; cap at 2 hours
```

Models go in `~/models` (gitignored). Download GGUFs from Hugging Face (e.g. Qwen2.5-7B-Instruct Q4_K_M and Q8_0).
