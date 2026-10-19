#!/usr/bin/env bash

set -euo pipefail

# English: Type-check the standalone product without calling the result runtime parity.
# Español: Comprueba el producto independiente sin llamar a este resultado paridad runtime.
# 中文：仅对独立产品做类型检查，不把结果称为运行时等价验证。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
swift package dump-package >/dev/null
sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
xcrun --sdk iphonesimulator swiftc -typecheck -swift-version 6 \
  -target arm64-apple-ios17.0-simulator -sdk "$sdk" \
  -module-name PToolsConstraintLayout \
  "$repo_root/PooToolsSource/PToolsConstraintLayout/PTLayoutCore.swift" \
  "$repo_root/PooToolsSource/PToolsConstraintLayout/PTLayoutGrouping.swift" \
  "$repo_root/PooToolsSource/PToolsConstraintLayout/PTLayoutPerformance.swift"
printf 'PTLayout static iOS Simulator type-check: passed; runtime parity remains a separate gate\n'
