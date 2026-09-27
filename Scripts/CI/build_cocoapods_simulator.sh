#!/usr/bin/env bash

# English: Build the CocoaPods example for the generic arm64 Simulator destination.
# Español: Compila el ejemplo de CocoaPods para el destino Simulator arm64 genérico.
# 中文：为通用 arm64 Simulator 目标构建 CocoaPods 示例工程。

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
configuration="${CONFIGURATION:-Debug}"
derived_data_path="${DERIVED_DATA_PATH:-/tmp/PTools-5.33.0-CocoaPods-Simulator-DD}"

xcodebuild \
  -workspace "$repo_root/PooTools.xcworkspace" \
  -scheme PooTools-Example \
  -configuration "$configuration" \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$derived_data_path" \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_ALLOWED=NO \
  build
