#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

instrument_file="PooToolsSource/Debug/PTInstruments.swift"
ui_file="PooToolsSource/Debug/PTInstrumentsUI.swift"

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

for file in "$instrument_file" "$ui_file"; do
  if [[ ! -f "$file" ]]; then
    printf 'FAIL: Instruments source is missing: %s\n' "$file" >&2
    exit 1
  fi
done

# English: Keep the Instruments data chain complete and opt-in.
# Español: Mantén completa y opt-in la cadena de datos de Instruments.
# 中文：确保 Instruments 数据链路完整，并且必须显式启用。
require_fragment "$instrument_file" "public actor PTInstrumentSession" "session owns mutable recording state"
require_fragment "$instrument_file" "public final class PTInstrumentRecorder" "recorder lifecycle contract"
require_fragment "$instrument_file" "public struct PTInstrumentSamplingPolicy" "sampling policy contract"
require_fragment "$instrument_file" "public enum PTInstrumentTraceStore" "trace storage contract"
require_fragment "$instrument_file" "public enum PTInstrumentRedactor" "export redaction contract"
require_fragment "$instrument_file" "PTDebugEventCenter.shared.addObserver" "existing Debug event bridge"
# English: Instruments consumes the shared bounded PTLogger memory destination.
# Español: Instruments consume el destino de memoria acotado y compartido de PTLogger.
# 中文：Instruments 消费共享的有界 PTLogger 内存日志目标。
require_fragment "$instrument_file" "PTLogger.memoryDestination() ?? PTLogger.installMemoryDestination()" "shared PTLogger memory bridge"
require_fragment "$instrument_file" "public func recordCrashMarker" "safe explicit crash marker"
require_fragment "$instrument_file" "CADisplayLink" "display-link performance sampling"
require_fragment "$instrument_file" "await MainActor.run { () }" "cancellable main-thread stall probe"
require_fragment "$ui_file" "public final class PTInstrumentTimelineView" "timeline UI contract"
require_fragment "$ui_file" "public final class PTInstrumentEventInspectorViewController" "event inspector UI contract"
require_fragment "$ui_file" "public final class PTInstrumentDashboardViewController" "dashboard UI contract"

if rg -n '@unchecked Sendable|nonisolated\(unsafe\)|try!|as!' "$instrument_file" "$ui_file"; then
  printf 'FAIL: 5.11 Instruments introduces an unsafe declaration or forceful operation\n' >&2
  exit 1
fi

# English: Instruments must consume existing collectors instead of installing duplicate hooks.
# Español: Instruments debe consumir los collectors existentes en vez de instalar hooks duplicados.
# 中文：Instruments 必须消费现有 Collector，不得重复安装 hook。
if rg -n 'PTNetworkHelper|PTPerformanceLeakDetector\.setup|lvcdSwizzleLifecycleMethods|Swizzle\(' "$instrument_file" "$ui_file"; then
  printf 'FAIL: Instruments source installs a duplicate collector or swizzle\n' >&2
  exit 1
fi

# English: A disabled recorder has no sampler task; recording is started only through the explicit API.
# Español: Un recorder desactivado no tiene tareas de muestreo; la grabación solo comienza mediante la API explícita.
# 中文：Recorder 未启用时不创建采样任务，只有显式 API 才会开始录制。
if rg -n 'PTInstrumentRecorder\.shared\.start\(' PooToolsSource --glob '*.swift' | rg -v 'PTInstruments.swift|PTInstrumentsUI.swift'; then
  printf 'FAIL: production source starts Instruments implicitly\n' >&2
  exit 1
fi

