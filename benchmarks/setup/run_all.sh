#!/usr/bin/env bash
# One-command reproduction of the lab results, in stages. Safe to re-run: builds are pinned and models are SHA256-verified.
# Usage: run_all.sh [--stages "env llamacpp baselines bitnet moe routing powerinfer"] [--reps N]
# Defaults skip `powerinfer` (needs ~20 GB peak disk, ~25 min). Run as root for the moe stage (cgroup/read_ahead).
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
STAGES="env llamacpp baselines bitnet moe routing"; REPS=3
while [ $# -gt 0 ]; do case "$1" in
  --stages) STAGES="$2"; shift 2;; --reps) REPS="$2"; shift 2;; *) die "unknown arg $1";; esac; done
S="$REPO_DIR/benchmarks/setup"; B="$REPO_DIR/benchmarks"
has() { [[ " $STAGES " == *" $1 "* ]]; }

has env       && { bash "$S/10_download_model.sh" olmoe-q8; bash "$S/00_env_report.sh"; }
has llamacpp  && bash "$S/20_build_llamacpp.sh"
has baselines && { bash "$S/10_download_model.sh" qwen25-7b-q4km
                   bash "$B/run_llamacpp.sh" "$MODELS_DIR/Qwen2.5-7B-Instruct-Q4_K_M.gguf"; }
has bitnet    && { bash "$S/30_setup_bitnet.sh"; bash "$B/run_bitnet.sh"; }
has powerinfer && { bash "$S/40_build_powerinfer.sh"; bash "$S/41_powerinfer_model.sh"
                    bash "$B/run_powerinfer.sh" "$MODELS_DIR/powerinfer/llama-7b-relu.q4.powerinfer.gguf"; }
has moe       && { bash "$S/10_download_model.sh" olmoe-q8; bash "$S/50_moe_streamed.sh" --reps "$REPS"; }
has routing   && { bash "$S/21_build_routing_tool.sh"; bash "$B/routing/run_routing.sh"; python3 "$B/routing/replay.py"; }
python3 "$B/compare.py"
