#!/bin/bash
# Limit page cache + process to LIMIT_GB via cgroup v2 with swap disabled (no swap confound), WSL stays at 14 GB.
LIMIT_GB="${1:-5}"
MODEL=/root/models/moe/olmoe-1b-7b-0924-instruct-q8_0.gguf
echo "MemTotal: $(grep MemTotal /proc/meminfo)"
[ -f /sys/fs/cgroup/cgroup.controllers ] || { echo "NO_CGROUP_V2"; exit 2; }
echo "controllers: $(cat /sys/fs/cgroup/cgroup.controllers)"
echo +memory > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null
G=/sys/fs/cgroup/moe_limit
rmdir $G 2>/dev/null; mkdir $G || { echo CGROUP_MKDIR_FAILED; exit 3; }
echo $((LIMIT_GB*1024*1024*1024)) > $G/memory.max
echo 0 > $G/memory.swap.max
echo "memory.max=$(cat $G/memory.max) swap.max=$(cat $G/memory.swap.max)"
sync; echo 3 > /proc/sys/vm/drop_caches
echo "swap before: $(grep SwapFree /proc/meminfo)"
echo $$ > $G/cgroup.procs
BENCH_P=32 BENCH_N=16 BENCH_R=3 SKIP_PEAK=1 \
NOTES="MoE OLMoE 64e top-8; streamed via cgroup memory.max=${LIMIT_GB}GB swap=0, WSL 14GB; pp32 tg16 3 reps" \
  timeout 2400 bash [WORKING_COPY_WSL_PATH]/benchmarks/run_llamacpp.sh $MODEL
echo "EXIT=$?"
echo "swap after:  $(grep SwapFree /proc/meminfo)"
grep -E "^(file|anon|pgmajfault) " $G/memory.stat
echo $$ > /sys/fs/cgroup/cgroup.procs
rmdir $G
