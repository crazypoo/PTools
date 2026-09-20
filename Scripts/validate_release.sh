#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

version="${1:-}"
if [[ -z "$version" ]]; then
  version="$(sed -nE "s/^[[:space:]]*s\.version[[:space:]]*=.*'([^']+)'.*/\1/p" PooTools.podspec | head -n 1)"
fi

[[ -n "$version" ]] || { printf 'FAIL: unable to determine podspec version\n' >&2; exit 1; }
rg -q --fixed-strings "s.version     = '$version'" PooTools.podspec \
  || { printf 'FAIL: podspec version mismatch: %s\n' "$version" >&2; exit 1; }
rg -q --fixed-strings "PooTools/Core ($version)" Podfile.lock \
  || { printf 'FAIL: Podfile.lock is not synchronized to %s\n' "$version" >&2; exit 1; }
rg -q --fixed-strings "当前代码基线：\`$version\`" ROADMAP.md \
  || { printf 'FAIL: ROADMAP.md has no current baseline for %s\n' "$version" >&2; exit 1; }

if git show-ref --tags --verify --quiet "refs/tags/$version"; then
  rg -q --fixed-strings "## $version" CHANGELOG.md \
    || { printf 'FAIL: CHANGELOG.md has no release heading for tagged version %s\n' "$version" >&2; exit 1; }
else
  rg -q --fixed-strings "Unreleased" CHANGELOG.md \
    || { printf 'FAIL: CHANGELOG.md has no Unreleased section for development version %s\n' "$version" >&2; exit 1; }
fi

bash Scripts/validate_docs.sh
bash Scripts/validate_document_versions.sh
bash Scripts/report_duplicate_entries.sh >/dev/null
bash Scripts/validate_network_security.sh
bash Scripts/validate_515_media.sh
bash Scripts/validate_516_permission.sh
bash Scripts/validate_517_ui.sh

printf 'Release metadata OK: development=%s\n' "$version"
