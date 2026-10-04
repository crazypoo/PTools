#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

version="${1:-$(tr -d '[:space:]' < VERSION)}"
expected_version="$(tr -d '[:space:]' < VERSION)"
[[ "$version" == "$expected_version" ]] || { printf 'FAIL: release version %s does not match VERSION %s\n' "$version" "$expected_version" >&2; exit 1; }
[[ "$version" == "5.61.0" ]] || { printf 'FAIL: this gate is for 5.61.0, got %s\n' "$version" >&2; exit 1; }

# English: Keep the closure gate portable and independent of ripgrep availability.
# Español: Mantiene la puerta de cierre portable e independiente de la disponibilidad de ripgrep.
# 中文：让收口门禁不依赖 ripgrep，在不同环境中都可执行。
forbidden_dependency_files=(Package.swift Package.resolved PooTools.podspec Scripts/dependency_freeze.json Scripts/module_registry.json)
for file in "${forbidden_dependency_files[@]}"; do
  if grep -in 'Kakapos' "$file" >/dev/null 2>&1; then
    printf 'FAIL: Kakapos remains in %s\n' "$file" >&2
    exit 1
  fi
done

bash Scripts/report_semantic_capability_ownership.sh >/dev/null
bash Scripts/report_5_61_runtime_safety.sh --check
bash Scripts/validate_5_61_splitview_demo.sh
swift package dump-package >/dev/null
git diff --check

# English: The full quality gate remains the source of truth for concurrency registries and legacy allowlists.
# Español: La puerta de calidad completa sigue siendo la fuente de verdad para registros de concurrencia y listas heredadas.
# 中文：完整质量门禁继续作为并发登记表和历史白名单的唯一依据。
bash Scripts/validate_quality_scans.sh

printf 'PASS [PTOOLS_5_61_RELEASE_CLOSURE] version=%s\n' "$version"
