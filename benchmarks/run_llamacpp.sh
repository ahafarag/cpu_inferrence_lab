#!/usr/bin/env bash
# Usage: benchmarks/run_llamacpp.sh <model.gguf> [threads] [quant_label]
# Runs llama-bench (3 reps, mean tok/s from avg_ts) and a short llama-cli run for peak RAM, appends to results.csv.
# threads defaults to PHYSICAL cores (benchmarks/README.md rule).
set -euo pipefail

# WSL appends the Windows PATH; keep the toolchain Linux-only.
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

MODEL="${1:?model path}"
THREADS="${2:-$(lscpu -p=CORE,SOCKET | grep -v '^#' | sort -u | wc -l)}"
QUANT="${3:-$(basename "$MODEL" | grep -ioE 'q[0-9]_[a-z0-9_]+|q[0-9]_[0-9]|f16|bf16' | head -1 | tr a-z A-Z || echo unknown)}"
LLAMA_DIR="${LLAMA_DIR:-${ENGINES_DIR:-$HOME/engines}/llama.cpp}"
ENGINE="${ENGINE:-llama.cpp}"            # row label (bitnet.cpp reuses this script via run_bitnet.sh)
CLI_ARGS="${CLI_ARGS:--st --simple-io}"  # scripted-run flags for llama-cli
BENCH="$LLAMA_DIR/build/bin/llama-bench"
CLI="$LLAMA_DIR/build/bin/llama-cli"
OUT="$(cd "$(dirname "$0")" && pwd)/results.csv"

[ -x "$BENCH" ] || { echo "llama-bench not found at $BENCH"; exit 1; }

COMMIT=$(git -C "$LLAMA_DIR" rev-parse --short HEAD)
SIZE_GB=$(python3 -c "import os;print(round(os.path.getsize('$MODEL')/1e9,2))")
CTX=2048

# llama-bench CSV: pick avg_ts by column name for the pp512 and tg128 rows.
# Overridable for slow cases (e.g. SSD-streamed MoE): BENCH_P / BENCH_N / BENCH_R, SKIP_PEAK=1.
RAW=$("$BENCH" -m "$MODEL" -t "$THREADS" -p "${BENCH_P:-512}" -n "${BENCH_N:-128}" -r "${BENCH_R:-3}" ${BENCH_ARGS:-} -o csv 2>/dev/null)
read -r PP TG PARAMS PPSD TGSD < <(printf '%s\n' "$RAW" | python3 -c '
import csv, sys
rows = list(csv.DictReader(sys.stdin))
pp = next(r for r in rows if r["n_prompt"] != "0" and r["n_gen"] == "0")
tg = next(r for r in rows if r["n_prompt"] == "0" and r["n_gen"] != "0")
print(round(float(pp["avg_ts"]), 2), round(float(tg["avg_ts"]), 2), round(int(pp["model_n_params"]) / 1e9, 2),
      round(float(pp["stddev_ts"]), 2), round(float(tg["stddev_ts"]), 2))
')

# Peak RSS of a short generation (stdin closed, no conversation mode).
if [ "${SKIP_PEAK:-0}" = "1" ]; then PEAK=""; else
PEAK=$(python3 - "$CLI" "$MODEL" "$THREADS" "$CLI_ARGS" <<'PY'
import resource, shlex, subprocess, sys
cli, model, threads, extra = sys.argv[1:5]
subprocess.run([cli, "-m", model, "-t", threads, "-n", "32", "-p", "hi", "-c", "2048", *shlex.split(extra)],
               stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
               timeout=300, check=True)
peak = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss / 1024 / 1024
if peak < 0.5:
    sys.exit(f"peak RSS {peak:.2f} GB is implausibly low; llama-cli did not load the model")
print(f"{peak:.2f}")
PY
)
fi

NAME=$(basename "$MODEL" .gguf)
case "$NAME" in ggml-model-*) NAME="$(basename "$(dirname "$MODEL")")-${NAME#ggml-model-}" ;; esac  # e.g. BitNet-b1.58-2B-4T-i2_s
echo "$(date +%F),$ENGINE,$COMMIT,$NAME,$PARAMS,$QUANT,$SIZE_GB,$THREADS,$CTX,$PP,$TG,$PEAK,,${NOTES:-}${NOTES:+; }sd(pp)=$PPSD sd(tg)=$TGSD n=${BENCH_R:-3}" >> "$OUT"
echo "appended: $ENGINE $QUANT threads=$THREADS pp=$PP tg=$TG peakRAM=${PEAK}GB"
