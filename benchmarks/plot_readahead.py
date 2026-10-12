#!/usr/bin/env python3
"""Plot MoE generation speed vs read_ahead_kb from results.csv -> content/readahead.png (needs matplotlib).

Two panels: WSL2 on the lab laptop and native Linux on EC2 m6id.xlarge (host=ec2-m6id-xlarge in the notes).
Only rows tagged read_ahead_kb=N with clean conditions are used:
  - OLMoE Q8_0, cgroup 5 GB/GiB (68% of the file cached)
  - OLMoE Q4_K_M, cgroup 3 GiB (76% cached), repack=0 (streams)   [rows with 'ACTUALLY repack=1' or COLD/FAILED are excluded]
Points are individual invocations (EC2: one mean of 3 reps per row); the line joins the mean per setting.
"""
import csv, os, re
from collections import defaultdict
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
rows = list(csv.DictReader(open(os.path.join(HERE, "results.csv"))))
S8, S4 = "Q8_0, 5 GiB cache (68% of file)", "Q4_K_M, 3 GiB cache (76% of file), --repack 0"
series = {"wsl": defaultdict(lambda: defaultdict(list)), "ec2": defaultdict(lambda: defaultdict(list))}
ref = {"wsl": {}, "ec2": {}}
for r in rows:
    # some notes contain unquoted commas; DictReader puts the overflow under key None, so rejoin it
    n = ",".join([r["notes"] or ""] + (r.get(None) or []))
    m = r["model"]
    if "FAILED" in n or "do not cite" in n or "ACTUALLY" in n or not r["gen_tps"]:
        continue
    h = "ec2" if "host=ec2" in n else "wsl"
    v = float(r["gen_tps"])
    ra = re.search(r"read_ahead_kb=(\d+)", n)
    if "olmoe" in m and "q8_0" in m and ra and re.search(r"cgroup 5Gi?B", n):
        series[h][S8][int(ra.group(1))].append(v)
    if "olmoe" in m and "q4_k_m" in m and ra and "cgroup 3GiB" in n and "repack=0" in n:
        series[h][S4][int(ra.group(1))].append(v)
    if "olmoe" in m and "q8_0" in m and "in-RAM" in n and (("WSL 14GB" in n and h == "wsl") or h == "ec2"):
        ref[h]["Q8_0 fully in RAM"] = v
    if "olmoe" in m and "q4_k_m" in m and "in-RAM (warm)" in n and "repack=0" in n:
        ref[h]["Q4_K_M fully in RAM"] = v

colors = {S8: "#1f77b4", S4: "#d62728"}
titles = {"wsl": "WSL2 on the lab laptop (i7-8550U, SATA SSD)", "ec2": "Native Linux, EC2 m6id.xlarge (16 GiB, NVMe)"}
fig, axes = plt.subplots(1, 2, figsize=(12.5, 4.8), dpi=150, sharey=True)
for ax, h in zip(axes, ["wsl", "ec2"]):
    for label, d in series[h].items():
        xs = sorted(d)
        if len(xs) > 2:
            ax.plot(xs, [sum(d[x]) / len(d[x]) for x in xs], "-", color=colors[label], alpha=0.6)
        for x in xs:
            ax.scatter([x] * len(d[x]), d[x], color=colors[label], s=28, zorder=3)
        ax.scatter([], [], color=colors[label], label=label)
    for (label, v), ls in zip(ref[h].items(), ["--", ":"]):
        ax.axhline(v, color="gray", linestyle=ls, linewidth=1)
        ax.text(0.02, v, f" {label}: {v:.1f} tok/s", transform=ax.get_yaxis_transform(), ha="left", va="bottom", fontsize=8, color="gray")
    ax.axvline(8192, color="black", alpha=0.25, linewidth=1)
    ax.annotate("WSL2 default\n8192 KB" if h == "wsl" else "8192 KB\n(not the default)", xy=(8192, 0.5), xycoords=("data", "axes fraction"),
                xytext=(-8, 0), textcoords="offset points", fontsize=8, ha="right", va="center")
    if h == "ec2":
        ax.axvline(128, color="green", alpha=0.3, linewidth=1)
        ax.annotate("native Linux\ndefault 128 KB", xy=(128, 0.5), xycoords=("data", "axes fraction"), xytext=(6, 0),
                    textcoords="offset points", fontsize=8, ha="left", va="center")
    ax.set_xscale("log", base=2)
    ax.set_yscale("log")
    ax.set_xlabel("read_ahead_kb (block device read-ahead, KB)")
    ax.set_title(titles[h], fontsize=10)
    ax.grid(True, which="both", alpha=0.25)
    ax.legend(loc="lower left", fontsize=8)
axes[0].set_ylabel("generation speed (tokens/s, log scale)")
fig.suptitle("OLMoE-1B-7B streamed from SSD in a limited page cache: generation speed vs read-ahead", fontsize=11)
fig.tight_layout()
out = os.path.join(HERE, "..", "content", "readahead.png")
fig.savefig(out)
print("wrote", os.path.normpath(out))
for h in series:
    print(h, {k: {x: round(sum(v) / len(v), 2) for x, v in d.items()} for k, d in series[h].items()}, ref[h])
