#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

version="${1:-}"
if [[ -z "$version" ]]; then
  version="$(sed -n "s/^[[:space:]]*s.version[[:space:]]*= *'\([^']*\)'.*/\1/p" PooTools.podspec | head -1)"
fi

[[ -n "$version" ]] || { printf 'FAIL: unable to determine version\n' >&2; exit 1; }
rg -q --fixed-strings "s.version     = '$version'" PooTools.podspec \
  || { printf 'FAIL: podspec version mismatch: %s\n' "$version" >&2; exit 1; }
rg -q --fixed-strings "## $version -" CHANGELOG.md \
  || { printf 'FAIL: CHANGELOG.md has no release heading for %s\n' "$version" >&2; exit 1; }
rg -q --fixed-strings "tag => '$version'" README.md \
  || { printf 'FAIL: README.md has no CocoaPods example for %s\n' "$version" >&2; exit 1; }
rg -q --fixed-strings "发布目标为 \`$version\`" RELEASE.md \
  || { printf 'FAIL: RELEASE.md target version mismatch: %s\n' "$version" >&2; exit 1; }
rg -q --fixed-strings "PooTools/Core ($version)" Podfile.lock \
  || { printf 'FAIL: Podfile.lock is not synchronized to %s\n' "$version" >&2; exit 1; }

printf 'Release metadata OK: %s\n' "$version"
