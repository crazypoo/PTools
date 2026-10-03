#!/usr/bin/env bash

set -euo pipefail

# English: Prepare only the command-line tools used by the repository quality gates.
# Español: Prepara únicamente las herramientas de línea de comandos usadas por las puertas de calidad del repositorio.
# 中文：只准备仓库质量门禁实际使用的命令行工具。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
need_cocoapods=0
if [[ "${1:-}" == "--cocoapods" ]]; then
  need_cocoapods=1
elif [[ "${1:-}" != "" ]]; then
  printf 'Usage: %s [--cocoapods]\n' "$0" >&2
  exit 64
fi

require_command() {
  local command_name="$1"
  local purpose="$2"
  if command -v "$command_name" >/dev/null 2>&1; then
    printf 'PASS [QUALITY_TOOL] %s -> %s\n' "$command_name" "$(command -v "$command_name")"
    return 0
  fi
  printf 'FAIL [QUALITY_TOOL_MISSING] command=%s purpose=%s\n' "$command_name" "$purpose" >&2
  return 1
}

if ! command -v rg >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    # English: Install ripgrep before legacy governance scripts that still use its richer glob syntax.
    # Español: Instala ripgrep antes de ejecutar scripts de gobernanza heredados que aún usan su sintaxis de glob.
    # 中文：在仍使用高级 glob 语法的旧治理脚本运行前安装 ripgrep。
    printf 'INFO [QUALITY_TOOL_INSTALL] installing ripgrep with Homebrew\n'
    brew install ripgrep
  else
    # English: The portable core gate still has a grep fallback, but the complete legacy scan needs an explicit blocker.
    # Español: La puerta principal portátil aún tiene fallback con grep, pero el escaneo heredado completo necesita un bloqueo explícito.
    # 中文：核心门禁仍可回退到 grep，但完整旧脚本扫描需要明确报告工具阻断。
    printf 'FAIL [QUALITY_TOOL_MISSING] command=rg purpose=legacy governance scripts; install ripgrep or use a runner image that provides it\n' >&2
    exit 1
  fi
fi
printf 'PASS [QUALITY_TOOL] rg -> %s\n' "$(command -v rg)"
require_command grep "POSIX search fallback"
require_command sed "diagnostic extraction"
require_command ruby "Ruby governance and package checks"
require_command python3 "Python governance and catalog checks"
require_command swift "SwiftPM and Swift source checks"
require_command xcodebuild "Xcode workspace checks"

if [[ "$need_cocoapods" -eq 1 ]]; then
  if ! command -v pod >/dev/null 2>&1; then
    if command -v brew >/dev/null 2>&1; then
      printf 'INFO [QUALITY_TOOL_INSTALL] installing CocoaPods with Homebrew\n'
      brew install cocoapods
    elif command -v gem >/dev/null 2>&1; then
      printf 'INFO [QUALITY_TOOL_INSTALL] installing CocoaPods with RubyGems\n'
      gem install cocoapods --no-document
    else
      printf 'FAIL [QUALITY_TOOL_MISSING] CocoaPods is unavailable and neither Homebrew nor RubyGems is available\n' >&2
      exit 1
    fi
  fi
  require_command pod "workspace Pods generation and CocoaPods validation"
fi

# English: Keep the dependency scan explicit so a new shell tool cannot silently become a CI assumption.
# Español: Mantiene explícito el escaneo de dependencias para que una nueva herramienta no se convierta silenciosamente en un supuesto de CI.
# 中文：显式扫描依赖，避免新增脚本工具后悄然变成 CI 的隐含前提。
printf 'INFO [QUALITY_TOOL_SCAN] scanning Scripts and .github for external command references\n'
for tool in rg jq yq python python3 ruby swiftformat swiftlint; do
  matches="$(grep -RInE --exclude-dir=.git --exclude='*.md' "(^|[[:space:](\"'])${tool}([[:space:])]|$)" "$repo_root/Scripts" "$repo_root/.github" 2>/dev/null || true)"
  if [[ -n "$matches" ]]; then
    case "$tool" in
      rg) strategy="workflow installs ripgrep; shell gates also provide grep fallback" ;;
      jq|yq) strategy="install explicitly in workflow before use, or replace with Python/Ruby fallback" ;;
      python) strategy="use python3 explicitly" ;;
      python3) strategy="runner prerequisite; fail with a diagnostic when missing" ;;
      ruby) strategy="runner prerequisite; fail with a diagnostic when missing" ;;
      swiftformat|swiftlint) strategy="install explicitly in workflow before introducing a gate dependency" ;;
    esac
    printf 'INFO [QUALITY_TOOL_REFERENCE] %s -> %s\n' "$tool" "$strategy"
  fi
done

printf 'PASS [QUALITY_ENVIRONMENT] command dependencies are available\n'
