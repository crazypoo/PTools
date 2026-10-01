#!/usr/bin/env bash

set -euo pipefail

# English: Run the deterministic local gates for PTModel G1, G2, and G3.
# Español: Ejecuta las puertas locales deterministas de PTModel G1, G2 y G3.
# 中文：执行 PTModel G1、G2、G3 的本地确定性门禁。

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

# English: Build the real SwiftPM consumer executables so legacy and typed products are both linked.
# Español: Construye los ejecutables reales de consumidores SwiftPM para enlazar productos heredados y tipados.
# 中文：构建真实 SwiftPM Consumer 可执行文件，确认旧版和类型化产品都能完成链接。
for product in \
  PTModelLegacySmartCodableFixture \
  PTModelLegacyKakaJSONFixture \
  PTModelMixedLegacyFixture \
  PTModelOnlyFixture; do
  swift build --target "$product" >/dev/null
  swift run --skip-build "$product" >/dev/null
done

# English: Reinstall the actual CocoaPods host without changing tracked consumer inputs.
# Español: Reinstala el host CocoaPods real sin cambiar las entradas rastreadas del consumidor.
# 中文：重新安装真实 CocoaPods 宿主，同时禁止修改已跟踪的 Consumer 输入。
command -v pod >/dev/null 2>&1 || {
  printf 'FAIL: CocoaPods is required for the PTModel host gate\n' >&2
  exit 1
}
status_before_pod="$(git status --short)"
pod install --no-repo-update >/dev/null
status_after_pod="$(git status --short)"
[[ "$status_before_pod" == "$status_after_pod" ]] || {
  printf 'FAIL: pod install changed tracked workspace inputs\n' >&2
  diff -u <(printf '%s\n' "$status_before_pod") <(printf '%s\n' "$status_after_pod") >&2 || true
  exit 1
}

example_settings="$(xcodebuild -workspace PooTools.xcworkspace \
  -scheme PooTools-Example \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -showBuildSettings 2>/dev/null)"
grep -Fqx '    SWIFT_VERSION = 6.0' <<<"$example_settings" || {
  printf 'FAIL: PooTools-Example is not using Swift 6\n' >&2
  exit 1
}
grep -Fqx '    IPHONEOS_DEPLOYMENT_TARGET = 17.0' <<<"$example_settings" || {
  printf 'FAIL: PooTools-Example is not using iOS 17\n' >&2
  exit 1
}

legacy_settings="$(xcodebuild -workspace PooTools.xcworkspace \
  -scheme Appz \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -showBuildSettings 2>/dev/null)"
grep -Fqx '    SWIFT_VERSION = 5.0' <<<"$legacy_settings" || {
  printf 'FAIL: Appz legacy compatibility target is not using Swift 5\n' >&2
  exit 1
}

# English: Build both configurations through the real CocoaPods iOS workspace.
# Español: Construye ambas configuraciones mediante el workspace iOS real de CocoaPods.
# 中文：通过真实 CocoaPods iOS workspace 构建 Debug 和 Release 两种配置。
derived_data="$(mktemp -d /tmp/PTModel-G1-G3.XXXXXX)"
simulator_udid=""
started_simulator=0
cleanup() {
  if [[ "$started_simulator" == "1" && -n "$simulator_udid" ]]; then
    xcrun simctl shutdown "$simulator_udid" >/dev/null 2>&1 || true
  fi
  rm -rf "$derived_data"
}
trap cleanup EXIT

for configuration in Debug Release; do
  build_log="$derived_data/xcodebuild-$configuration.log"
  if ! xcodebuild -workspace PooTools.xcworkspace \
    -scheme PooTools-Example \
    -configuration "$configuration" \
    -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$derived_data" \
    build >"$build_log" 2>&1; then
    tail -120 "$build_log" >&2
    printf 'FAIL: CocoaPods host %s build failed\n' "$configuration" >&2
    exit 1
  fi
done

# English: Install and launch the built host on an available iOS Simulator.
# Español: Instala y lanza el host construido en un iOS Simulator disponible.
# 中文：将构建好的宿主安装并启动到可用的 iOS 模拟器。
simulator_udid="$(xcrun simctl list devices available | sed -nE 's/.*\(([A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12})\).*/\1/p' | head -1)"
[[ -n "$simulator_udid" ]] || {
  printf 'FAIL: no available iOS Simulator found\n' >&2
  exit 1
}
if ! xcrun simctl list devices | grep -F "$simulator_udid" | grep -Fq '(Booted)'; then
  xcrun simctl boot "$simulator_udid" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$simulator_udid" -b
  started_simulator=1
fi

run_log="$derived_data/xcodebuild-run.log"
if ! xcodebuild -workspace PooTools.xcworkspace \
  -scheme PooTools-Example \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=$simulator_udid" \
  -derivedDataPath "$derived_data" \
  build >"$run_log" 2>&1; then
  tail -120 "$run_log" >&2
  printf 'FAIL: explicit iOS Simulator host build failed\n' >&2
  exit 1
fi
app_path="$(find "$derived_data/Build/Products/Debug-iphonesimulator" -maxdepth 1 -name 'PooTools_Example.app' -print -quit)"
[[ -n "$app_path" ]] || {
  printf 'FAIL: PooTools_Example.app was not produced\n' >&2
  exit 1
}
bundle_identifier="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Info.plist")"
xcrun simctl install "$simulator_udid" "$app_path"
xcrun simctl launch "$simulator_udid" "$bundle_identifier" >/dev/null
sleep 3
xcrun simctl terminate "$simulator_udid" "$bundle_identifier" >/dev/null 2>&1 || true

printf 'PASS: PTModel G1/G2/G3 deterministic and iOS host gates\n'
