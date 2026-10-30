#!/usr/bin/env bash
# PR57: real Apple SDK compile of Studio's modular and compatibility targets.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

if ! command -v xcrun >/dev/null || ! command -v xcodebuild >/dev/null; then
  echo "FAIL [STUDIO_APPLE_SDK_REQUIRED]: run on a macOS Xcode runner" >&2
  exit 1
fi
xcodebuild -version
swift --version
xcrun --sdk iphonesimulator --show-sdk-version

# Include the protocol/core alongside UIKit presentation and original umbrella.
# Do not disable strict-concurrency or alter public interfaces to force a build.
for target in \
  PToolsStudioProtocolCore \
  PToolsDebugInspectorCore \
  PToolsDebugInspectorUI \
  PToolsDebugConsoleUI \
  PToolsDebugMetricsUI \
  PToolsDebugStudioBridge \
  PooToolsDEBUG
do
  printf 'Checking native iOS Simulator target: %s\n' "$target"
  swift build --triple arm64-apple-ios17.0-simulator --target "$target"
done

echo "PASS [STUDIO_NATIVE_TARGETS]: seven SwiftPM targets typechecked against real iOS SDK"
