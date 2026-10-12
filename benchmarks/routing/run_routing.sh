#!/usr/bin/env bash
# Usage: benchmarks/routing/run_routing.sh [model.gguf]
# Runs llama-moe-routing on each prompt in prompts/ and stores the expert routing in logs/<name>.routes.txt.
set -euo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HERE="$(cd "$(dirname "$0")" && pwd)"
MODEL="${1:-$HOME/models/moe/olmoe-1b-7b-0924-instruct-q8_0.gguf}"
BIN="${LLAMA_DIR:-$HOME/engines/llama.cpp}/build/bin/llama-moe-routing"
mkdir -p "$HERE/logs"
for p in "$HERE"/prompts/*.txt; do
  n="$(basename "$p" .txt)"
  "$BIN" -m "$MODEL" -t 4 -c 2048 -b 2048 -f "$p" > "$HERE/logs/$n.routes.txt" 2> "$HERE/logs/$n.err" || { echo "FAILED $n"; tail -5 "$HERE/logs/$n.err"; exit 1; }
  echo "$n: $(head -1 "$HERE/logs/$n.routes.txt") routes=$(grep -c '^ROUTE' "$HERE/logs/$n.routes.txt")"
done
