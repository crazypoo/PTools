#!/usr/bin/env bash

set -euo pipefail

# English: Validate the 5.21 logging migration, Debug bridge and privacy contracts.
# Español: Valida la migración de logging, el puente de Debug y los contratos de privacidad de 5.21.
# 中文：校验 5.21 日志迁移、Debug 桥接和隐私契约。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

version="$(tr -d '[:space:]' < VERSION)"
[[ "$version" =~ ^5\.21\.[0-9]+$ ]] || {
  printf 'FAIL: 5.21 logging gate requires a 5.21.x VERSION, got %s\n' "$version" >&2
  exit 1
}

required_files=(
  PooToolsSource/PToolsLogging/Core/PTLogTypes.swift
  PooToolsSource/PToolsLogging/Core/PTLogger.swift
  PooToolsSource/PToolsLogging/Destinations/PTMemoryLogDestination.swift
  PooToolsSource/PToolsLogging/Privacy/PTLogRedactor.swift
  PooToolsSource/LocalConsole/LocalConsole.swift
  PooToolsSource/Debug/PTInstruments.swift
  PooToolsSource/NetWork/Network+Logging.swift
  Tests/PToolsLoggingTests/PTLoggingFoundationTests.swift
  Tests/PToolsLoggingTests/PTLoggingPerformanceTests.swift
)
for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || {
    printf 'FAIL: 5.21 logging file is missing: %s\n' "$file" >&2
    exit 1
  }
done

# English: CocoaLumberjack remains a compatibility dependency, but PTools production Swift no longer calls it directly.
# Español: CocoaLumberjack sigue siendo una dependencia de compatibilidad, pero Swift de producción ya no la llama directamente.
# 中文：CocoaLumberjack 仍作为兼容依赖保留，但 PTools 生产 Swift 不再直接调用它。
if rg -n --glob '*.swift' 'DDLog|import CocoaLumberjack' PooToolsSource; then
  printf 'FAIL: direct CocoaLumberjack usage remains in PooTools production Swift\n' >&2
  exit 1
fi

required_patterns=(
  'PooToolsSource/PToolsLogging/Destinations/PTMemoryLogDestination.swift|public actor PTMemoryLogStore'
  'PooToolsSource/PToolsLogging/Destinations/PTMemoryLogDestination.swift|Task.detached'
  'PooToolsSource/PToolsLogging/Destinations/PTMemoryLogDestination.swift|PTLogDropPolicy'
  'PooToolsSource/PToolsLogging/Core/PTLogger.swift|installMemoryDestination'
  'PooToolsSource/PToolsLogging/Core/PTLogger.swift|exportLogFiles'
  'PooToolsSource/PToolsLogging/Privacy/PTLogRedactor.swift|redact(record:'
  'PooToolsSource/LocalConsole/LocalConsole.swift|logCategoryFilter'
  'PooToolsSource/LocalConsole/LocalConsole.swift|logLevelFilter'
  'PooToolsSource/LocalConsole/LocalConsole.swift|logKeywordFilter'
  'PooToolsSource/Debug/PTInstruments.swift|PTLogRecord'
  'PooToolsSource/NetWork/Network+Logging.swift|redactedHeaders'
  'Tests/PToolsLoggingTests/PTLoggingPerformanceTests.swift|measure'
)
for requirement in "${required_patterns[@]}"; do
  file="${requirement%%|*}"
  pattern="${requirement#*|}"
  rg -q --fixed-strings "$pattern" "$file" || {
    printf 'FAIL: 5.21 logging marker missing: %s (%s)\n' "$file" "$pattern" >&2
    exit 1
  }
done

printf 'PASS: PTools 5.21 logging migration, memory diagnostics and privacy contracts\n'
