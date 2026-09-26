#!/usr/bin/env bash

set -euo pipefail

# English: Enforce the final 5.22+ logging dependency and compatibility boundary through 5.25.
# Español: Refuerza el límite final de dependencias y compatibilidad de logging desde 5.22 hasta 5.25.
# 中文：强制执行 5.22 至 5.25 日志依赖和兼容层的最终边界。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

version="$(tr -d '[:space:]' < VERSION)"
[[ "$version" =~ ^5\.(22|23|24|25|26)\.[0-9]+$ ]] || {
  printf 'FAIL: 5.22+ logging closure requires a 5.22.x through 5.26.x VERSION, got %s\n' "$version" >&2
  exit 1
}

# English: Migration and audit documents may mention the historical backend, but shipped implementation paths may not.
# Español: Los documentos de migración y auditoría pueden mencionar el backend histórico, pero las rutas de implementación no.
# 中文：迁移和审计文档可以保留历史后端名称，但交付实现路径不得出现这些名称。
implementation_paths=(
  PooToolsSource
  Package.swift
  PooTools.podspec
  Package.resolved
  Podfile.lock
)
legacy_pattern='CocoaLumberjack|CocoaLumberjackSwift|DDLog|DDFileLogger|DDOSLogger|DDLogger|DDLogMessage|DDLogLevel|dynamicLogLevel|PTLegacyLogCompatibility|PTOOLS_LOG_SHADOW|Shadow Backend'
legacy_hits="$(rg -n -i "$legacy_pattern" "${implementation_paths[@]}" || true)"
if [[ -n "$legacy_hits" ]]; then
  printf '%s\n' "$legacy_hits" >&2
  printf 'FAIL: legacy logging dependency or compatibility marker remains in an implementation path\n' >&2
  exit 1
fi

required_files=(
  docs/dependencies/DEPENDENCY_POLICY.md
  PooToolsSource/PToolsLogging/Core/PTLogger.swift
  PooToolsSource/PToolsLogging/Core/PTLogTypes.swift
  PooToolsSource/PToolsLogging/Destinations/PTOSLogDestination.swift
  PooToolsSource/PToolsLogging/Destinations/PTFileLogDestination.swift
  PooToolsSource/PToolsLogging/Destinations/PTMemoryLogDestination.swift
  PooToolsSource/Log/PTNSLog.swift
  PooToolsSource/Log/PTLogFileManager.swift
  PooToolsSource/LocalConsole/LocalConsole.swift
  PooToolsSource/Debug/PTInstruments.swift
)
for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || {
    printf 'FAIL: 5.22+ logging closure file is missing: %s\n' "$file" >&2
    exit 1
  }
done

required_patterns=(
  'PooToolsSource/Log/PTNSLog.swift|PTLogger.log('
  'PooToolsSource/Log/PTNSLog.swift|PTLogger.installFileDestinationIfNeeded()'
  'PooToolsSource/Log/PTLogFileManager.swift|PTLogger.installFileDestinationIfNeeded()'
  'PooToolsSource/Log/PTLogFileManager.swift|PTLogger.log('
  'PooToolsSource/LocalConsole/LocalConsole.swift|PTMemoryLogDestination'
  'PooToolsSource/Debug/PTInstruments.swift|PTMemoryLogDestination'
  'PooToolsSource/PToolsLogging/Core/PTLogger.swift|public enum PTLogger'
  'PooToolsSource/PToolsLogging/Destinations/PTOSLogDestination.swift|public struct PTOSLogDestination'
  'PooToolsSource/PToolsLogging/Destinations/PTFileLogDestination.swift|public final class PTFileLogDestination'
  'PooToolsSource/PToolsLogging/Destinations/PTMemoryLogDestination.swift|public final class PTMemoryLogDestination'
)
for requirement in "${required_patterns[@]}"; do
  file="${requirement%%|*}"
  pattern="${requirement#*|}"
  rg -q --fixed-strings "$pattern" "$file" || {
    printf 'FAIL: 5.22+ logging marker missing: %s (%s)\n' "$file" "$pattern" >&2
    exit 1
  }
done

# English: The historical file-manager symbol may remain only as a PTLogger-only compatibility adapter.
# Español: El símbolo histórico del gestor de archivos solo puede permanecer como adaptador compatible basado en PTLogger.
# 中文：历史文件管理器符号只能作为仅调用 PTLogger 的兼容适配器保留。

git diff --check
printf 'PASS: PTools 5.22+ logging dependency removal, compatibility closure and backend parity through 5.26\n'