# PR15: Studio must reuse PTInstruments and must not install a second FPS
# DisplayLink or another Mach-based CPU/memory reader.
studio_agent="PooToolsSource/DebugStudioBridge/PTStudioDiagnosticAgent.swift"
inventory_core="PooToolsSource/PToolsDebugInventoryCore/PTDebugInventoryCore.swift"
require_fragment "$studio_agent" "startStudioSamplerIfNeeded()" "Studio requests an existing recorder"
require_fragment "$studio_agent" "releaseStudioSamplerIfOwned()" "Studio releases only its own session"
require_fragment "$instrument_file" "public func latestSamples(for kinds:" "bounded metric snapshot API"
metrics_core="PooToolsSource/PToolsDebugMetricsCore/PTDebugRingBuffer.swift"
ownership_core="PooToolsSource/PToolsDebugCore/PTDebugSessionOwnerLedger.swift"
require_fragment "$metrics_core" "public var latestValue: Element?" "O(1) ring buffer latest accessor"
require_fragment "$instrument_file" "private typealias PTInstrumentRingBuffer<Element> = PTDebugRingBuffer<Element>" "single metrics buffer backend"
require_fragment "$ownership_core" "public struct PTDebugSessionOwnerLedger" "Foundation Debug lifecycle owner"
require_fragment "PooToolsSource/Debug/PTDebugFunction.swift" "sessionOwners.acquire(owner)" "DebugManager lifecycle adapter"
require_fragment "Package.swift" 'name: "PToolsDebugCore"' "SwiftPM Debug Core"
require_fragment "Package.swift" 'name: "PToolsDebugMetricsCore"' "SwiftPM Debug Metrics Core"
require_fragment "PooTools.podspec" 'PooToolsSource/PToolsDebugCore/**/*.swift' "CocoaPods Debug Core source parity"
require_fragment "PooTools.podspec" 'PooToolsSource/PToolsDebugMetricsCore/**/*.swift' "CocoaPods Debug Metrics Core source parity"
if rg -n '^import (UIKit|AppKit|SwiftUI)' "$metrics_core" "$ownership_core"; then
  printf 'FAIL: shared Debug Core and Metrics Core must be platform-neutral\n' >&2
  exit 1
fi
require_fragment "$inventory_core" "public enum PTDebugInventoryCore" "Foundation-only Debug inventory owner"

if rg -n 'CADisplayLink|mach_task_basic_info|task_threads|task_info\\(' "$studio_agent"; then
  printf 'FAIL: Studio reintroduces a duplicate performance collector\n' >&2
  exit 1
fi
if rg -n '^import (UIKit|AppKit|SwiftUI)' "$inventory_core"; then
  printf 'FAIL: DebugInventoryCore must remain Foundation-only\n' >&2
  exit 1
fi
require_fragment "Package.swift" 'name: "PToolsDebugInventoryCore"' "SwiftPM independent inventory target"
inspector_core="PooToolsSource/PToolsDebugInspectorCore/PTDebugInspectorSnapshotSignature.swift"
require_fragment "$inspector_core" "public enum PTDebugInspectorSnapshotSignature" "UIKit-free Inspector fingerprint owner"
require_fragment "$studio_agent" "PTDebugInspectorSnapshotSignature.fingerprint(entries:" "Studio reuses canonical fingerprint"
require_fragment "Package.swift" 'name: "PToolsDebugInspectorCore"' "SwiftPM inspector target"
require_fragment "PooTools.podspec" 'PooToolsSource/PToolsDebugInspectorCore/**/*.swift' "CocoaPods inspector source parity"
if rg -n '^import (UIKit|AppKit|SwiftUI)' "$inspector_core"; then
  printf 'FAIL: DebugInspectorCore must remain platform-neutral\n' >&2
  exit 1
fi
require_fragment "PooTools.podspec" 'PooToolsSource/PToolsDebugInventoryCore/**/*.swift' "CocoaPods inventory parity"

# PR23–PR25: Network capture's canonical types, Actor Store and privacy
# live outside the UIKit Debug target in SwiftPM. CocoaPods DEBUG intentionally
# aggregates those same source files once to preserve the existing Pod API.
network_core_files=(
  PooToolsSource/DebugNetwork/PTNetworkCaptureModels.swift
  PooToolsSource/DebugNetwork/PTNetworkCaptureStore.swift
  PooToolsSource/DebugNetwork/PTNetworkRedactor.swift
)
require_fragment "Package.swift" 'name: "PToolsDebugNetworkCore"' "standalone SwiftPM capture core"
require_fragment "Package.swift" 'exclude: ["DebugNetwork/PTNetworkCaptureModels.swift", "DebugNetwork/PTNetworkCaptureStore.swift", "DebugNetwork/PTNetworkRedactor.swift"]' "no duplicated SwiftPM capture sources"
require_fragment "Package.swift" '"PToolsDebugNetworkCore", "PToolsDebugCore"' "Debug facade consumes capture core"
require_fragment "PooToolsSource/DebugNetwork/PTNetworkCaptureCoreExport.swift" '@_exported import PToolsDebugNetworkCore' "legacy import surface preserved"
require_fragment "PooToolsSource/DebugStudioBridge/PTStudioBridge.swift" 'import PToolsDebugNetworkCore' "Studio bridge uses canonical capture data types"
require_fragment "PooTools.podspec" 'PooToolsSource/DebugNetwork/*.{h,m,swift}' "CocoaPods aggregated capture and DebugNetwork UI"
for file in "${network_core_files[@]}"; do
  if rg -n '^import (UIKit|AppKit|SwiftUI|ptools)' "$file"; then
    printf 'FAIL: Network capture core must not depend on UI or app Core: %s\n' "$file" >&2
    exit 1
  fi
