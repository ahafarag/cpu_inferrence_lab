#!/usr/bin/env bash
# Usage: benchmarks/run_powerinfer.sh <model.powerinfer.gguf> [threads] [quant_label]
# PowerInfer's llama-bench cannot load .powerinfer.gguf, so this runs `main` 3x and reads llama_print_timings.
# pp = "prompt eval" tok/s on a ~500-token prompt, tg = "eval" tok/s over 128 generated tokens (median of 3).
# Appends one row to results.csv. CPU-only (no VRAM budget), same thread default as run_llamacpp.sh.
set -euo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

MODEL="${1:?model path}"
THREADS="${2:-$(lscpu -p=CORE,SOCKET | grep -v '^#' | sort -u | wc -l)}"
QUANT="${3:-$(basename "$MODEL" | grep -oE 'q[0-9]_?[0-9a-z]*' | head -1 | tr a-z A-Z || echo unknown)}"
PI_DIR="${PI_DIR:-$HOME/engines/PowerInfer}"
OUT="$(cd "$(dirname "$0")" && pwd)/results.csv"
MAIN="$PI_DIR/build/bin/main"
[ -x "$MAIN" ] || { echo "main not found at $MAIN"; exit 1; }

COMMIT=$(git -C "$PI_DIR" rev-parse --short HEAD)
SIZE_GB=$(python3 -c "import os;print(round(os.path.getsize('$MODEL')/1e9,2))")
CTX=2048
PROMPT_FILE="$(mktemp)"
python3 - "$PROMPT_FILE" <<'PY'
import sys
text = ("Explain in detail how memory bandwidth limits token generation speed in large language model inference "
        "on a laptop CPU, and why quantization helps. ") * 24
open(sys.argv[1], "w").write(text)
PY

python3 - "$MAIN" "$MODEL" "$THREADS" "$PROMPT_FILE" "$OUT" "$COMMIT" "$QUANT" "$SIZE_GB" "$CTX" <<'PY'
import datetime, os, re, resource, statistics, subprocess, sys
main, model, threads, prompt, out, commit, quant, size, ctx = sys.argv[1:10]
pp, tg, ntok = [], [], None
for i in range(3):
    r = subprocess.run([main, "-m", model, "-t", threads, "-c", ctx, "-b", "512", "-n", "128",
                        "-f", prompt, "--ignore-eos"],
                       stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
                       text=True, timeout=1800, check=True)
    m_pp = re.search(r"prompt eval time =.*?/\s*(\d+) tokens.*?([\d.]+) tokens per second", r.stderr)
    m_tg = re.search(r"\n[^\n]*\beval time =.*?/\s*(\d+) runs.*?([\d.]+) tokens per second", r.stderr)
    if not (m_pp and m_tg):
        sys.exit("could not parse llama_print_timings:\n" + r.stderr[-800:])
    ntok = int(m_pp.group(1))
    pp.append(float(m_pp.group(2))); tg.append(float(m_tg.group(2)))
    print(f"rep {i+1}: prompt {ntok} tok {pp[-1]:.2f} tok/s, gen {tg[-1]:.2f} tok/s", flush=True)
peak = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss / 1024 / 1024
if peak < 0.5:
    sys.exit(f"peak RSS {peak:.2f} GB implausibly low")
row = (f"{datetime.date.today()},PowerInfer,{commit},{os.path.basename(model).replace('.gguf','')},6.74,{quant},"
       f"{size},{threads},{ctx},{statistics.median(pp):.2f},{statistics.median(tg):.2f},{peak:.2f},,"
       f"median of 3; sparse CPU-only; pp on {ntok}-token prompt")
open(out, "a").write(row + "\n")
print("appended:", row)
PY
rm -f "$PROMPT_FILE"
