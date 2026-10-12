#!/usr/bin/env bash
# Sourced by every setup script. Defines directories and the pinned engine commits.
# Override any variable from the environment (e.g. ENGINES_DIR=/opt/engines MODELS_DIR=/data/models).
set -euo pipefail

# WSL2 appends the Windows PATH, which makes cmake find Windows OpenSSL/gettext headers (libintl_snprintf build error).
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENGINES_DIR="${ENGINES_DIR:-$HOME/engines}"
MODELS_DIR="${MODELS_DIR:-$HOME/models}"
VENV_DIR="${VENV_DIR:-$HOME/venv-lab}"
JOBS="${JOBS:-$(nproc)}"
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"

# Pinned engine versions used for every published number (full hashes).
LLAMA_CPP_URL="https://github.com/ggml-org/llama.cpp"
LLAMA_CPP_COMMIT="f2cc7282ce0042641df55e0e563b75e824e2b647"
BITNET_URL="https://github.com/microsoft/BitNet.git"
BITNET_COMMIT="0b341e582afbf9e1011f24744b554c96a3477eb5"      # submodule llama.cpp fork pinned by this commit (390c307)
POWERINFER_URL="https://github.com/SJTU-IPADS/PowerInfer.git"
POWERINFER_COMMIT="8bd56d69906c9d2dba4d3bf6899763401e01a9a4"

die() { echo "ERROR: $*" >&2; exit 1; }

# fetch_pinned <url> <dir> <commit>  — shallow fetch of exactly one commit
fetch_pinned() {
  local url="$1" dir="$2" commit="$3"
  mkdir -p "$dir"
  [ -d "$dir/.git" ] || { git -C "$dir" init -q; git -C "$dir" remote add origin "$url"; }
  if [ "$(git -C "$dir" rev-parse HEAD 2>/dev/null || true)" != "$commit" ]; then
    git -C "$dir" fetch -q --depth 1 origin "$commit"
    git -C "$dir" checkout -q FETCH_HEAD
  fi
  echo "pinned $(basename "$dir") @ $(git -C "$dir" rev-parse --short HEAD)"
}

sha256_of() { sha256sum "$1" | cut -d' ' -f1; }

# a python with numpy (benchmarks/membw.py); creates $VENV_DIR on first use
ensure_venv() {
  if [ ! -x "$VENV_DIR/bin/python" ]; then
    python3 -m venv "$VENV_DIR"
    "$VENV_DIR/bin/pip" install -q numpy
  fi
}