done

# PR26–PR30: the 5.x Debug facade retains source compatibility, but it
# must not own additional copies of Storage, Console or Inspector helpers.
require_fragment "Package.swift" 'name: "PToolsDebugStorageCore"' "Storage facade has an independent SwiftPM target"
require_fragment "Package.swift" 'name: "PToolsDebugInspectorUI"' "Inspector overlay has an independent UIKit target"
require_fragment "Package.swift" '"Debug/PTDebugInventory.swift"' "Storage adapter excluded from DEBUG compilation"
require_fragment "PooToolsSource/Debug/PTDebugStorageCoreExports.swift" '@_exported import PToolsDebugStorageCore' "legacy Storage facade import"
require_fragment "PooToolsSource/Debug/PTDebugCoreExports.swift" '@_exported import PToolsDebugCore' "legacy Console event import"
require_fragment "PooToolsSource/DebugStudioBridge/PTStudioDiagnosticAgent.swift" 'PTDebugInspectorHighlight.show(view)' "single Inspector overlay owner"
require_fragment "PooTools.podspec" 'PooToolsSource/PToolsDebugInspectorUI/**/*.swift' "CocoaPods Inspector overlay parity"
require_fragment "PooToolsSource/PToolsDebugCore/PTDebugEvents.swift" 'public final class PTDebugEventCenter' "Console event center in Foundation Core"
require_fragment "PooToolsSource/DebugNetwork/PTNetworkDebugSupport.swift" 'import PToolsDebugNetworkCore' "presentation imports canonical Network models"
if rg -n '^public (struct PTDebugEvent|final class PTDebugEventCenter)' PooToolsSource/Debug/PTDebugFunction.swift; then
  printf 'FAIL: Console event declarations still duplicated in UIKit DEBUG\n' >&2
  exit 1
fi
if rg -n '^import (UIKit|AppKit|SwiftUI)' PooToolsSource/PToolsDebugCore/PTDebugEvents.swift PooToolsSource/Debug/PTDebugInventory.swift; then
  printf 'FAIL: Console/Storage core source unexpectedly depends on presentation\n' >&2
  exit 1
fi

require_fragment "Package.swift" 'name: "PToolsDebugInspectorLegacyUI"' "full local Inspector UIKit target"
require_fragment "Package.swift" 'name: "PToolsDebugConsoleCore"' "Console data core target"
require_fragment "Package.swift" 'exclude: ["PTDebugEvents.swift"]' "Debug Core compilation must not duplicate Console events"
require_fragment "Package.swift" 'path: "PooToolsSource/Inspector"' "Inspector source ownership"
require_fragment "PooToolsSource/Debug/PTDebugInspectorLegacyExports.swift" '@_exported import PToolsDebugInspectorLegacyUI' "Inspector 5.x import facade"
require_fragment "PooToolsSource/PToolsDebugCore/PTDebugConsoleExports.swift" '@_exported import PToolsDebugConsoleCore' "Console 5.x import facade"
require_fragment "PooToolsSource/Debug/PTInstrumentsUI.swift" 'PTDebugTimelineGeometry(' "Metrics UI uses independent geometry"
require_fragment "PooToolsSource/DebugNetwork/PTNetworkWatcherViewController.swift" 'changes(bufferingNewest: 32)' "DebugNetwork UI bounded subscriber"
printf 'PTInstruments 5.11 static contract OK\n'
