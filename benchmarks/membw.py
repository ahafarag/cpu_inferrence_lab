#!/usr/bin/env python3
"""Rough memory-bandwidth estimate (GB/s). Not a replacement for sysbench/STREAM, but enough for HARDWARE.md."""
import time
import numpy as np

SIZE_GB = 2
n = SIZE_GB * 1024**3 // 8
a = np.ones(n, dtype=np.float64)
b = np.empty_like(a)

best = 0.0
for _ in range(5):
    t = time.perf_counter()
    np.copyto(b, a)
    dt = time.perf_counter() - t
    gbps = (2 * SIZE_GB) / dt  # read + write
    best = max(best, gbps)
print(f"approx memory bandwidth: {best:.1f} GB/s (copy, read+write counted)")
