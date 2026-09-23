#!/usr/bin/env bash

set -euo pipefail

# English: Guard the 5.25.0 removal of the third-party rich-text dependency.
# Español: Protege la eliminación de la dependencia externa de texto enriquecido en 5.25.0.
# 中文：守护 5.25.0 对第三方富文本依赖的移除结果。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

source_paths=(PooToolsSource PooTools)
source_forbidden="$(rg -n --hidden 'import AttributedString|ASAttributedString' "${source_paths[@]}" 2>/dev/null || true)"
if [[ -n "$source_forbidden" ]]; then
  printf '%s\n' "$source_forbidden" >&2
  fail 'third-party AttributedString references remain in production or package inputs'
fi

package_paths=(Package.swift Package.resolved PooTools.podspec Podfile.lock)
package_forbidden="$(rg -n --hidden --fixed-strings 'AttributedString' "${package_paths[@]}" 2>/dev/null || true)"
if [[ -n "$package_forbidden" ]]; then
  printf '%s\n' "$package_forbidden" >&2
  fail 'third-party AttributedString references remain in package inputs'
fi

rich_text_file='PooToolsSource/PToolsUIFoundation/PTRichText.swift'
[[ -f "$rich_text_file" ]] || fail "missing canonical rich-text implementation: $rich_text_file"
rg -q --fixed-strings 'public struct PTRichText' "$rich_text_file" \
  || fail 'PTRichText value model is missing'
rg -q --fixed-strings 'Foundation.AttributedString' "$rich_text_file" \
  || fail 'PTRichText is not backed by Foundation.AttributedString'

printf 'PASS: 5.25.0 AttributedString absorption and removal contract\n'
