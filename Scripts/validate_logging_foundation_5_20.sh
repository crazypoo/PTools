#!/usr/bin/env bash

set -euo pipefail

# English: Validate the logging foundation across the maintained 5.x line.
# Español: Valida la base de logging en toda la línea 5.x mantenida.
# 中文：校验当前维护的 5.x 全版本日志基础层。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

version="$(tr -d '[:space:]' < VERSION)"
[[ "$version" =~ ^5\.[0-9]+\.[0-9]+$ ]] || {
  printf 'FAIL: logging foundation gate requires a 5.x VERSION, got %s\n' "$version" >&2
  exit 1
}

required_files=(
  PooToolsSource/PToolsLogging/Core/PTLogTypes.swift
  PooToolsSource/PToolsLogging/Core/PTLogger.swift
  PooToolsSource/PToolsLogging/Destinations/PTOSLogDestination.swift
  PooToolsSource/PToolsLogging/Destinations/PTFileLogDestination.swift
  PooToolsSource/PToolsLogging/File/PTLogFileWriter.swift
  PooToolsSource/PToolsLogging/Privacy/PTLogRedactor.swift
  PooToolsSource/PToolsLogging/Internal/PTLoggerInternalDiagnostics.swift
  PooToolsSource/PToolsLogging/README.md
  Tests/PToolsLoggingTests/PTLoggingFoundationTests.swift
  docs/audits/COCOALUMBERJACK_USAGE_AUDIT.md
)
for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { printf 'FAIL: logging foundation file is missing: %s\n' "$file" >&2; exit 1; }
done

required_patterns=(
  'Package.swift|.library(name: "PToolsLogging", targets: ["PToolsLogging"])'
  'Package.swift|name: "PToolsLogging"'
  'Package.swift|"PToolsLogging"'
  'Package.swift|name: "PToolsLoggingTests"'
  'PooTools.podspec|s.subspec '\''Logging'\''' 
  'PooTools.podspec|PooToolsSource/PToolsLogging/**/*.swift'
  'PooTools.podspec|subspec.dependency '\''PooTools/Logging'\'''
  'PooToolsSource/PToolsLogging/Core/PTLogTypes.swift|public enum PTLogLevel'
  'PooToolsSource/PToolsLogging/Core/PTLogTypes.swift|public struct PTLogCategory'
  'PooToolsSource/PToolsLogging/Core/PTLogTypes.swift|public struct PTLogRecord'
  'PooToolsSource/PToolsLogging/Core/PTLogTypes.swift|public struct PTLogConfiguration'
  'PooToolsSource/PToolsLogging/Core/PTLogger.swift|public enum PTLogger'
  'PooToolsSource/PToolsLogging/Destinations/PTOSLogDestination.swift|public struct PTOSLogDestination'
  'PooToolsSource/PToolsLogging/Destinations/PTFileLogDestination.swift|public final class PTFileLogDestination'
  'PooToolsSource/PToolsLogging/File/PTLogFileWriter.swift|actor PTLogFileWriter'
  'PooToolsSource/PToolsLogging/Privacy/PTLogRedactor.swift|public enum PTLogRedactor'
  'PooToolsSource/PToolsLogging/Core/PTLogger.swift|installFileDestination'
  'PooToolsSource/PToolsLogging/Core/PTLogger.swift|logFiles'
)
for requirement in "${required_patterns[@]}"; do
  file="${requirement%%|*}"
  pattern="${requirement#*|}"
  rg -q --fixed-strings "$pattern" "$file" || {
    printf 'FAIL: logging foundation marker missing: %s (%s)\n' "$file" "$pattern" >&2
    exit 1
  }
done

if rg -n --glob '*.swift' '^(import|@_exported import) (UIKit|CocoaLumberjack|Alamofire|SnapKit|Kingfisher)' PooToolsSource/PToolsLogging; then
  printf 'FAIL: PToolsLogging imports a forbidden UI, legacy logger, network, layout, or image module\n' >&2
  exit 1
fi

printf 'PASS: PTools 5.x logging foundation contract\n'
