#!/usr/bin/env bash

# English: Compile the CocoaPods example for a generic iOS device without signing.
# Español: Compila el ejemplo de CocoaPods para un dispositivo iOS genérico sin firma.
# 中文：在不签名的情况下，为通用 iOS 真机构建 CocoaPods 示例工程。

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
configuration="${CONFIGURATION:-Debug}"
derived_data_path="${DERIVED_DATA_PATH:-/tmp/PTools-5.32.0-CocoaPods-Device-DD}"

xcodebuild \
  -workspace "$repo_root/PooTools.xcworkspace" \
  -scheme PooTools-Example \
  -configuration "$configuration" \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$derived_data_path" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build
