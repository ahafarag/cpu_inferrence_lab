#!/usr/bin/env bash
# Records the environment to HARDWARE-<label>.md (Phase 1b step 1). Usage: HOST_LABEL=vps-xyz 00_env_report.sh [model.gguf]
# The model file (>= 2 GB) is used for the raw disk speed tests; without one those are skipped.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
LABEL="${HOST_LABEL:-$(hostname -s)}"
OUT="$REPO_DIR/HARDWARE-$LABEL.md"
MODEL="${1:-$MODELS_DIR/moe/olmoe-1b-7b-0924-instruct-q8_0.gguf}"
ROOT_SRC="$(df --output=source / | tail -1)"
DEV="$(basename "$ROOT_SRC")"; DEV="${DEV%%[0-9]*}"
RA="/sys/block/$DEV/queue/read_ahead_kb"
ensure_venv

{
echo "# HARDWARE-$LABEL.md"
echo
echo "Recorded $(date -u +%FT%TZ) by benchmarks/setup/00_env_report.sh"
echo
echo '```'
echo "kernel:       $(uname -srm)"
echo "virt:         $(systemd-detect-virt 2>/dev/null || echo unknown)"
echo "cpu:          $(lscpu | awk -F: '/Model name/{gsub(/^ +/,"",$2); print $2}')"
echo "cores/thread: $(lscpu -p=CORE,SOCKET | grep -v '^#' | sort -u | wc -l) physical / $(nproc) logical"
echo "flags:        $(lscpu | grep -o -E 'avx2|avx512f|fma' | sort -u | tr '\n' ' ')"
echo "ram:          $(free -m | awk '/Mem:/{print $2" MB total"}')  swap: $(free -m | awk '/Swap:/{print $2" MB"}')"
echo "root device:  $ROOT_SRC ($(lsblk -d -no ROTA,MODEL,SIZE "/dev/$DEV" 2>/dev/null | head -1))"
echo "free disk:    $(df -h --output=avail / | tail -1 | xargs)"
echo "read_ahead_kb: $(cat "$RA" 2>/dev/null || echo unknown)  ($RA)"
echo "cgroup v2:    $([ -f /sys/fs/cgroup/cgroup.controllers ] && echo yes || echo no)"
echo "RAM bandwidth (membw.py, GB/s, read+write counted): $("$VENV_DIR/bin/python" "$REPO_DIR/benchmarks/membw.py" 2>&1 | grep -oE '[0-9.]+ GB/s')"
if [ -f "$MODEL" ]; then
  [ "$(id -u)" -eq 0 ] && { sync; echo 3 > /proc/sys/vm/drop_caches; } || echo "(not root: page cache not dropped, disk numbers may be inflated)"
  echo "disk seq read (2 GB of $(basename "$MODEL")): $(dd if="$MODEL" of=/dev/null bs=1M count=2048 2>&1 | tail -1 | grep -oE '[0-9.]+ [MG]B/s')"
  [ "$(id -u)" -eq 0 ] && { sync; echo 3 > /proc/sys/vm/drop_caches; }
  echo "disk random 128 KB: $(python3 - "$MODEL" <<'PY'
import os, random, sys, time
f = os.open(sys.argv[1], os.O_RDONLY); size = os.fstat(f).st_size
random.seed(1); n = 4096; t = time.time()
for _ in range(n):
    os.pread(f, 131072, random.randrange(0, size - 131072))
print(f"{n*131072/1e6/(time.time()-t):.0f} MB/s")
PY
)"
else
  echo "disk speed tests skipped (no model file at $MODEL)"
fi
echo '```'
} | tee "$OUT"
echo "wrote $OUT"
