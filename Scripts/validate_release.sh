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
[[ -f MIGRATION_5X.md ]] \
  || { printf 'FAIL: MIGRATION_5X.md is missing\n' >&2; exit 1; }
rg -q --fixed-strings "6.0.0 删除评估条件" MIGRATION_5X.md \
  || { printf 'FAIL: MIGRATION_5X.md has no 6.0.0 removal criteria\n' >&2; exit 1; }
bash Scripts/report_duplicate_entries.sh >/dev/null

if [[ -f ROADMAP_5X.md ]]; then
  roadmap_section="$(awk -v version="$version" '
    $0 ~ "^## " version "([：: ].*)?$" { found = 1; next }
    found && /^## / { exit }
    found { print }
  ' ROADMAP_5X.md)"
  if [[ -z "$roadmap_section" ]]; then
    printf 'FAIL: ROADMAP_5X.md has no section for %s\n' "$version" >&2
    exit 1
  fi
  unresolved_tasks="$(printf '%s\n' "$roadmap_section" | rg '^[[:space:]]*-[[:space:]]*(🚧|⬜|⛔)' || true)"
  if [[ -n "$unresolved_tasks" ]]; then
    printf '%s\n' "$unresolved_tasks" >&2
    printf 'FAIL: ROADMAP_5X.md still contains unresolved tasks for %s\n' "$version" >&2
    exit 1
  fi
fi

printf 'Release metadata OK: %s\n' "$version"
