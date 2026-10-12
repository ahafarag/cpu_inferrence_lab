#!/bin/bash
set -e
# Linux-only PATH: WSL appends the Windows PATH, which broke the llama.cpp build earlier.
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DEBIAN_FRONTEND=noninteractive
apt-get install -y -qq clang lld python3-venv > ~/bitnet_apt.log 2>&1
clang --version | head -1
mkdir -p ~/engines && cd ~/engines
[ -d BitNet ] || git clone --recursive --depth 1 https://github.com/microsoft/BitNet.git
cd BitNet
git log -1 --format=%h
[ -d ~/venv-bitnet ] || python3 -m venv ~/venv-bitnet
~/venv-bitnet/bin/pip install -q -r requirements.txt "huggingface_hub[cli]" > ~/bitnet_pip.log 2>&1
mkdir -p ~/models/BitNet-b1.58-2B-4T
~/venv-bitnet/bin/python - <<'PY'
from huggingface_hub import snapshot_download
p = snapshot_download("microsoft/BitNet-b1.58-2B-4T-gguf", local_dir="/root/models/BitNet-b1.58-2B-4T")
print("downloaded to", p)
PY
~/venv-bitnet/bin/python setup_env.py -md ~/models/BitNet-b1.58-2B-4T -q i2_s > ~/bitnet_setup.log 2>&1
echo BITNET_SETUP_DONE
ls -la ~/models/BitNet-b1.58-2B-4T | head
ls build/bin 2>/dev/null | head
