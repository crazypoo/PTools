#!/usr/bin/env bash

set -euo pipefail

# English: Regenerate font sources in a temporary directory and compare committed output.
# Español: Regenera las fuentes en un directorio temporal y compara la salida versionada.
# 中文：在临时目录重新生成字体源码，并与仓库中的生成文件比较。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/ptools-font.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

python3 "$repo_root/Scripts/Font/validate-font-catalog.py"
python3 "$repo_root/Scripts/Font/generate-font-catalog.py" \
  --catalog "$repo_root/PooToolsSource/Font/Resources/FontCatalog/FontCatalog.json" \
  --output "$tmp_dir" \
  --generate

for generated in PTFontCatalog.generated.swift PTFontCompatibility.generated.swift; do
  if ! cmp -s "$tmp_dir/$generated" "$repo_root/PooToolsSource/Font/Generated/$generated"; then
    printf 'FAIL [FONT_GENERATED_STALE] %s\n' "$generated" >&2
    exit 1
  fi
done

printf 'PASS [FONT_GENERATED] generated sources are current\n'

