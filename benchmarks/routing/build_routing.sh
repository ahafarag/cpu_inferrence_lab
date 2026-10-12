#!/usr/bin/env bash
# Builds benchmarks/routing/moe_routing.cpp as a llama.cpp example target (llama-moe-routing).
set -euo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin   # avoid the WSL Windows-PATH trap
HERE="$(cd "$(dirname "$0")" && pwd)"
LLAMA_DIR="${LLAMA_DIR:-${ENGINES_DIR:-$HOME/engines}/llama.cpp}"
EX="$LLAMA_DIR/examples/moe-routing"
mkdir -p "$EX"
cp "$HERE/moe_routing.cpp" "$EX/moe-routing.cpp"
cat > "$EX/CMakeLists.txt" <<'EOF'
set(TARGET llama-moe-routing)
add_executable(${TARGET} moe-routing.cpp)
install(TARGETS ${TARGET} RUNTIME)
target_link_libraries(${TARGET} PRIVATE llama-common llama ${CMAKE_THREAD_LIBS_INIT})
target_compile_features(${TARGET} PRIVATE cxx_std_17)
EOF
grep -q 'add_subdirectory(moe-routing)' "$LLAMA_DIR/examples/CMakeLists.txt" || \
  sed -i 's/add_subdirectory(eval-callback)/add_subdirectory(eval-callback)\n    add_subdirectory(moe-routing)/' "$LLAMA_DIR/examples/CMakeLists.txt"
cd "$LLAMA_DIR"
cmake -B build -DGGML_NATIVE=ON -DGGML_CUDA=OFF -DCMAKE_BUILD_TYPE=Release -DLLAMA_OPENSSL=OFF -DLLAMA_CURL=OFF > /dev/null
cmake --build build -j4 --target llama-moe-routing 2>&1 | tail -5
ls -la build/bin/llama-moe-routing
