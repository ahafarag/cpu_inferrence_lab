#!/usr/bin/env bash
# Builds llama.cpp (pinned commit), CPU-only. Produces $ENGINES_DIR/llama.cpp/build/bin/{llama-bench,llama-cli}.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
command -v cmake >/dev/null && command -v g++ >/dev/null || die "need cmake and g++ (apt install build-essential cmake)"
fetch_pinned "$LLAMA_CPP_URL" "$ENGINES_DIR/llama.cpp" "$LLAMA_CPP_COMMIT"
cd "$ENGINES_DIR/llama.cpp"
cmake -B build -DCMAKE_BUILD_TYPE=Release -DGGML_NATIVE=ON -DGGML_CUDA=OFF -DLLAMA_OPENSSL=OFF -DLLAMA_CURL=OFF >/dev/null
cmake --build build -j"$JOBS" --target llama-bench llama-cli
ls -la build/bin/llama-bench build/bin/llama-cli
