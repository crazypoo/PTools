#!/usr/bin/env bash

set -euo pipefail

# English: Verify that the 6.0 migration inventory and canonical adapters are present.
# Español: Verifica que estén presentes el inventario de migración 6.0 y los adaptadores canónicos.
# 中文：验证 6.0 迁移清单和 canonical 适配器是否存在。
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

for file in MIGRATION_6.md PUBLIC_API_5_9.json report/public_api_5_9.md; do
  [[ -f "$file" ]] || {
    printf 'FAIL: missing migration/API inventory: %s\n' "$file" >&2
    exit 1
  }
done

for symbol in globalURL socketGlobalURL globalNavControl webImageLoadOptions highlightColor; do
  rg -q --fixed-strings "$symbol" MIGRATION_6.md || {
    printf 'FAIL: canonical symbol is not documented: %s\n' "$symbol" >&2
    exit 1
  }
done

printf 'PASS: canonical and deprecated API inventory\n'
