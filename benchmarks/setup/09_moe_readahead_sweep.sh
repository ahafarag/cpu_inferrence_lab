#!/bin/bash
# Same clean setup as the 0.19 tok/s baseline (cgroup 5 GB, swap off, pp32 tg16 3 reps), varying block-device read-ahead.
MODEL=/root/models/moe/olmoe-1b-7b-0924-instruct-q8_0.gguf
DEV=$(df --output=source / | tail -1 | xargs basename)
RA=/sys/block/$DEV/queue/read_ahead_kb
ORIG=$(cat $RA)
echo "device=$DEV read_ahead_kb(original)=$ORIG"
echo +memory > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null
for KB in "$@"; do
  echo $KB > $RA
  G=/sys/fs/cgroup/moe_ra; rmdir $G 2>/dev/null; mkdir $G
  echo $((5*1024*1024*1024)) > $G/memory.max; echo 0 > $G/memory.swap.max
  sync; echo 3 > /proc/sys/vm/drop_caches
  echo "== read_ahead_kb=$(cat $RA)"
  (
    echo $BASHPID > $G/cgroup.procs
    BENCH_P=32 BENCH_N=16 BENCH_R=${BENCH_R:-3} SKIP_PEAK=1 \
    NOTES="MoE OLMoE; cgroup 5GB swap=0, WSL 14GB; read_ahead_kb=$KB; pp32 tg16 ${BENCH_R:-3} reps; CLEAN" \
      timeout 1500 bash [WORKING_COPY_WSL_PATH]/benchmarks/run_llamacpp.sh $MODEL
  )
  grep -E "^pgmajfault " $G/memory.stat
  rmdir $G
done
echo $ORIG > $RA
echo "restored read_ahead_kb=$(cat $RA)"
