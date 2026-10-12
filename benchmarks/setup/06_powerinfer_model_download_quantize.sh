#!/bin/bash
set -e
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
mkdir -p ~/models/powerinfer && cd ~/models/powerinfer

# Make room: my own Q8_0 download (re-downloadable, already benchmarked).
rm -f ~/models/Qwen2.5-7B-Instruct-Q8_0.gguf
df -h / | tail -1

echo "== download ReluLLaMA-7B (fp16, PowerInfer format)"
~/venv-bitnet/bin/python - <<'PY'
from huggingface_hub import hf_hub_download
p = hf_hub_download("PowerInfer/ReluLLaMA-7B-PowerInfer-GGUF", "llama-7b-relu.powerinfer.gguf",
                    local_dir="/root/models/powerinfer")
print("downloaded", p)
PY
ls -la ~/models/powerinfer
df -h / | tail -1

echo "== quantize Q4_0"
~/engines/PowerInfer/build/bin/quantize ~/models/powerinfer/llama-7b-relu.powerinfer.gguf \
  ~/models/powerinfer/llama-7b-relu.q4.powerinfer.gguf Q4_0 2>&1 | tail -6
ls -la ~/models/powerinfer
echo PI_MODEL_DONE
