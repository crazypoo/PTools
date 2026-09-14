#!/usr/bin/env bash

set -euo pipefail

# English: Keep the historical migration command as a compatibility wrapper for the canonical documentation gates.
# Español: Mantén el comando histórico de migración como envoltorio compatible de las puertas documentales canónicas.
# 中文：保留历史迁移命令，并让它转发到 canonical 文档门禁。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

bash Scripts/validate_docs.sh
bash Scripts/validate_document_versions.sh
bash Scripts/validate_deprecated_inventory.sh

for source in \
  PooTools/SceneDelegate.swift \
  PooTools/PTTestTabbarViewController.swift \
  PooTools/PTFuncNameViewController.swift \
  PooTools/PTFuncDetailViewController.swift \
  PooTools/PTSideController.swift; do
  [[ -f "$source" ]] || {
    printf 'FAIL: Example source entry is missing: %s\n' "$source" >&2
    exit 1
  }
done

printf 'PASS: canonical documentation and Example migration contracts\n'
