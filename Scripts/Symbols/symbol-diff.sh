#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
generator_source="$repo_root/Tools/PTSymbolGen/main.swift"
old_catalog="${1:-}"
new_catalog="${2:-$repo_root/PooToolsSource/PToolsSymbols/Resources/SFSymbolCatalog.json}"
report="${3:-$repo_root/docs/reports/SYMBOL_CATALOG_DIFF.md}"

if [[ -z "$old_catalog" ]]; then
  printf 'usage: %s <old-catalog.json> [new-catalog.json] [report.md]\n' "$0" >&2
  exit 2
fi

temporary_generator="$(mktemp "${TMPDIR:-/tmp}/ptsymbolgen.XXXXXX")"
trap 'rm -f "$temporary_generator"' EXIT
swiftc "$generator_source" -o "$temporary_generator"
"$temporary_generator" diff "$old_catalog" "$new_catalog" "$report"
printf 'Generated %s\n' "$report"
