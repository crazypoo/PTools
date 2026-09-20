#!/usr/bin/env bash

set -euo pipefail

# English: Verify that legacy spellings have a canonical migration path and compile aliases.
# Español: Verifica que cada nombre heredado tenga una ruta canónica y alias de compilación.
# 中文：校验历史拼写都有 canonical 迁移入口和编译宏别名。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

ruby - "Scripts/naming_debt_registry.json" <<'RUBY'
require "json"

path = ARGV.fetch(0)
data = JSON.parse(File.read(path))
entries = data.fetch("entries")
abort "FAIL: naming registry is empty" if entries.empty?

entries.each do |entry|
  %w[legacy canonical kind status remove_in].each do |key|
    value = entry[key].to_s.strip
    abort "FAIL: naming registry entry is missing #{key}: #{entry.inspect}" if value.empty?
  end
  abort "FAIL: naming registry removal must target 6.0.0: #{entry.inspect}" unless entry["remove_in"] == "6.0.0"
end

data.fetch("compile_flag_aliases").each do |entry|
  %w[legacy canonical].each do |key|
    abort "FAIL: compile flag alias is incomplete: #{entry.inspect}" if entry[key].to_s.strip.empty?
  end
end
RUBY

required_pairs=(
  'POOTOOLS_BIOID|POOTOOLS_BILOGYID'
  'POOTOOLS_ZIPARCHIVE|POOTOOLS_ZIPARCHINE'
  'POOTOOLS_MXMETRICMANAGERKIT|POOTOOLS_MXMERRICKITMANAGER'
)
for pair in "${required_pairs[@]}"; do
  canonical="${pair%%|*}"
  legacy="${pair##*|}"
  rg -q --fixed-strings "$canonical" PooTools.podspec || { printf 'FAIL: canonical flag missing from podspec: %s\n' "$canonical" >&2; exit 1; }
  rg -q --fixed-strings "$legacy" PooTools.podspec || { printf 'FAIL: legacy flag missing from podspec: %s\n' "$legacy" >&2; exit 1; }
done

rg -q --fixed-strings 'class func drop(' PooToolsSource/Category/UIViewController+PTEX.swift \
  || { printf 'FAIL: canonical drop API is missing\n' >&2; exit 1; }
rg -q --fixed-strings 'class func gobal_drop(' PooToolsSource/Category/UIViewController+PTEX.swift \
  || { printf 'FAIL: legacy gobal_drop wrapper is missing\n' >&2; exit 1; }
rg -q --fixed-strings 'typealias PTCoreUserDefaultsWrapper' PooToolsSource/Core/PTAppUserdefault.swift \
  || { printf 'FAIL: canonical user defaults typealias is missing\n' >&2; exit 1; }

printf 'PASS: naming debt registry and compile aliases\n'
