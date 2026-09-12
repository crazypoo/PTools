#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# English: Keep the Core-to-Debug boundary executable as a small, repeatable gate.
# Español: Mantén el límite Core→Debug como una puerta pequeña y repetible.
# 中文：将 Core 到 Debug 的边界固化为小而可重复执行的门禁。
core_paths=(
  PooToolsSource/Core
  PooToolsSource/Blur
  PooToolsSource/ActionsheetAndAlert
  PooToolsSource/Base
  PooToolsSource/AppStore
  PooToolsSource/ApplicationFunction
  PooToolsSource/BlackMagic
  PooToolsSource/Button
  PooToolsSource/Category
  PooToolsSource/Log
  PooToolsSource/StatusBar
  PooToolsSource/Protocol
  PooToolsSource/Animation
  PooToolsSource/PermissionCore
  PooToolsSource/PhotoLibraryPermission
  PooToolsSource/AppDelegate
  PooToolsSource/Foundation
  PooToolsSource/Language
  PooToolsSource/DarkMode
  PooToolsSource/Line
  PooToolsSource/Badge
  PooToolsSource/Rotation
  PooToolsSource/Switch
  PooToolsSource/Colors
  PooToolsSource/Font
  PooToolsSource/FloatPanel
  PooToolsSource/SideMenuControl
  PooToolsSource/iCloud
)

forbidden_core_references='\b(LocalConsole|PTLogLevel|PTConsoleWindow|TouchInspectorWindow|PTDebugFunction|PTDevFunction|Inspector|PTDebugPreferences|PTDebugManager)\b'
core_references="$(rg -n --glob '*.swift' "$forbidden_core_references" "${core_paths[@]}" || true)"
if [[ -n "$core_references" ]]; then
  printf '%s\n' "$core_references" >&2
  printf 'FAIL: Core source contains a direct Debug reference\n' >&2
  exit 1
fi

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

require_fragment "PooToolsSource/Core/PTUtils.swift" "public enum PTUIKitRuntimeHooks" "Core runtime hook contract"
require_fragment "PooToolsSource/Log/PTNSLog.swift" "public final class PTLogSinkCenter" "Core log sink contract"
require_fragment "PooToolsSource/Debug/PTDebugFunction.swift" "public final class PTDebugManager" "Debug manager foundation"
require_fragment "PooToolsSource/Debug/PTDebugFunction.swift" "public final class PTDebugEventCenter" "Debug event foundation"
require_fragment "PooToolsSource/Debug/PTDebugFunction.swift" "public final class PTDebugPreferences" "Debug preference owner"
require_fragment "PooToolsSource/BlackMagic/PTSwiftMethodSwizzle.swift" "public static func registeredOwners()" "Swizzle owner registry"
require_fragment "PooToolsSource/LocalConsole/LocalConsole.swift" "PTDebugManager.shared.startSession(owner:" "Scene-scoped Debug session start"
require_fragment "PooToolsSource/LocalConsole/LocalConsole.swift" "PTDebugManager.shared.stopSession(owner:" "Scene-scoped Debug session stop"
require_fragment "Package.swift" "name: \"PooToolsDEBUG\"" "SwiftPM Debug target"
require_fragment "Package.swift" "dependencies: [\"ptools\", \"PooToolsNetWork\"" "SwiftPM Debug depends on Core"
require_fragment "PooTools.podspec" "s.subspec 'DEBUG'" "CocoaPods Debug subspec"
require_fragment "PooTools.podspec" "subspec.dependency 'PooTools/Core'" "CocoaPods Debug depends on Core"

# English: Bootstrap belongs to collectors; LocalConsole may still present an Inspector menu action.
# Español: El arranque pertenece a los collectors; LocalConsole aún puede presentar una acción de menú Inspector.
# 中文：启动职责归 Collector；LocalConsole 可以保留打开 Inspector 的菜单动作。
bootstrap_references="$(rg -n --glob '*.swift' 'PTNetworkHelper\.shared\.(enable|disable)|StdoutCapture\.(start|stop)Capturing|StderrCapture\.(start|stop)Capturing|Inspector\.sharedInstance\.start|PTCrashManager\.register|PTLaunchTimeTracker\.measureAppStartUpTime|PTPerformanceLeakDetector\.setup|CLLocationManager\.swizzleMethods' PooToolsSource/LocalConsole || true)"
if [[ -n "$bootstrap_references" ]]; then
  printf '%s\n' "$bootstrap_references" >&2
  printf 'FAIL: LocalConsole still owns a collector bootstrap call\n' >&2
  exit 1
fi

printf 'Debug Foundation 5.10 static contract OK\n'
