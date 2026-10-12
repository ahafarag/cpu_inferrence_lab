# Running the lab on a VPS (Phase 1b) — step by step

Written for the owner's Hostinger VPS (`[VPS_HOSTNAME]`, seen 2026-10-12: Linux, 3.9 GB RAM with ~1.8 GB available, no swap,
48 GB disk / 21 GB free, Docker present). Adjust numbers if yours differ.

## 0. Read first: protect the VPS

- **Do not run this on a VPS that serves anything important** unless you accept slowdowns. The benchmarks use all CPU cores for
  minutes and a lot of page cache. Run off-peak, and check what is running first (step 2).
- **No swap + 1.8 GB free RAM = OOM risk.** Compiling with many parallel jobs can kill other processes. Always use `JOBS=2`.
- Nothing here needs open ports, new users or changes to your services. It only writes under `~/lab`, `~/engines`, `~/models`.
- Delete everything afterwards with `rm -rf ~/lab ~/engines ~/models ~/venv-*` if you want the space back.

## 1. Get the repo onto the VPS (no GitHub needed)

On your **Windows laptop** (PowerShell):

```powershell
cd [WORKING_COPY_PATH]
git archive --format=tar.gz -o $env:USERPROFILE\lab.tar.gz HEAD
scp $env:USERPROFILE\lab.tar.gz root@<VPS_IP>:/root/
```

`<VPS_IP>` is on the VPS overview page in Hostinger hPanel. The first connection asks you to type `yes`, then the root password
(or use an SSH key you added in hPanel). If `scp` is not found: Settings → Apps → Optional features → "OpenSSH Client".

On the **VPS** (Hostinger web terminal is fine):

```bash
mkdir -p ~/lab && tar -xzf ~/lab.tar.gz -C ~/lab && cd ~/lab && ls
```

(Later, once the GitHub repo exists: `git clone <url> ~/lab` instead.)

## 2. Look before you run (paste the output back to me or send a screenshot)

```bash
nproc; uptime; free -m; df -h /; docker ps --format '{{.Names}}  {{.Status}}' 2>/dev/null | head
cat /sys/block/$(lsblk -no pkname $(df --output=source / | tail -1) | head -1)/queue/read_ahead_kb
systemd-detect-virt; uname -r
```

## 3. Install tools and record the environment

```bash
apt-get update && apt-get install -y build-essential cmake git curl python3 python3-venv util-linux
export JOBS=2 HOST_LABEL=vps-hostinger
cd ~/lab && bash benchmarks/setup/00_env_report.sh      # writes HARDWARE-vps-hostinger.md (downloads nothing big)
```

`00_env_report.sh` uses a model file for the disk speed tests; without one it skips them. To include them, first
`bash benchmarks/setup/10_download_model.sh olmoe-q4km` (4.2 GB, verified), then rerun the report with that file:
`bash benchmarks/setup/00_env_report.sh ~/models/moe/olmoe-1b-7b-0924-instruct-q4_k_m.gguf`.

## 4. What fits on this VPS (3.9 GB RAM)

| Test | Fits? | Command |
|---|---|---|
| BitNet 2B baseline (1.3 GB peak) | yes | `apt-get install -y clang lld; bash benchmarks/setup/30_setup_bitnet.sh; bash benchmarks/run_bitnet.sh` |
| Qwen2.5-7B Q4 (7.5 GB peak) | **no**, would stream and be mislabelled | skip |
| MoE streaming sweep, OLMoE Q4_K_M (4.2 GB) with a 2 GiB cache (~48% of file; lab used 68%) | yes, this is the point | below |
| In-RAM reference for OLMoE | **no** (needs ≥ 9 GB) | the script skips it and says so |

```bash
export JOBS=2 HOST_LABEL=vps-hostinger
bash benchmarks/setup/20_build_llamacpp.sh              # ~30–60 min on 2 vCPUs; run inside `screen` or `tmux`
bash benchmarks/setup/10_download_model.sh olmoe-q4km
bash benchmarks/setup/50_moe_streamed.sh --model ~/models/moe/olmoe-1b-7b-0924-instruct-q4_k_m.gguf \
     --cache-gb 2 --readahead "128 256 1024 8192" --reps 3
python3 benchmarks/compare.py
```

Send me `benchmarks/results.csv` (the new rows) and `HARDWARE-vps-hostinger.md`. Those two files are the whole result.

## 5. What the result will and will not tell us

- It answers the open question: **is the large-read-ahead penalty WSL2-specific?** (native Linux default is 128 KB).
- It cannot give an in-RAM ratio on this machine (the model does not fit); report absolute tok/s and the ratio between
  read-ahead settings only.
- VPS disks are virtualised and often rate-limited; the numbers describe this VPS, not NVMe in general.
