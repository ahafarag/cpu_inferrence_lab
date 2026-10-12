# HARDWARE.md

Measured 2026-10-12.

| Item | Value | How to get it (WSL) |
|---|---|---|
| CPU model | Intel Core i7-8550U @ 1.80 GHz (Kaby Lake R, 15 W laptop part) | `lscpu \| grep "Model name"` |
| Physical cores / threads | 4 cores / 8 threads, AVX2 + FMA, no AVX-512 | `lscpu \| grep -E "^CPU\(s\)\|Core\|Thread"` |
| RAM total | 20 GB (4 GB Samsung + 16 GB module) | `free -g` |
| RAM type / speed | DDR4-2133, mismatched modules (dual-channel only on the first 8 GB, single-channel above) | Windows: `Get-CimInstance Win32_PhysicalMemory` |
| Measured RAM bandwidth (GB/s) | **14.8** (numpy 2 GB copy, read+write counted, best of 5; theoretical dual-channel peak 34 GB/s) | `benchmarks/membw.py` |
| GPU model + VRAM | NVIDIA GeForce MX150, 4 GB (visible in WSL via `nvidia-smi`); Intel UHD 620 iGPU | `nvidia-smi` |
| SSD model, interface | Kingston SA400S37960G, 960 GB SATA III | Windows: `Get-PhysicalDisk` |
| SSD sequential read (GB/s) | not measured yet (SATA III limit ~0.5 GB/s) | `benchmarks/ssdread.sh` or CrystalDiskMark |
| OS / WSL version | Windows 11 Pro 10.0.26200; WSL 3.0.1.0, kernel 6.18.40.1-microsoft-standard-WSL2 | `wsl --version`, `uname -a` |
| WSL memory limit | 14 GB, 4 GB swap (`.wslconfig` set 2026-10-12; was 9.9 GB default) | `%UserProfile%\.wslconfig` |

## Notes

- Ceiling for dense models: `bandwidth_GBps / model_size_GB`. At 14.8 GB/s a 7B Q4_K_M (~4.4 GB) tops out near **3.4 tok/s**, a 7B Q8_0 (~7.7 GB) near **1.9 tok/s**. Treat the measured llama.cpp numbers against these ceilings.
- The 14.8 figure is a numpy copy test, not STREAM. Re-measure with `sysbench` if the ceiling matters for a published claim.
- **WSL cannot read `G:` (Google Drive).** `/mnt/g` is empty. Work happens in `[WORKING_COPY_PATH]`; `G:` is the cloud backup, updated with `sync.ps1`.
- WSL memory was raised from the 9.9 GB default to 14 GB so 7B Q8_0 fits. Leaves ~6 GB for Windows.
- A 4 GB MX150 can offload a few layers but is not a CPU-only baseline. Benchmark CPU-only first (`-ngl 0`); GPU offload is a separate, labelled row.
- Missing in WSL: `cmake`, `sysbench`, numpy (a venv with numpy exists at `~/venv-lab`). `gcc`, `g++`, `git`, `make`, `python3` are present.
