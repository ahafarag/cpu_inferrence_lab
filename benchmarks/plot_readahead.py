#!/usr/bin/env python3
"""Plot MoE generation speed vs read_ahead_kb from results.csv -> content/readahead.png (needs matplotlib).

Only rows tagged read_ahead_kb=N with CLEAN / valid conditions are used:
  - OLMoE Q8_0, cgroup 5 GB (68% of the file cached), repack irrelevant (Q8_0 is not repacked)
  - OLMoE Q4_K_M, cgroup 3 GiB (76% cached), repack=0 (streams)  [rows with 'ACTUALLY repack=1' or COLD/FAILED are excluded]
Points are individual invocations; the line joins the mean per setting.
"""
import csv, os, re
from collections import defaultdict
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
rows = list(csv.DictReader(open(os.path.join(HERE, "results.csv"))))
series = defaultdict(lambda: defaultdict(list))   # label -> read_ahead -> [tok/s]
ref = {}
for r in rows:
    # some notes contain unquoted commas; DictReader puts the overflow under key None, so rejoin it
    n = ",".join([r["notes"] or ""] + (r.get(None) or []))
    m = r["model"]
    if "FAILED" in n or "do not cite" in n or "ACTUALLY" in n or not r["gen_tps"]:
        continue
    ra = re.search(r"read_ahead_kb=(\d+)", n)
    if "olmoe" in m and "q8_0" in m and ra and "cgroup 5GB" in n:
        series["Q8_0, 5 GB cache (68% of file)"][int(ra.group(1))].append(float(r["gen_tps"]))
    if "olmoe" in m and "q4_k_m" in m and ra and "cgroup 3GiB" in n and "repack=0" in n:
        series["Q4_K_M, 3 GiB cache (76% of file), --repack 0"][int(ra.group(1))].append(float(r["gen_tps"]))
    if "olmoe" in m and "q8_0" in m and "in-RAM" in n and "WSL 14GB" in n:
        ref["Q8_0 fully in RAM"] = float(r["gen_tps"])
    if "olmoe" in m and "q4_k_m" in m and "in-RAM (warm)" in n and "repack=0" in n:
        ref["Q4_K_M fully in RAM"] = float(r["gen_tps"])

fig, ax = plt.subplots(figsize=(8.2, 4.8), dpi=150)
colors = {"Q8_0, 5 GB cache (68% of file)": "#1f77b4", "Q4_K_M, 3 GiB cache (76% of file), --repack 0": "#d62728"}
for label, d in series.items():
    xs = sorted(d)
    if len(xs) > 2:                      # only draw a line where a curve was actually measured
        ax.plot(xs, [sum(d[x]) / len(d[x]) for x in xs], "-", color=colors[label], alpha=0.6)
    for x in xs:
        ax.scatter([x] * len(d[x]), d[x], color=colors[label], s=28, zorder=3)
    ax.scatter([], [], color=colors[label], label=label)
for (label, v), ls in zip(ref.items(), ["--", ":"]):
    ax.axhline(v, color="gray", linestyle=ls, linewidth=1)
    ax.text(0.02, v, f" {label}: {v:.1f} tok/s", transform=ax.get_yaxis_transform(), ha="left", va="bottom", fontsize=8, color="gray")
ax.axvline(8192, color="black", alpha=0.25, linewidth=1)
ax.annotate("WSL2 default\n8192 KB", xy=(8192, 0.5), xycoords=("data", "axes fraction"), xytext=(-8, 0),
            textcoords="offset points", fontsize=8, ha="right", va="center")
ax.set_xscale("log", base=2)
ax.set_yscale("log")
ax.set_xlabel("read_ahead_kb (block device read-ahead, KB)")
ax.set_ylabel("generation speed (tokens/s, log scale)")
ax.set_title("OLMoE-1B-7B streamed from SATA SSD in a limited page cache (WSL2, i7-8550U)", fontsize=10)
ax.grid(True, which="both", alpha=0.25)
ax.legend(loc="lower left", fontsize=8)
fig.tight_layout()
out = os.path.join(HERE, "..", "content", "readahead.png")
fig.savefig(out)
print("wrote", os.path.normpath(out), {k: {x: round(sum(v) / len(v), 2) for x, v in d.items()} for k, d in series.items()}, ref)
