#!/usr/bin/env bash
# Builds PowerInfer (pinned commit), CPU-only. Produces build/bin/{main,quantize}.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fetch_pinned "$POWERINFER_URL" "$ENGINES_DIR/PowerInfer" "$POWERINFER_COMMIT"
cd "$ENGINES_DIR/PowerInfer"
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DLLAMA_CUBLAS=OFF >/dev/null
cmake --build build --config Release -j"$JOBS" --target main quantize
ls -la build/bin/main build/bin/quantize
