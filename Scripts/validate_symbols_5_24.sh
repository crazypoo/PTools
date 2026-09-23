#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

bash Scripts/Symbols/verify-generated-symbols.sh

active_paths=(
  PooToolsSource
  PooTools
  Tests
  Package.swift
  Package.resolved
  PooTools.podspec
  Podfile.lock
  Scripts
)

if rg -n --hidden --glob '!Pods/**' --glob '!build/**' --glob '!Scripts/validate_symbols_5_24.sh' 'SafeSFSymbols|safeSFSymbols' "${active_paths[@]}"; then
  printf 'FAIL: SafeSFSymbols remains in an active source, package, or CI path\n' >&2
  exit 1
fi

static_system_calls="$(rg -n --glob '*.swift' 'UIImage\(systemName:\s*"' PooToolsSource PooTools Tests \
  | rg -v 'PooToolsSource/PToolsSymbols/PTSymbolResolver.swift|PooToolsSource/Category/UIImage\+PTEX.swift|PooToolsSource/Core/PTLoadImageFunction.swift|PooToolsSource/Category/UIView\+PTEX.swift|PooToolsSource/Category/String\+PTEX.swift|Tests/' || true)"
if [[ -n "$static_system_calls" ]]; then
  printf '%s\n' "$static_system_calls" >&2
  printf 'FAIL: static UIImage(systemName:) call is outside the dynamic resolver allowlist\n' >&2
  exit 1
fi

if rg -n --glob '*.swift' 'UIImage\(systemName:.*\)!|UIImage\(.*\)!' PooToolsSource/PToolsSymbols; then
  printf 'FAIL: PToolsSymbols contains a force-unwrapped symbol image\n' >&2
  exit 1
fi

printf 'PASS: PTools 5.24 symbol dependency, generated catalog, and static-call guards\n'
