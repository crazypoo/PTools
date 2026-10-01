#!/usr/bin/env bash

set -euo pipefail

# English: Run the deterministic local gates for the PTModel 65-to-100 execution track.
# Español: Ejecuta las puertas locales deterministas de la ruta PTModel del 65 al 100.
# 中文：执行 PTModel 65% 到 100% 路线的本地确定性门禁。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

[[ "$(tr -d '[:space:]' < VERSION)" == "5.58.0" ]] || {
  printf 'FAIL: VERSION must remain 5.58.0 for this execution track\n' >&2
  exit 1
}

git diff --check
swift package dump-package >/dev/null

core_imports="$(find PooToolsSource/PToolsModelCore -type f -name '*.swift' -print0 | xargs -0 grep -nE '^(import|@_exported import) (UIKit|SwiftUI|Combine|AppKit)' || true)"
if [[ -n "$core_imports" ]]; then
  printf '%s\n' "$core_imports" >&2
  printf 'FAIL: PToolsModelCore has a platform import\n' >&2
  exit 1
fi

unsafe_matches="$(find PooToolsSource/PToolsModelCore PToolsModelMacros -type f -name '*.swift' -print0 | xargs -0 grep -nE 'nonisolated\(unsafe\)|try!|as!' || true)"
if [[ -n "$unsafe_matches" ]]; then
  printf '%s\n' "$unsafe_matches"
  printf 'FAIL: unsafe escape hatch found in PTModel core or macros\n' >&2
  exit 1
fi

for file in PooToolsSource/PToolsModelCore/*.swift PooToolsSource/PToolsModel/*.swift PooToolsSource/PToolsModelUIKit/*.swift PooToolsSource/PToolsModelCombine/*.swift PToolsModelMacros/*.swift; do
  xcrun swiftc -frontend -parse "$file" >/dev/null
done

grep -Eq 'encodeP99Milliseconds|decodeP99Milliseconds|concurrentEncodeCount|concurrentDecodeCount' \
  Benchmarks/PTModel/Runner/main.swift || {
  printf 'FAIL: PTModel benchmark runner is missing P99 or concurrency metrics\n' >&2
  exit 1
}

grep -Eq 'concurrent_1000_encode|concurrent_1000_decode' Benchmarks/PTModel/manifest.json || {
  printf 'FAIL: PTModel benchmark manifest is missing the 1,000-task stress metrics\n' >&2
  exit 1
}

# English: Require the R3 dependency audit and every named consumer fixture before closing the migration track.
# Español: Exige la auditoría de dependencias R3 y cada fixture de consumidor antes de cerrar la migración.
# 中文：在关闭迁移路线前，强制执行 R3 依赖审计并检查所有指定 Consumer fixture。
audit_output="$(swift Scripts/PTModel/audit_model_dependencies.swift)"
for gate in \
  'internalSmartCodableImports = 0' \
  'internalKakaJSONImports = 0' \
  'remainingLegacyNetworkCalls = 0'; do
  grep -Fqx "$gate" <<<"$audit_output" || {
    printf 'FAIL: dependency audit gate is not closed: %s\n' "$gate" >&2
    exit 1
  }
done

for fixture in \
  Fixtures/PTModelConsumers/SmartCodableLegacyApp/main.swift \
  Fixtures/PTModelConsumers/KakaJSONLegacyApp/main.swift \
  Fixtures/PTModelConsumers/MixedLegacyApp/main.swift \
  Fixtures/PTModelConsumers/PTModelOnlyApp/main.swift \
  Fixtures/PTModelConsumers/SwiftPMConsumer/README.md \
  Fixtures/PTModelConsumers/CocoaPodsConsumer/README.md; do
  [[ -f "$fixture" ]] || {
    printf 'FAIL: consumer fixture is missing: %s\n' "$fixture" >&2
    exit 1
  }
done

for product in \
  PTModelLegacySmartCodableFixture \
  PTModelLegacyKakaJSONFixture \
  PTModelMixedLegacyFixture \
  PTModelOnlyFixture; do
  grep -Fq "$product" Package.swift || {
    printf 'FAIL: Package.swift is missing consumer fixture product: %s\n' "$product" >&2
    exit 1
  }
done

printf 'PASS: PTModel local 65-to-100 static gates\n'
