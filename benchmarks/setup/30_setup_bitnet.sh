#!/usr/bin/env bash
# Builds bitnet.cpp (pinned commit + its pinned llama.cpp fork) and prepares the 2B-4T i2_s model.
# Needs clang >= 18 (apt install clang lld). Takes ~10 min on a 4-core laptop.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
command -v clang >/dev/null || die "need clang (apt install clang lld)"
bash "$REPO_DIR/benchmarks/setup/10_download_model.sh" bitnet-2b-i2s
fetch_pinned "$BITNET_URL" "$ENGINES_DIR/BitNet" "$BITNET_COMMIT"
git -C "$ENGINES_DIR/BitNet" submodule update --init --recursive --depth 1
VENV_BN="${VENV_BITNET:-$HOME/venv-bitnet}"
[ -x "$VENV_BN/bin/python" ] || python3 -m venv "$VENV_BN"
"$VENV_BN/bin/pip" install -q -r "$ENGINES_DIR/BitNet/requirements.txt"
cd "$ENGINES_DIR/BitNet"
"$VENV_BN/bin/python" setup_env.py -md "$MODELS_DIR/BitNet-b1.58-2B-4T" -q i2_s
ls -la build/bin/llama-bench build/bin/llama-cli
