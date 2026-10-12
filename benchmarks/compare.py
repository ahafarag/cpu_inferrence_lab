#!/usr/bin/env python3
"""Print a comparison table from results.csv (latest row per engine/model/quant)."""
import csv
from pathlib import Path

rows = list(csv.DictReader(open(Path(__file__).with_name("results.csv"))))
if not rows:
    print("results.csv is empty — Phase 0 not started.")
    raise SystemExit

latest = {}
for r in rows:
    latest[(r["engine"], r["model"], r["quant"])] = r

cols = ["engine", "model", "quant", "size_GB", "threads", "prompt_tps", "gen_tps", "peak_ram_GB", "quality_1to5"]
w = {c: max(len(c), *(len(r[c]) for r in latest.values())) for c in cols}
print(" | ".join(c.ljust(w[c]) for c in cols))
print("-+-".join("-" * w[c] for c in cols))
for r in sorted(latest.values(), key=lambda x: -float(x["gen_tps"] or 0)):
    print(" | ".join(r[c].ljust(w[c]) for c in cols))
