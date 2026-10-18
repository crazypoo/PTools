#!/usr/bin/env bash

set -euo pipefail

# English: Type-check the standalone product with the iOS 17 Simulator SDK.
# Español: Comprueba el producto independiente con el SDK Simulator de iOS 17.
# 中文：使用 iOS 17 Simulator SDK 对独立产品做类型检查。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
swift package dump-package >/dev/null
sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
xcrun --sdk iphonesimulator swiftc -typecheck -swift-version 6 \
  -target arm64-apple-ios17.0-simulator -sdk "$sdk" \
  -module-name PToolsConstraintLayout \
  "$repo_root/PooToolsSource/PToolsConstraintLayout/PTLayoutCore.swift" \
  "$repo_root/PooToolsSource/PToolsConstraintLayout/PTLayoutGrouping.swift" \
  "$repo_root/PooToolsSource/PToolsConstraintLayout/PTLayoutPerformance.swift"
printf 'PTLayout differential contract: static iOS Simulator type-check passed; runtime parity requires an external iOS host\n'
