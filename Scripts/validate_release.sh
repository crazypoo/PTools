#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

version="${1:-}"
if [[ -z "$version" ]]; then
  version="$(tr -d '[:space:]' < VERSION)"
fi

[[ -n "$version" ]] || { printf 'FAIL: unable to determine podspec version\n' >&2; exit 1; }
[[ "$version" == "$(tr -d '[:space:]' < VERSION)" ]] \
  || { printf 'FAIL: requested release version does not match VERSION: %s\n' "$version" >&2; exit 1; }
rg -q --fixed-strings "version_path = File.join(__dir__, 'VERSION')" PooTools.podspec \
  || { printf 'FAIL: podspec does not use VERSION as its source\n' >&2; exit 1; }
pod_version="$(pod ipc spec PooTools.podspec | ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("version")')"
[[ "$pod_version" == "$version" ]] \
  || { printf 'FAIL: resolved podspec version mismatch: %s != %s\n' "$pod_version" "$version" >&2; exit 1; }
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
bash Scripts/validate_logging_foundation_5_20.sh
bash Scripts/validate_logging_5_21.sh
bash Scripts/validate_logging_5_22.sh
bash Scripts/validate_519_package_tests_docs.sh
bash Scripts/report_duplicate_entries.sh >/dev/null
bash Scripts/validate_network_security.sh
bash Scripts/validate_socketrocket_removal_5_27.sh
bash Scripts/validate_515_media.sh
bash Scripts/validate_516_permission.sh
bash Scripts/validate_517_ui.sh
bash Scripts/validate_debug_instruments_5_18.sh
bash Scripts/validate_swifterswift_removal.sh
bash Scripts/validate_symbols_5_24.sh

printf 'Release metadata OK: development=%s\n' "$version"
