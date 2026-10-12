# MODELS.md — provenance of every model file

All downloads come from a **pinned Hugging Face revision** and are verified by SHA256 (`benchmarks/setup/models.tsv` is the
machine-readable source; `benchmarks/setup/10_download_model.sh <key>` downloads and verifies). The "upstream SHA256" is the
Hugging Face LFS object hash. "Verified locally" means the file used for the published numbers was hashed and matched.

| Key | Repo | File | Revision | Size (bytes) | Upstream SHA256 | Verified locally |
|---|---|---|---|---|---|---|
| `qwen25-7b-q4km` | bartowski/Qwen2.5-7B-Instruct-GGUF | Qwen2.5-7B-Instruct-Q4_K_M.gguf | 8911e8a4 | 4,683,074,240 | 65b8fcd92af6…aaa1423 | yes |
| `qwen25-7b-q8` | bartowski/Qwen2.5-7B-Instruct-GGUF | Qwen2.5-7B-Instruct-Q8_0.gguf | 8911e8a4 | 8,098,525,888 | 9c6a6e616644…bc0e1fce4abe780ce1b | size matched; hash not re-checked (file was deleted to free disk) |
| `olmoe-q8` | allenai/OLMoE-1B-7B-0924-Instruct-GGUF | olmoe-1b-7b-0924-instruct-q8_0.gguf | 02ab6ea6 | 7,359,943,136 | d089e8b12dee…f8909c66 | yes |
| `olmoe-q4km` | allenai/OLMoE-1B-7B-0924-Instruct-GGUF | olmoe-1b-7b-0924-instruct-q4_k_m.gguf | 02ab6ea6 | 4,213,512,672 | 8c310f1435a1…ac32f3f | not downloaded yet |
| `bitnet-2b-i2s` | microsoft/BitNet-b1.58-2B-4T-gguf | ggml-model-i2_s.gguf | a1f2f1c7 | 1,187,801,280 | 4221b252fdd5…c2162 | yes |
| `relullama-7b-f16` | PowerInfer/ReluLLaMA-7B-PowerInfer-GGUF | llama-7b-relu.powerinfer.gguf | 17b5d8a2 | 15,148,489,984 | ed59b0524bc7…18169086 | source file for the quantized model below (deleted after quantizing; hash taken from upstream) |

Full hashes are in `models.tsv`.

## Derived file

| File | Produced by | Command | SHA256 (informational) |
|---|---|---|---|
| `powerinfer/llama-7b-relu.q4.powerinfer.gguf` (4,295,605,536 B) | PowerInfer `quantize` @ `8bd56d6` | `quantize llama-7b-relu.powerinfer.gguf llama-7b-relu.q4.powerinfer.gguf Q4_0` | 9f0154de6eda…e9d17d |

`41_powerinfer_model.sh` reproduces it. Bit-identity of the output across machines is not guaranteed; compare size and benchmark
speed, not the hash.

## Engines (pinned)

| Engine | Repo | Commit |
|---|---|---|
| llama.cpp | ggml-org/llama.cpp | `f2cc7282ce0042641df55e0e563b75e824e2b647` |
| bitnet.cpp | microsoft/BitNet | `0b341e582afbf9e1011f24744b554c96a3477eb5` (llama.cpp fork submodule `390c307752ab78fd8189f359d6954c9ba1be74af`, github.com/isHuangXin/llama.cpp) |
| PowerInfer | SJTU-IPADS/PowerInfer | `8bd56d69906c9d2dba4d3bf6899763401e01a9a4` |

## Licences (check before redistributing or publishing derived files)

Model licences differ (Qwen2.5-7B: Apache-2.0; OLMoE: Apache-2.0; BitNet b1.58 2B4T: MIT; ReluLLaMA derives from LLaMA, which has its
own licence). The models are **not** in this repository and are never committed; they are downloaded from their upstream pages.
Confirm each licence on its model card before writing anything that implies redistribution.
