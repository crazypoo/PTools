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
require_fragment "$instrument_file" "PTLogSinkCenter.shared.install" "existing Core log sink bridge"
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

printf 'PTInstruments 5.11 static contract OK\n'
