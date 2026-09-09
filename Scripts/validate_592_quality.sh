#!/usr/bin/env bash

set -euo pipefail

# English: Validate the 5.9.2 iOS test targets, benchmark fixtures, and regression harness inventory.
# Español: Valida los objetivos de prueba de iOS, los fixtures de benchmark y el inventario del harness de regresión de 5.9.2.
# 中文：校验 5.9.2 的 iOS 测试目标、基准夹具和回归 harness 清单。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

test_targets=(
  PToolsCoreTests
  PToolsUIFoundationTests
  PToolsNetworkTests
  PToolsListTests
  PToolsNavigationTests
  PToolsMediaTests
  PToolsPermissionTests
)

test_files=(
  Tests/PooToolsCoreTests/PTCoreContractTests.swift
  Tests/PToolsUIFoundationTests/PTUIFoundationContractTests.swift
  Tests/PToolsNetworkTests/PTNetworkQualityTests.swift
  Tests/PToolsListTests/PTListQualityTests.swift
  Tests/PToolsNavigationTests/PTNavigationRegressionTests.swift
  Tests/PToolsMediaTests/PTMediaQualityTests.swift
  Tests/PToolsPermissionTests/PTPermissionQualityTests.swift
)

for target in "${test_targets[@]}"; do
  if ! rg -q --fixed-strings "name: \"$target\"" Package.swift; then
    printf 'FAIL: missing SwiftPM quality test target: %s\n' "$target" >&2
    exit 1
  fi
  printf 'PASS: SwiftPM quality test target: %s\n' "$target"
done

for file in "${test_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    printf 'FAIL: missing quality test source: %s\n' "$file" >&2
    exit 1
  fi
  printf 'PASS: quality test source: %s\n' "$file"
done

require_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if ! rg -q --fixed-strings "$pattern" "$file"; then
    printf 'FAIL: %s (%s)\n' "$description" "$file" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$description"
}

require_pattern "Tests/PToolsListTests/PTListQualityTests.swift" "10_000" "Collection 10,000-item benchmark fixture"
require_pattern "Tests/PToolsListTests/PTListQualityTests.swift" "incremental-section" "Collection incremental snapshot fixture"
require_pattern "Tests/PToolsListTests/PTListQualityTests.swift" "photo-prefetch" "Collection photo prefetch scenario inventory"
require_pattern "Tests/PToolsNetworkTests/PTNetworkQualityTests.swift" "0..<100" "Network 100-request benchmark fixture"
require_pattern "Tests/PToolsNetworkTests/PTNetworkQualityTests.swift" "policy: .identical" "Network deduplication scenario"
require_pattern "Tests/PToolsMediaTests/PTMediaQualityTests.swift" "3_840" "Media 4K image benchmark fixture"
require_pattern "Tests/PToolsMediaTests/PTMediaQualityTests.swift" "PTVideoThumbnailService" "Media video preparation harness"
require_pattern "Tests/PToolsNavigationTests/PTNavigationRegressionTests.swift" "interactivePopGestureRecognizer" "Navigation interactive-pop harness"

swift package dump-package >/dev/null
git diff --check

if [[ ! -f "report/quality_5_9_2.md" ]]; then
  printf 'FAIL: missing 5.9.2 quality report\n' >&2
  exit 1
fi

printf 'PASS: 5.9.2 quality target and harness contracts\n'
