#!/usr/bin/env python3
"""Analytical projection of SSD-streamed MoE generation speed on other machines.

MODEL (per generated token):   t = B_active / MEM_BW  +  miss_bytes / DISK_BW
  B_active  : bytes of weights touched per token (calibrated from the in-RAM run: B = t_ram * MEM_BW)
  miss_bytes: bytes that must come from disk per token (calibrated from the streamed run)
  Assumes compute is memory-bandwidth bound (true for every row in results.csv) and that
  disk reads overlap nothing (no prefetch), same cache FRACTION as the calibration run.

CALIBRATION (measured on the lab laptop, benchmarks/results.csv, OLMoE-1B-7B Q8_0, 7.36 GB, 4 threads):
  in RAM                       10.36 tok/s   (WSL 14 GB)
  streamed, 5 GB cgroup cache   2.81 tok/s   (read_ahead_kb=256, best measured so far; swap off)
  disk (dd / pread in WSL)     seq 0.285 GB/s, random 128 KB 0.086 GB/s
  lab RAM bandwidth            14.8 GB/s (benchmarks/membw.py)

THIS IS A MODEL, NOT A MEASUREMENT. Limits are printed with the output.
"""
MEM_LAB = 14.8
T_RAM = 1 / 10.36
T_STREAM = 1 / 2.81
SEQ_LAB, RND_LAB = 0.285, 0.086

B = T_RAM * MEM_LAB                      # GB read per token
t_io = T_STREAM - T_RAM                  # seconds per token spent waiting on disk
m_lo, m_hi = t_io * RND_LAB, t_io * SEQ_LAB   # GB of disk traffic per token (bounds)
hit_lo, hit_hi = 1 - m_hi / B, 1 - m_lo / B

print(f"calibration: active bytes/token B = {B:.2f} GB, disk wait = {t_io*1000:.0f} ms/token")
print(f"implied disk traffic = {m_lo*1000:.0f}-{m_hi*1000:.0f} MB/token  => byte hit rate {hit_lo*100:.1f}-{hit_hi*100:.1f}%\n")

# (name, memory GB/s [assumed sustained], disk GB/s for this access pattern [assumed])
machines = [
    ("lab laptop (measured)",                14.8, 0.15),
    ("2020-era laptop, DDR4-3200 dual + NVMe Gen3", 35.0, 1.5),
    ("2023-era laptop, DDR5-5600 dual + NVMe Gen4", 60.0, 3.0),
    ("modern laptop, LPDDR5X + NVMe Gen4 fast",     70.0, 4.0),
]

def tps(mem, disk, miss_gb):
    return 1.0 / (B / mem + miss_gb / disk)

print("A) calibrated hit rate (benchmark workload, same cache fraction 68%)")
print(f"{'machine':48s} {'in-RAM':>8s} {'streamed':>16s}")
for name, mem, disk in machines:
    ram = 1.0 / (B / mem)
    lo = tps(mem, disk, m_hi)   # more disk traffic = slower
    hi = tps(mem, disk, m_lo)
    print(f"{name:48s} {ram:8.1f} {lo:7.1f} - {hi:5.1f} tok/s")

print("\nB) pessimistic: real text routes less repetitively than the benchmark (byte hit rate assumed)")
for h in (0.95, 0.90, 0.80):
    print(f"  hit rate {h*100:.0f}%:")
    for name, mem, disk in machines:
        print(f"    {name:48s} {tps(mem, disk, (1-h)*B):6.2f} tok/s")

print("""
LIMITS (read before quoting any number above):
 1. Calibrated on llama-bench token generation, which uses a near-empty context; routing there is far more repetitive
    than real chat. Section B shows what a lower hit rate does. The routing replay is what pins this down.
 2. Disk speeds for other machines are ASSUMED typical values for this access pattern (~256 KB reads), not measured.
 3. Same cache fraction as the lab run (68% of the file fits). A bigger model on a bigger machine needs its own run.
 4. One model (OLMoE, 64 experts top-8, Q8_0), one OS (WSL2), 3 reps per setting.
""")
