#!/usr/bin/env bash

set -euo pipefail

# English: Keep runtime snapshots pending until a human reviews the diff.
# Español: Mantiene las instantáneas del runtime como pending hasta la revisión humana.
# 中文：Runtime 快照必须先进入 pending，人工审核后才能更新正式目录。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
catalog="$repo_root/PooToolsSource/Font/Resources/FontCatalog/FontCatalog.json"
pending="$repo_root/PooToolsSource/Font/Resources/FontCatalog/FontCatalog.pending.json"

if [[ "${1:-}" != "--from-json" ]]; then
  printf 'Runtime collection is performed by the iOS Simulator host; use --from-json for a reviewed candidate.\n' >&2
  exit 2
fi

candidate="${2:-}"
[[ -n "$candidate" && -f "$candidate" ]] || { printf 'FAIL [FONT_PENDING] candidate JSON is missing\n' >&2; exit 1; }

python3 "$repo_root/Scripts/Font/diff-font-catalog.py" \
  --current "$catalog" \
  --candidate "$candidate" \
  --output "$pending"
