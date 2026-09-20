#!/usr/bin/env bash

set -euo pipefail

# English: Compare the current public API against the latest formal release baseline.
# Español: Compara la API pública actual con la línea base de la última versión formal.
# 中文：将当前公开 API 与最新正式版本基线比较。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

latest_tag="$(git tag --list | ruby -e 'require "rubygems"; tags = STDIN.readlines(chomp: true).select { |tag| tag.match?(%r{\A\d+\.\d+\.\d+\z}) }; puts(tags.max_by { |tag| Gem::Version.new(tag) } || "")')"
[[ -n "$latest_tag" ]] || { printf 'FAIL: no semantic release tag is available\n' >&2; exit 1; }

baseline="api-baseline/$latest_tag/public_api.json"
[[ -f "$baseline" ]] || { printf 'FAIL: API baseline is missing: %s\n' "$baseline" >&2; exit 1; }
[[ -f report/current/public_api.json ]] || { printf 'FAIL: current API report is missing\n' >&2; exit 1; }

comparison="$(mktemp)"
trap 'rm -f "$comparison"' EXIT
if ruby Scripts/compare_public_api.rb "$baseline" report/current/public_api.json >"$comparison" 2>&1; then
  cat "$comparison"
else
  cat "$comparison"
  printf 'FAIL: public API removals or breaking signature changes detected\n' >&2
  exit 1
fi

printf 'PASS: public API baseline compared against %s\n' "$latest_tag"
