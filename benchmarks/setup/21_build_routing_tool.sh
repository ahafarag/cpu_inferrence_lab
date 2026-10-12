#!/usr/bin/env bash
# Builds llama-moe-routing (expert routing logger) inside the pinned llama.cpp checkout.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
[ -d "$ENGINES_DIR/llama.cpp/build" ] || die "run 20_build_llamacpp.sh first"
LLAMA_DIR="$ENGINES_DIR/llama.cpp" bash "$REPO_DIR/benchmarks/routing/build_routing.sh"
