#!/usr/bin/env bash

set -euo pipefail

# English: Validate the 5.19 domain matrix without inventing empty test targets.
# Español: Valida la matriz de dominios 5.19 sin inventar objetivos de prueba vacíos.
# 中文：校验 5.19 领域矩阵，不通过创建空测试 target 伪造覆盖率。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

matrix="docs/maintainers/TEST_MATRIX.md"
[[ -f "$matrix" ]] || { printf 'FAIL: test matrix is missing: %s\n' "$matrix" >&2; exit 1; }

# English: Keep the check portable on hosts without ripgrep.
# Español: Mantiene la comprobación portable en hosts sin ripgrep.
# 中文：兼容未安装 ripgrep 的环境。
contains_fixed() {
  local needle="$1"
  local file="$2"
  if command -v rg >/dev/null 2>&1; then
    rg -q --fixed-strings "$needle" "$file"
  else
    grep -Fq -- "$needle" "$file"
  fi
}

domains=(
  PToolsCoreTests
  PToolsUIFoundationTests
  PToolsNavigationTests
  PToolsCollectionTests
  PToolsNetworkTests
  PToolsSocketTests
  PToolsSecurityTests
  PToolsMediaTests
  PToolsPermissionTests
  PToolsSystemTests
  PToolsWebKitTests
  PToolsDebugTests
  PToolsInstrumentsTests
)

for domain in "${domains[@]}"; do
  contains_fixed "\`$domain\`" "$matrix" \
    || { printf 'FAIL: test matrix is missing domain %s\n' "$domain" >&2; exit 1; }
done

existing_targets=(
  PToolsCoreTests
  PToolsUIFoundationTests
  PToolsNetworkTests
  PToolsListTests
  PToolsNavigationTests
  PToolsMediaTests
  PToolsPermissionTests
  PToolsDebugTests
)

for target in "${existing_targets[@]}"; do
  target_path="Tests/$target"
  [[ "$target" == "PToolsCoreTests" ]] && target_path="Tests/PooToolsCoreTests"
  [[ -d "$target_path" ]] || { printf 'FAIL: mapped test directory is missing: %s\n' "$target_path" >&2; exit 1; }
  contains_fixed "name: \"$target\"" Package.swift \
    || { printf 'FAIL: Package.swift is missing test target %s\n' "$target" >&2; exit 1; }
done

contains_fixed 'PToolsCollectionTests' "$matrix" \
  || { printf 'FAIL: collection compatibility mapping is missing\n' >&2; exit 1; }
contains_fixed 'Tests/PToolsListTests' "$matrix" \
  || { printf 'FAIL: collection compatibility path is missing\n' >&2; exit 1; }

printf 'PASS: 5.19 test domain matrix (%d domains, %d existing targets)\n' "${#domains[@]}" "${#existing_targets[@]}"
