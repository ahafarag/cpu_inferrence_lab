#!/bin/bash
export PATH=/usr/local/bin:/usr/bin:/bin
mkdir -p ~/models/moe
~/venv-bitnet/bin/python - <<'PY'
from huggingface_hub import hf_hub_download
p = hf_hub_download("allenai/OLMoE-1B-7B-0924-Instruct-GGUF", "olmoe-1b-7b-0924-instruct-q8_0.gguf",
                    local_dir="/root/models/moe")
print("downloaded", p)
PY
ls -la ~/models/moe
echo MOE_DL_DONE
