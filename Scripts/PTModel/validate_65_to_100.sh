#!/usr/bin/env bash

set -euo pipefail

# English: Run the deterministic local gates for the PTModel 65-to-100 execution track.
# Español: Ejecuta las puertas locales deterministas de la ruta PTModel del 65 al 100.
# 中文：执行 PTModel 65% 到 100% 路线的本地确定性门禁。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

[[ "$(tr -d '[:space:]' < VERSION)" == "5.58.0" ]] || {
  printf 'FAIL: VERSION must remain 5.58.0 for this execution track\n' >&2
  exit 1
}

git diff --check
swift package dump-package >/dev/null

core_imports="$(rg -n --glob '*.swift' '^(import|@_exported import) (UIKit|SwiftUI|Combine|AppKit)' PooToolsSource/PToolsModelCore || true)"
if [[ -n "$core_imports" ]]; then
  printf '%s\n' "$core_imports" >&2
  printf 'FAIL: PToolsModelCore has a platform import\n' >&2
  exit 1
fi

if rg -n --glob '*.swift' 'nonisolated\(unsafe\)|try!|as!' PooToolsSource/PToolsModelCore PToolsModelMacros; then
  printf 'FAIL: unsafe escape hatch found in PTModel core or macros\n' >&2
  exit 1
fi

for file in PooToolsSource/PToolsModelCore/*.swift PooToolsSource/PToolsModel/*.swift PooToolsSource/PToolsModelUIKit/*.swift PooToolsSource/PToolsModelCombine/*.swift PToolsModelMacros/*.swift; do
  xcrun swiftc -frontend -parse "$file" >/dev/null
done

printf 'PASS: PTModel local 65-to-100 static gates\n'
