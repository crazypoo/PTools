#!/usr/bin/env bash

set -euo pipefail

# English: Validate the 5.21–5.25 logging migration, Debug bridge and privacy contracts.
# Español: Valida la migración de logging, el puente de Debug y los contratos de privacidad de 5.21–5.25.
# 中文：校验 5.21–5.25 日志迁移、Debug 桥接和隐私契约。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

version="$(tr -d '[:space:]' < VERSION)"
[[ "$version" =~ ^5\.(21|22|23|24|25|26|27)\.[0-9]+$ ]] || {
  printf 'FAIL: 5.21–5.27 logging gate requires a 5.21.x through 5.27.x VERSION, got %s\n' "$version" >&2
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
    printf 'FAIL: 5.21–5.25 logging file is missing: %s\n' "$file" >&2
    exit 1
  }
done

# English: PTools production Swift must route logging through PTLogger; legacy backend calls are forbidden.
# Español: El Swift de producción de PTools debe dirigir el logging por PTLogger; se prohíben los backends heredados.
# 中文：PTools 生产 Swift 必须统一通过 PTLogger 记录日志，禁止调用旧日志后端。
if rg -n --glob '*.swift' 'DDLog|import CocoaLumberjack' PooToolsSource; then
  printf 'FAIL: direct legacy logging usage remains in PooTools production Swift\n' >&2
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
    printf 'FAIL: 5.21–5.25 logging marker missing: %s (%s)\n' "$file" "$pattern" >&2
    exit 1
  }
done

printf 'PASS: PTools 5.21–5.27 logging migration, memory diagnostics and privacy contracts\n'
