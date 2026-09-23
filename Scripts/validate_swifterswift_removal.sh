#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# English: Keep the one-shot removal enforceable in source and package manifests while allowing historical reports.
# Español: Mantiene verificable la eliminación única en el código y los manifiestos, permitiendo informes históricos.
# 中文：在源码和包清单中强制执行一次性移除，同时允许历史报告保留记录。
active_paths=(
  PooToolsSource
  PooTools
  Tests
  Package.swift
  Package.resolved
  PooTools.podspec
  Podfile.lock
  Scripts/module_registry.json
)

matches="$(rg -n --hidden --glob '!Pods/**' --glob '!build/**' 'SwifterSwift|swifterswift' "${active_paths[@]}" || true)"
if [[ -n "$matches" ]]; then
  printf '%s\n' "$matches" >&2
  printf 'FAIL: SwifterSwift remains in an active source or package manifest path\n' >&2
  exit 1
fi

printf 'PASS: SwifterSwift is absent from active source and package manifests\n'
