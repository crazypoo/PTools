#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

debug_file="PooToolsSource/Debug/PTDebugHookRegistry.swift"
manager_file="PooToolsSource/Debug/PTDebugFunction.swift"
instrument_file="PooToolsSource/Debug/PTInstruments.swift"
ui_file="PooToolsSource/Debug/PTInstrumentsUI.swift"
console_file="PooToolsSource/LocalConsole/LocalConsole.swift"

require_fragment() {
  local file="$1"
  local fragment="$2"
  local description="$3"
  if ! rg -q --fixed-strings "$fragment" "$repo_root/$file"; then
    printf 'FAIL: %s (%s)\n' "$description" "$file" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$description"
}

for file in "$debug_file" "$manager_file" "$instrument_file" "$ui_file" "$console_file"; do
  if [[ ! -f "$file" ]]; then
    printf 'FAIL: missing Debug/Instruments source: %s\n' "$file" >&2
    exit 1
  fi
done

# English: Require one reversible registry instead of scattered Debug hook ownership.
# Español: Exige un único registro reversible en lugar de repartir la propiedad de hooks de Debug.
# 中文：要求使用一个可逆 Registry，避免 Debug Hook 所有权分散在各处。
require_fragment "$debug_file" "public final class PTDebugHookRegistry" "Debug hook registry"
require_fragment "$debug_file" "public var isInstalled: Bool" "registry installation state"
require_fragment "$debug_file" "public func install()" "registry install entry"
require_fragment "$debug_file" "public func uninstall()" "registry uninstall entry"
require_fragment "$manager_file" "PTDebugHookRegistry.shared.install(identifier:" "collector hook installation"
require_fragment "$manager_file" "PTDebugHookRegistry.shared.uninstall(identifier:" "collector hook teardown"

# English: Require bounded recording and safe archive analysis APIs.
# Español: Exige grabación acotada y APIs seguras para analizar archivos.
# 中文：要求录制有容量上限，并提供安全的归档分析 API。
require_fragment "$instrument_file" "private struct PTInstrumentRingBuffer" "bounded instrument ring buffer"
require_fragment "$instrument_file" "public static func importTrace" "trace import API"
require_fragment "$instrument_file" "public static func replay" "trace replay API"
require_fragment "$instrument_file" "public static func compare" "trace comparison API"
require_fragment "$instrument_file" "case disk" "disk instrument"
require_fragment "$instrument_file" "case viewControllerLifecycle" "view-controller lifecycle instrument"
require_fragment "$instrument_file" "case threads" "thread instrument"
require_fragment "$instrument_file" "case tasks" "task instrument"
require_fragment "$instrument_file" "case signposts" "signpost instrument"
require_fragment "$instrument_file" "public func liveSnapshot()" "live snapshot API"
require_fragment "$instrument_file" "static func freeDiskMB" "disk sampler"
require_fragment "$instrument_file" "static func threadCount" "thread sampler"
require_fragment "$ui_file" "private var liveRefreshTask" "batched dashboard refresh"
require_fragment "$console_file" "scene.coordinateSpace.bounds.size" "scene-scoped console geometry"

if rg -n '@unchecked Sendable|nonisolated\(unsafe\)|try!|as!' "$debug_file" "$instrument_file" "$ui_file"; then
  printf 'FAIL: 5.18 Debug/Instruments introduces an unsafe declaration or forceful operation\n' >&2
  exit 1
fi

printf 'PTDebug / PTInstruments 5.18 static contract OK\n'
