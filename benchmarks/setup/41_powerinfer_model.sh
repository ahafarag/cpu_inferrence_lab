#!/usr/bin/env bash
# Downloads the FP16 PowerInfer-format ReluLLaMA-7B (15 GB) and quantizes it to Q4_0 (4.3 GB) with PowerInfer's own tool.
# Peak disk use ~20 GB; quantize takes ~9 min. The FP16 file is deleted afterwards (KEEP_F16=1 to keep it).
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
Q="$MODELS_DIR/powerinfer/llama-7b-relu.q4.powerinfer.gguf"
F16="$MODELS_DIR/powerinfer/llama-7b-relu.powerinfer.gguf"
[ -x "$ENGINES_DIR/PowerInfer/build/bin/quantize" ] || die "run 40_build_powerinfer.sh first"
if [ -f "$Q" ]; then echo "already present: $Q"; exit 0; fi
bash "$REPO_DIR/benchmarks/setup/10_download_model.sh" relullama-7b-f16
"$ENGINES_DIR/PowerInfer/build/bin/quantize" "$F16" "$Q" Q4_0
[ "${KEEP_F16:-0}" = "1" ] || rm -f "$F16"
ls -la "$MODELS_DIR/powerinfer/"
