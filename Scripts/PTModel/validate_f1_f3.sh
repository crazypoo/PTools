#!/usr/bin/env bash

set -euo pipefail

# English: Run the deterministic local gates for PTModel F1, F2, and F3.
# Español: Ejecuta las puertas locales deterministas de PTModel F1, F2 y F3.
# 中文：执行 PTModel F1、F2、F3 的本地确定性门禁。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

version="$(tr -d '[:space:]' < VERSION)"
[[ "$version" == "5.58.0" ]] || {
  printf 'FAIL: VERSION must remain 5.58.0, got %s\n' "$version" >&2
  exit 1
}

git diff --check
swift package dump-package >/dev/null

core_imports="$(find PooToolsSource/PToolsModelCore -type f -name '*.swift' -print0 | xargs -0 grep -nE '^(import|@_exported import) (UIKit|SwiftUI|Combine|AppKit)' || true)"
[[ -z "$core_imports" ]] || {
  printf '%s\nFAIL: ModelCore has a platform import\n' "$core_imports" >&2
  exit 1
}

unsafe_matches="$(find PooToolsSource/PToolsModelCore PToolsModelMacros -type f -name '*.swift' -print0 | xargs -0 grep -nE 'nonisolated\(unsafe\)|try!|as!' || true)"
[[ -z "$unsafe_matches" ]] || {
  printf '%s\nFAIL: unsafe escape hatch found in ModelCore or macros\n' "$unsafe_matches" >&2
  exit 1
}

swift build --target PToolsModelTests >/dev/null
xcrun xctest -XCTest PTModelCoreTests .build/out/Products/Debug/PToolsModelTests.xctest >/dev/null
xcrun xctest -XCTest PTModelMacroGoldenTests .build/out/Products/Debug/PToolsModelTests.xctest >/dev/null

# English: Compile the real Network compatibility fixture against the iOS 17 Simulator SDK.
# Español: Compila el fixture real de compatibilidad de Network contra el SDK Simulator de iOS 17.
# 中文：使用 iOS 17 Simulator SDK 编译真实的 Network 兼容夹具。
command -v xcrun >/dev/null 2>&1 || {
  printf 'FAIL: xcrun is required for the iOS Network compatibility gate\n' >&2
  exit 1
}
simulator_sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
xcrun swift build \
  --sdk "$simulator_sdk" \
  --triple arm64-apple-ios17.0-simulator \
  --target PToolsNetworkTests >/dev/null 2>&1 || {
  printf 'FAIL: iOS Simulator Network compatibility target does not compile\n' >&2
  exit 1
}

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
  Fixtures/PTModelConsumers/CocoaPodsConsumer/Podfile \
  Fixtures/PTModelConsumers/CocoaPodsConsumer/Consumer.swift; do
  [[ -f "$fixture" ]] || {
    printf 'FAIL: consumer fixture is missing: %s\n' "$fixture" >&2
    exit 1
  }
done

printf 'PASS: PTModel F1/F2/F3 deterministic Core gates\n'
