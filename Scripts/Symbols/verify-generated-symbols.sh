#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
generator_source="$repo_root/Tools/PTSymbolGen/main.swift"
catalog="$repo_root/PooToolsSource/PToolsSymbols/Resources/SFSymbolCatalog.json"
generated="$repo_root/PooToolsSource/PToolsSymbols/Generated/PTSymbols+iOS17.swift"
temporary_generator="$(mktemp "${TMPDIR:-/tmp}/ptsymbolgen.XXXXXX")"
temporary_output="$(mktemp "${TMPDIR:-/tmp}/ptsymbols.XXXXXX.swift")"
trap 'rm -f "$temporary_generator" "$temporary_output"' EXIT

swiftc "$generator_source" -o "$temporary_generator"
"$temporary_generator" generate "$catalog" "$temporary_output"
if ! diff -u "$generated" "$temporary_output"; then
  printf 'FAIL: generated PTSymbol source is stale\n' >&2
  exit 1
fi
printf 'PASS: generated PTSymbol source matches catalog\n'
