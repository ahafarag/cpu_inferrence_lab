# benchmarks/setup/

Portable, pinned setup for everything in `../results.csv`. Tested on Ubuntu 24.04 under WSL2 (see "Tested" below).

```bash
# prerequisites (Debian/Ubuntu)
sudo apt install build-essential cmake clang lld git curl python3 python3-venv util-linux
cd <repo>
bash benchmarks/setup/run_all.sh                  # env, llamacpp, baselines, bitnet, moe, routing
bash benchmarks/setup/run_all.sh --stages "env llamacpp"   # just the environment record + llama.cpp
sudo bash benchmarks/setup/run_all.sh --stages "moe"       # MoE streaming needs root (cgroup, drop_caches, read_ahead_kb)
```

| Script | What |
|---|---|
| `common.sh` | directories (`ENGINES_DIR`, `MODELS_DIR`, `VENV_DIR`), pinned engine commits, clean PATH |
| `models.tsv` | model keys, pinned HF revisions, sizes, SHA256 |
| `00_env_report.sh` | writes `HARDWARE-<label>.md` (CPU, RAM, disk, `read_ahead_kb`, RAM bandwidth, raw disk speeds) |
| `10_download_model.sh <key>` | resumable download + SHA256 verification; skips verified files |
| `20_build_llamacpp.sh` | pinned llama.cpp, CPU-only |
| `21_build_routing_tool.sh` | expert-routing logger (`../routing/moe_routing.cpp`) |
| `30_setup_bitnet.sh` | pinned bitnet.cpp + 2B-4T i2_s model |
| `40_build_powerinfer.sh`, `41_powerinfer_model.sh` | pinned PowerInfer; FP16 download (15 GB) + Q4_0 quantize (peak ~20 GB disk) |
| `50_moe_streamed.sh` | MoE in-RAM vs cgroup-limited streaming over a `read_ahead_kb` sweep |
| `run_all.sh` | stages above, then `compare.py` |

Override locations with env vars: `ENGINES_DIR`, `MODELS_DIR`, `VENV_DIR`, `HOST_LABEL` (tags rows and the HARDWARE file).
Model files and builds are never written into the repo.

## Disk and memory you need

| Stage | Disk | RAM |
|---|---|---|
| llama.cpp + Qwen Q4 | ~7 GB | 8 GB |
| bitnet.cpp | ~3 GB | 4 GB |
| MoE (OLMoE Q8_0) | ~8 GB | in-RAM needs ≥ 9 GB; streaming runs with a 5 GiB limit |
| PowerInfer (optional) | ~20 GB peak | 6 GB |

## Known environment traps (all hit while building this)

- WSL2 appends the Windows PATH, so cmake finds Windows OpenSSL/gettext headers (`libintl_snprintf` error). `common.sh` resets PATH.
- `llama-cli` needs `-st --simple-io -c 2048` when scripted; `-no-cnv` hangs on the pinned build.
- PowerInfer's `llama-bench` cannot load `.powerinfer.gguf`; `run_powerinfer.sh` parses `main` timings.
- Limit the page cache with a **cgroup v2** `memory.max` and `memory.swap.max=0`, not WSL `.wslconfig` (swap confound, restarts).
- The WSL virtual disk keeps its peak size after deletions; compact it with `diskpart` (`compact vdisk`) if C: fills up.
- Sparse VHD mode is disabled by WSL for data-safety reasons; do not force `--allow-unsafe`.

## Docker (untested)

`../../Dockerfile` builds llama.cpp, the routing tool and PowerInfer in an Ubuntu 24.04 image; models and results live in volumes.
**It has not been built or run yet** (Docker daemon was not running when it was written). A container on Windows shares the WSL2
kernel, so it reproduces the software stack, not native-Linux disk behaviour. The cgroup/`read_ahead_kb` stage needs
`--privileged`.

## Tested

| Date | Host | Result |
|---|---|---|
| 2026-10-12 | lab laptop, WSL2 Ubuntu 24.04 | `10_download_model.sh` (SHA256 verified existing Qwen Q4_K_M + OLMoE Q8_0), `00_env_report.sh`, `20_build_llamacpp.sh` from an empty directory: pinned `f2cc7282…` built in 7m47s (8 jobs), `llama-bench` smoke run OK (Qwen Q4_K_M pp16 7.00 / tg8 2.75 tok/s). **Not yet exercised end to end:** `30_setup_bitnet.sh`, `40/41` PowerInfer, `50_moe_streamed.sh` (rewritten from the working raw scripts), `run_all.sh`, Dockerfile |

VPS walkthrough: `VPS.md`.
