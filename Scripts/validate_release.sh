#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail() {
  local code="$1"
  local file="$2"
  local expected="$3"
  local actual="$4"
  local rule="$5"
  printf 'FAIL [%s]\nFile: %s\nExpected: %s\nActual: %s\nRule: %s\n' \
    "$code" "$file" "$expected" "$actual" "$rule" >&2
  exit 1
}

metadata_only=false
if [[ "$#" -gt 0 && "$1" == "--metadata-only" ]]; then
  metadata_only=true
fi

version=""
if [[ "$#" -gt 0 && "$1" != "--metadata-only" ]]; then
  version="$1"
fi
if [[ -z "$version" ]]; then
  version="$(tr -d '[:space:]' < VERSION)"
fi

[[ -n "$version" ]] || fail RELEASE_VERSION_MISSING VERSION 'semantic version' 'empty' 'release version must be readable'
[[ "$version" == "$(tr -d '[:space:]' < VERSION)" ]] \
  || fail RELEASE_VERSION_MISMATCH VERSION "$(tr -d '[:space:]' < VERSION)" "$version" 'release input must match VERSION'
rg -q --fixed-strings "version_path = File.join(__dir__, 'VERSION')" PooTools.podspec \
  || fail RELEASE_PODSPEC_SOURCE PooTools.podspec 'VERSION-backed podspec' 'no VERSION source' 'podspec must use the canonical version source'
pod_version="$(pod ipc spec PooTools.podspec | ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("version")')"
[[ "$pod_version" == "$version" ]] \
  || fail RELEASE_PODSPEC_MISMATCH PooTools.podspec "$version" "$pod_version" 'resolved podspec version must match VERSION'
rg -q --fixed-strings "PooTools/Core ($version)" Podfile.lock \
  || fail RELEASE_LOCK_MISMATCH Podfile.lock "PooTools/Core ($version)" 'missing or different resolved version' 'lockfile must match VERSION'
rg -q --fixed-strings "当前代码基线：\`$version\`" ROADMAP.md \
  || fail RELEASE_ROADMAP_MISMATCH ROADMAP.md "$version" 'current baseline is different' 'ROADMAP must match VERSION'

# English: A tag-triggered release must prove that its embedded VERSION is the tag name.
# Español: Un release activado por una etiqueta debe demostrar que su VERSION interno coincide con el nombre.
# 中文：由标签触发的发布必须证明标签内部 VERSION 与标签名一致。
if [[ "${GITHUB_REF_NAME:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  tag_version="$GITHUB_REF_NAME"
  [[ "$tag_version" == "$version" ]] \
    || fail RELEASE_TAG_VERSION_MISMATCH VERSION "$tag_version" "$version" 'tag name must match VERSION at the tagged commit'
  formal_tag="$(ruby Scripts/CI/version_facts.rb latest-formal-tag)"
  [[ "$formal_tag" == "$tag_version" ]] \
    || fail RELEASE_TAG_NOT_FORMAL .git/refs/tags "$tag_version" "${formal_tag:-none}" 'tag must satisfy the canonical formal-tag contract'
fi

if git show-ref --tags --verify --quiet "refs/tags/$version"; then
  rg -q --fixed-strings "## $version" CHANGELOG.md \
    || fail RELEASE_CHANGELOG_MISSING CHANGELOG.md "## $version" 'section not found' 'tagged releases must have a finalized changelog heading'
else
  rg -q --fixed-strings "Unreleased" CHANGELOG.md \
    || fail RELEASE_CHANGELOG_UNRELEASED_MISSING CHANGELOG.md 'Unreleased section' 'section not found' 'development releases must retain an Unreleased section'
fi

if [[ "$metadata_only" == true ]]; then
  # English: CI release metadata is intentionally separate from the full release rehearsal.
  # Español: Los metadatos de release de CI están separados intencionadamente del ensayo completo.
  # 中文：CI 的发布元数据门禁与完整发布演练明确分离。
  printf 'PASS [RELEASE_METADATA] development=%s\n' "$version"
  exit 0
fi

bash Scripts/validate_docs.sh
bash Scripts/CI/check_p0_platform_modules.sh
bash Scripts/CI/check_p1_advanced_modules.sh
bash Scripts/CI/check_p2_modern_modules.sh
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
