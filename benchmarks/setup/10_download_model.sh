#!/usr/bin/env bash
# Usage: 10_download_model.sh <key> [<key> ...]      keys are listed in models.tsv
# Downloads from the pinned Hugging Face revision (resumable) and verifies SHA256. Skips files that already verify.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
TSV="$REPO_DIR/benchmarks/setup/models.tsv"
[ "$#" -ge 1 ] || die "usage: $0 <key> [<key>...]  (keys: $(awk -F'\t' 'NR>1{printf "%s ", $1}' "$TSV"))"

for key in "$@"; do
  line="$(awk -F'\t' -v k="$key" '$1==k' "$TSV")"
  [ -n "$line" ] || die "unknown model key: $key"
  IFS=$'\t' read -r _ repo file rev size sha dest <<<"$line"
  out="$MODELS_DIR/$dest"
  mkdir -p "$(dirname "$out")"
  if [ -f "$out" ] && [ "$(stat -c %s "$out")" = "$size" ] && [ "$(sha256_of "$out")" = "$sha" ]; then
    echo "OK (already present, SHA256 verified): $key"
    continue
  fi
  need_gb=$(( (size + 1073741823) / 1073741824 ))
  free_gb=$(df -P --output=avail -BG "$(dirname "$out")" | tail -1 | tr -dc '0-9')
  [ "$free_gb" -ge $((need_gb + 2)) ] || die "need ~${need_gb} GB free in $(dirname "$out"), have ${free_gb} GB"
  echo "downloading $key ($(( size / 1000000 )) MB) from $repo @ ${rev:0:8}"
  curl -fL -C - --retry 5 --retry-delay 5 -o "$out" "https://huggingface.co/$repo/resolve/$rev/$file"
  [ "$(sha256_of "$out")" = "$sha" ] || die "SHA256 mismatch for $key (delete $out and retry)"
  echo "downloaded + verified: $key"
done
