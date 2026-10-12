#!/bin/bash
set -e
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
cd ~/engines
[ -d PowerInfer ] || git clone --depth 1 https://github.com/SJTU-IPADS/PowerInfer.git
cd PowerInfer
git log -1 --format='%h %ad' --date=short
rm -rf build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DLLAMA_CUBLAS=OFF > ~/pi_cmake.log 2>&1 || { echo CMAKE_FAILED; tail -15 ~/pi_cmake.log; exit 1; }
cmake --build build --config Release -j4 > ~/pi_make.log 2>&1 || { echo BUILD_FAILED; grep -E "error|Error" ~/pi_make.log | head -10; exit 1; }
ls build/bin | head -20
echo POWERINFER_BUILD_DONE
