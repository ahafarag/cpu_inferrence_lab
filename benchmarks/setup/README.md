# benchmarks/setup/

Raw scripts used on 2026-10-12 to build the engines and fetch models, in run order. They are the provenance for every row in
`../results.csv`. They are NOT yet parameterised (paths assume `/root`, WSL2 Ubuntu 24.04, repo at `[WORKING_COPY_WSL_PATH]`).
TODO: parameterise paths, record model SHA256 in `../../MODELS.md`, add `run_all.sh`.

Known environment traps (all hit during setup):
- WSL2 appends the Windows PATH; use a Linux-only PATH or cmake finds Windows OpenSSL/gettext headers (build fails with `libintl_snprintf`).
- `llama-cli` needs `-st --simple-io -c 2048` when scripted; `-no-cnv` hangs on this build.
- PowerInfer's `llama-bench` cannot load `.powerinfer.gguf`; use `main` and parse `llama_print_timings`.
- WSL2 default `read_ahead_kb` is 8192; limit the page cache with a cgroup v2 `memory.max` and `memory.swap.max=0`, not `.wslconfig` (swap confound).
