#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
generator_source="$repo_root/Tools/PTSymbolGen/main.swift"
catalog="$repo_root/PooToolsSource/PToolsSymbols/Resources/SFSymbolCatalog.json"
generated="$repo_root/PooToolsSource/PToolsSymbols/Generated/PTSymbols+iOS17.swift"
temporary_generator="$(mktemp "${TMPDIR:-/tmp}/ptsymbolgen.XXXXXX")"
trap 'rm -f "$temporary_generator"' EXIT

# English: Updating symbols is an explicit maintainer action and never a normal build phase.
# Español: La actualización de símbolos es una acción explícita del mantenedor y nunca una fase normal de build.
# 中文：更新符号是维护者主动执行的操作，绝不进入普通构建阶段。
swiftc "$generator_source" -o "$temporary_generator"
"$temporary_generator" generate "$catalog" "$generated"
printf 'Generated %s\n' "$generated"
