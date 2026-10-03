#!/usr/bin/env bash

set -euo pipefail

# English: Collect only from an iOS Simulator host; macOS fonts are never a catalog source.
# Español: Recopila solo desde un host de iOS Simulator; las fuentes de macOS nunca son fuente del catálogo.
# 中文：只从 iOS Simulator 宿主采集，禁止把 macOS 字体作为目录来源。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
simulator_target="booted"
output="$repo_root/PooToolsSource/Font/Resources/FontCatalog/runtime-fonts.json"
configuration="Debug"
derived_data_path="${PT_FONT_COLLECTOR_DERIVED_DATA:-$repo_root/.font-collector-derived-data}"

usage() {
  cat >&2 <<'MESSAGE'
Usage: collect-fonts.sh [--simulator booted|UDID] [--output FILE] [--configuration Debug|Release]
用法：collect-fonts.sh [--simulator booted|UDID] [--output 文件] [--configuration Debug|Release]
Uso: collect-fonts.sh [--simulator booted|UDID] [--output ARCHIVO] [--configuration Debug|Release]
MESSAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --simulator)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      simulator_target="$2"
      shift 2
      ;;
    --output)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      output="$2"
      shift 2
      ;;
    --configuration)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      configuration="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

command -v xcodebuild >/dev/null 2>&1 || { printf 'FAIL [FONT_COLLECTOR] xcodebuild is required\n' >&2; exit 1; }
command -v xcrun >/dev/null 2>&1 || { printf 'FAIL [FONT_COLLECTOR] xcrun is required\n' >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { printf 'FAIL [FONT_COLLECTOR] python3 is required\n' >&2; exit 1; }

resolve_simulator() {
  local target="$1"
  if [[ "$target" != "booted" ]]; then
    printf '%s\n' "$target"
    return 0
  fi

  xcrun simctl list devices booted -j | python3 -c '
import json
import sys

payload = json.load(sys.stdin)
for devices in payload.get("devices", {}).values():
    for device in devices:
        if device.get("state") == "Booted":
            print(device["udid"])
            raise SystemExit(0)
raise SystemExit("no booted iOS Simulator")
'
}

simulator_udid="$(resolve_simulator "$simulator_target")"
runtime_identifier="$(xcrun simctl list devices -j | python3 -c '
import json
import sys

payload = json.load(sys.stdin)
target = sys.argv[1]
for devices in payload.get("devices", {}).values():
    for device in devices:
        if device.get("udid") == target:
            print(device.get("runtime", "iOS-Simulator"))
            raise SystemExit(0)
print("iOS-Simulator")
' "$simulator_udid")"
runtime_label="${runtime_identifier##*.}"

printf 'INFO [FONT_COLLECTOR] simulator=%s runtime=%s\n' "$simulator_udid" "$runtime_label" >&2

build_settings="$(xcodebuild \
  -workspace "$repo_root/PooTools.xcworkspace" \
  -scheme PooTools-Example \
  -configuration "$configuration" \
  -sdk iphonesimulator \
  -destination "id=$simulator_udid" \
  -derivedDataPath "$derived_data_path" \
  -showBuildSettings 2>/dev/null)"

bundle_id="$(printf '%s\n' "$build_settings" | awk -F ' = ' '/PRODUCT_BUNDLE_IDENTIFIER = / { print $2; exit }')"
target_build_dir="$(printf '%s\n' "$build_settings" | awk -F ' = ' '/TARGET_BUILD_DIR = / { print $2; exit }')"
product_name="$(printf '%s\n' "$build_settings" | awk -F ' = ' '/FULL_PRODUCT_NAME = / { print $2; exit }')"
[[ -n "$bundle_id" && -n "$target_build_dir" && -n "$product_name" ]] || {
  printf 'FAIL [FONT_COLLECTOR] unable to resolve Example build settings\n' >&2
  exit 1
}

xcodebuild \
  -workspace "$repo_root/PooTools.xcworkspace" \
  -scheme PooTools-Example \
  -configuration "$configuration" \
  -sdk iphonesimulator \
  -destination "id=$simulator_udid" \
  -derivedDataPath "$derived_data_path" \
  CODE_SIGNING_ALLOWED=NO \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=YES \
  build >/tmp/ptools-font-collector-build.log 2>&1 || {
    cat /tmp/ptools-font-collector-build.log >&2
    exit 1
  }

app_path="$target_build_dir/$product_name"
[[ -d "$app_path" ]] || { printf 'FAIL [FONT_COLLECTOR] built app not found: %s\n' "$app_path" >&2; exit 1; }

filename="$(basename "$output")"
output_directory="$(dirname "$output")"
mkdir -p "$output_directory"

xcrun simctl install "$simulator_udid" "$app_path"
xcrun simctl launch "$simulator_udid" "$bundle_id" \
  --pt-font-collector \
  "--pt-font-collector-output=$filename" \
  "--pt-font-collector-runtime=$runtime_label" >/tmp/ptools-font-collector-launch.log 2>&1

data_container="$(xcrun simctl get_app_container "$simulator_udid" "$bundle_id" data)"
snapshot_path="$data_container/Documents/$filename"
for _ in $(seq 1 60); do
  if [[ -s "$snapshot_path" ]]; then
    cp "$snapshot_path" "$output"
    printf 'PASS [FONT_COLLECTOR] snapshot=%s\n' "$output"
    printf 'INFO [FONT_COLLECTOR] formal FontCatalog.json was not modified\n' >&2
    exit 0
  fi
  sleep 1
done

printf 'FAIL [FONT_COLLECTOR] timed out waiting for %s\n' "$snapshot_path" >&2
exit 1
