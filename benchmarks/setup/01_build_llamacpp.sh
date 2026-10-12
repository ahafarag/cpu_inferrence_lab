#!/bin/bash
set -e
# WSL appends the Windows PATH; cmake then finds Windows OpenSSL/gettext headers (PostgreSQL). Use a Linux-only PATH.
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
mkdir -p ~/engines ~/models
cd ~/engines
[ -d llama.cpp ] || git clone --depth 1 https://github.com/ggml-org/llama.cpp
cd llama.cpp
rm -f build/CMakeCache.txt
cmake -B build -DGGML_NATIVE=ON -DGGML_CUDA=OFF -DCMAKE_BUILD_TYPE=Release \
  -DLLAMA_OPENSSL=OFF -DLLAMA_CURL=OFF -DOPENSSL_INCLUDE_DIR= -DOPENSSL_ROOT_DIR= > ~/build_cmake.log 2>&1
cmake --build build -j4 --target llama-bench llama-cli > ~/build_make.log 2>&1
ls build/bin | grep -E 'llama-(bench|cli)'
echo BUILD_DONE
