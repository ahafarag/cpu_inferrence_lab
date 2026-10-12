#!/bin/bash
mkdir -p ~/models && cd ~/models
URL=https://huggingface.co/bartowski/Qwen2.5-7B-Instruct-GGUF/resolve/main/Qwen2.5-7B-Instruct-Q4_K_M.gguf
curl -fL -C - -o Qwen2.5-7B-Instruct-Q4_K_M.gguf "$URL" && echo DL_DONE
