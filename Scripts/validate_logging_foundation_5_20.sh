#!/usr/bin/env bash

set -euo pipefail

# English: Validate the 5.20.0 logging foundation without requiring the legacy logger migration.
# Español: Valida la base de logging de 5.20.0 sin exigir todavía la migración del logger heredado.
# 中文：校验 5.20.0 日志基础层，但不提前要求迁移旧日志实现。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

version="$(tr -d '[:space:]' < VERSION)"
[[ "$version" =~ ^5\.20\.[0-9]+$ ]] || {
  printf 'FAIL: logging foundation gate requires a 5.20.x VERSION, got %s\n' "$version" >&2
  exit 1
}

required_files=(
  PooToolsSource/PToolsLogging/Core/PTLogTypes.swift
  PooToolsSource/PToolsLogging/Core/PTLogger.swift
  PooToolsSource/PToolsLogging/README.md
  docs/audits/COCOALUMBERJACK_USAGE_AUDIT.md
)
for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { printf 'FAIL: logging foundation file is missing: %s\n' "$file" >&2; exit 1; }
done

required_patterns=(
  'Package.swift|.library(name: "PToolsLogging", targets: ["PToolsLogging"])'
  'Package.swift|name: "PToolsLogging"'
  'Package.swift|"PToolsLogging"'
  'PooTools.podspec|s.subspec '\''Logging'\''' 
  'PooTools.podspec|PooToolsSource/PToolsLogging/**/*.swift'
  'PooTools.podspec|subspec.dependency '\''PooTools/Logging'\'''
  'PooToolsSource/PToolsLogging/Core/PTLogTypes.swift|public enum PTLogLevel'
  'PooToolsSource/PToolsLogging/Core/PTLogTypes.swift|public struct PTLogCategory'
  'PooToolsSource/PToolsLogging/Core/PTLogTypes.swift|public struct PTLogRecord'
  'PooToolsSource/PToolsLogging/Core/PTLogTypes.swift|public struct PTLogConfiguration'
  'PooToolsSource/PToolsLogging/Core/PTLogger.swift|public enum PTLogger'
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

printf 'PASS: PTools 5.20 logging foundation contract\n'
