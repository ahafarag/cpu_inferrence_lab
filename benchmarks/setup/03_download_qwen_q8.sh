#!/bin/bash
export PATH=/usr/local/bin:/usr/bin:/bin
mkdir -p ~/models && cd ~/models
URL=https://huggingface.co/bartowski/Qwen2.5-7B-Instruct-GGUF/resolve/main/Qwen2.5-7B-Instruct-Q8_0.gguf
curl -fL -s -C - -o Qwen2.5-7B-Instruct-Q8_0.gguf "$URL" && echo DL_DONE
ls -la ~/models
