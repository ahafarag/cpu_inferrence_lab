#!/usr/bin/env bash
# Usage: benchmarks/run_bitnet.sh [model.gguf] [threads]
# bitnet.cpp ships a llama.cpp fork with llama-bench/llama-cli, so this reuses run_llamacpp.sh.
# Default model: official BitNet-b1.58-2B-4T (i2_s).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
MODEL="${1:-$HOME/models/BitNet-b1.58-2B-4T/ggml-model-i2_s.gguf}"
export ENGINE=bitnet.cpp
export LLAMA_DIR="${BITNET_DIR:-$HOME/engines/BitNet}"
exec "$HERE/run_llamacpp.sh" "$MODEL" "${2:-}" i2_s
