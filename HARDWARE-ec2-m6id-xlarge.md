# HARDWARE-ec2-m6id-xlarge.md

Recorded 2026-10-12T17:34:27Z by benchmarks/setup/00_env_report.sh

```
kernel:       Linux 6.17.0-1017-aws x86_64
virt:         amazon
cpu:          Intel(R) Xeon(R) Platinum 8375C CPU @ 2.90GHz
Intel(R) Xeon(R) Platinum 8375C CPU @ 2.90GHz  CPU @ 2.9GHz
cores/thread: 2 physical / 4 logical
flags:        avx2 avx512f fma 
ram:          15703 MB total  swap: 0 MB
root device:  /dev/root (   0        29G)
free disk:    25G
read_ahead_kb: unknown  (/sys/block/root/queue/read_ahead_kb)
cgroup v2:    yes
RAM bandwidth (membw.py, GB/s, read+write counted): 26.5 GB/s
disk seq read (2 GB of olmoe-1b-7b-0924-instruct-q4_k_m.gguf): 430 MB/s
disk random 128 KB: 146 MB/s
```

## Context added by hand (the env report cannot see these)

- **Instance:** AWS EC2 `m6id.xlarge`, us-east-1a, on-demand (~$0.2373/h), Ubuntu 24.04.4 LTS, kernel 6.17.0-1017-aws, Xeon Platinum 8375C (Ice Lake), 2 physical cores / 4 vCPU, 16 GiB RAM, no swap.
- **Why this instance:** closest EC2 match to an ordinary 2023-24 laptop with 16 GB RAM and an NVMe SSD, no GPU (CPU-only project).
- **Where the model lived:** local NVMe instance store `/dev/nvme1n1` (ext4, 217 GB, mounted at `/mnt/nvme`), NOT the 30 GiB gp3 root volume. `read_ahead_kb` default on it: **128** (the native-Linux default). The `read_ahead_kb: unknown` line above is the report tool looking at `/` instead of the model's device; `50_moe_streamed.sh` was patched to tune the device that holds the model file.
- **Disk speed measured on that NVMe** (the 430 / 146 MB/s above): sequential 430 MB/s, random 128 KB 146 MB/s. That is only ~1.5-2x the lab laptop's SATA SSD and well below a typical consumer NVMe, so absolute streamed speeds here are not what a fast laptop NVMe would give.
- **Threads:** `run_llamacpp.sh` used 2 threads (physical cores).
- **Virtualised:** EC2 Nitro, storage is network-less local NVMe but shared hardware; treat absolute numbers as "this instance".
- **Run:** 2026-10-12, llama.cpp f2cc728, OLMoE-1B-7B-0924-Instruct Q4_K_M (`--repack 0`, 3 GiB cgroup = 76% of file) and Q8_0 (5 GiB cgroup = 68%), `read_ahead_kb` 8192/1024/256/128, 3 reps each, `pp32 tg16`. Raw log: `benchmarks/logs/ec2_m6id_xlarge_sweep.txt`; rows in `benchmarks/results.csv` with `host=ec2-m6id-xlarge`.
- **Not repeated here:** the `--repack 1` OOM test (only `--repack 0` was run for Q4).
