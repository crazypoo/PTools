#!/usr/bin/env bash

set -euo pipefail

# English: Enforce the current documentation, script, data, and test governance contract.
# Español: Aplica el contrato actual de gobernanza de documentación, scripts, datos y tests.
# 中文：执行当前版本的文档、脚本、数据资产和测试治理契约。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

version="$(tr -d '[:space:]' < VERSION)"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  printf 'FAIL [VERSION_SOURCE_INVALID]: VERSION must be semantic, got %s\n' "$version" >&2
  exit 1
}

python3 Scripts/Docs/audit_docs.py --check

required_files=(
  docs/_meta/modules.yml
  docs/_meta/scripts.yml
  docs/_meta/data-assets.yml
  docs/_meta/tests.yml
  docs/_meta/languages.yml
  docs/_meta/document-policy.yml
  docs/_meta/glossary.yml
  docs/_meta/provenance.yml
  docs/index/README.zh-Hans.md
  docs/index/README.en.md
  docs/index/README.es.md
  docs/index/MODULES.zh-Hans.md
  docs/index/MODULES.en.md
  docs/index/MODULES.es.md
  docs/maintenance/DOCUMENTATION_AND_ASSET_GOVERNANCE.md
  docs/maintainers/TEST_GOVERNANCE.md
  report/docs/DOCUMENT_INVENTORY.json
  report/scripts/SCRIPT_INVENTORY.json
  report/data/DATA_ASSET_INVENTORY.json
  report/tests/TEST_INVENTORY.json
  PooToolsSource/Core/PTControlLoadingCoordinator.swift
  PooToolsSource/PToolsForm/PTFormRenderers.swift
  PooToolsSource/PToolsForm/PTFormSupport.swift
  PooToolsSource/PToolsDocuments/PTDocumentPDFAdapters.swift
  PooToolsSource/PDF/PTPDFPreviewController.swift
  docs/guides/PTOOLS_5_56_2_CLOSURE.md
)
for path in "${required_files[@]}"; do
  [[ -f "$path" ]] || { printf 'FAIL: governance asset is missing: %s\n' "$path" >&2; exit 1; }
done

git diff --check
printf 'PASS: PTools 5.56.2 documentation and repository governance\n'
