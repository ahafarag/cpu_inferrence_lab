#!/usr/bin/env bash
# MoE streaming test: same model in RAM vs. with the page cache limited by a cgroup v2 (swap off), over a read_ahead_kb sweep.
# Needs root and cgroup v2. Appends rows to benchmarks/results.csv via run_llamacpp.sh.
# Usage: 50_moe_streamed.sh [--model FILE] [--cache-gb N] [--readahead "128 256 8192"] [--reps 5]
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
MODEL="$MODELS_DIR/moe/olmoe-1b-7b-0924-instruct-q8_0.gguf"; CACHE_GB=""; RAS="128 256 8192"; REPS=5
while [ $# -gt 0 ]; do case "$1" in
  --model) MODEL="$2"; shift 2;; --cache-gb) CACHE_GB="$2"; shift 2;; --readahead) RAS="$2"; shift 2;; --reps) REPS="$2"; shift 2;;
  *) die "unknown arg $1";; esac; done
[ "$(id -u)" -eq 0 ] || die "needs root (cgroup, drop_caches, read_ahead_kb)"
[ -f /sys/fs/cgroup/cgroup.controllers ] || die "cgroup v2 not available"
[ -f "$MODEL" ] || die "model not found: $MODEL (run 10_download_model.sh olmoe-q8)"
RUN="$REPO_DIR/benchmarks/run_llamacpp.sh"
LABEL="${HOST_LABEL:-$(hostname -s)}"
SIZE_B=$(stat -c %s "$MODEL")
# default cache = 68% of the file (the fraction used on the lab laptop), rounded to whole GiB
[ -n "$CACHE_GB" ] || CACHE_GB=$(python3 -c "import math;print(max(1, round($SIZE_B*0.68/2**30)))")
ROOT_SRC="$(df --output=source / | tail -1)"; DEV="$(basename "$ROOT_SRC")"; DEV="${DEV%%[0-9]*}"
RA="/sys/block/$DEV/queue/read_ahead_kb"; ORIG_RA="$(cat "$RA")"
trap 'echo "$ORIG_RA" > "$RA"; rmdir /sys/fs/cgroup/moe_limit 2>/dev/null || true' EXIT
MEM_AVAIL_GB=$(awk '/MemAvailable/{printf "%.1f", $2/1048576}' /proc/meminfo)
FRACTION=$(python3 -c "print(f'{$CACHE_GB*2**30/$SIZE_B*100:.0f}')")
echo "model=$(basename "$MODEL") ($((SIZE_B/1000000)) MB) cache=${CACHE_GB}GiB (${FRACTION}% of file) MemAvailable=${MEM_AVAIL_GB}GiB read_ahead_kb original=$ORIG_RA host=$LABEL"
python3 -c "import sys; sys.exit(0 if $CACHE_GB < $MEM_AVAIL_GB else 1)" || \
  die "cache limit ${CACHE_GB}GiB >= MemAvailable ${MEM_AVAIL_GB}GiB: the limit would not bind and could push the host into OOM. Use --cache-gb below ${MEM_AVAIL_GB}."

# An "in RAM" reference is only valid if the model fits in available RAM with headroom.
if python3 -c "import sys; sys.exit(0 if $SIZE_B/2**30 + 1.0 < $MEM_AVAIL_GB else 1)"; then
  echo "== in RAM (no limit)"
  sync; echo 3 > /proc/sys/vm/drop_caches
  BENCH_P=32 BENCH_N=16 BENCH_R="$REPS" SKIP_PEAK=1 NOTES="MoE in-RAM; host=$LABEL; pp32 tg16 $REPS reps" bash "$RUN" "$MODEL"
else
  echo "== SKIPPING in-RAM reference: model does not fit in MemAvailable (${MEM_AVAIL_GB}GiB); streamed rows only, no in-RAM ratio"
fi

echo +memory > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || true
for KB in $RAS; do
  G=/sys/fs/cgroup/moe_limit; rmdir "$G" 2>/dev/null || true; mkdir "$G"
  echo $((CACHE_GB * 1024 * 1024 * 1024)) > "$G/memory.max"; echo 0 > "$G/memory.swap.max"
  echo "$KB" > "$RA"; sync; echo 3 > /proc/sys/vm/drop_caches
  echo "== streamed: cgroup ${CACHE_GB}GiB swap=0, read_ahead_kb=$KB"
  (
    echo $BASHPID > "$G/cgroup.procs"
    BENCH_P=32 BENCH_N=16 BENCH_R="$REPS" SKIP_PEAK=1 \
      NOTES="MoE streamed; host=$LABEL; cgroup ${CACHE_GB}GiB swap=0; read_ahead_kb=$KB; pp32 tg16 $REPS reps" \
      timeout 3000 bash "$RUN" "$MODEL"
  )
  grep -E '^pgmajfault ' "$G/memory.stat"
  rmdir "$G"
done
echo "restored read_ahead_kb=$ORIG_RA (via trap)"
