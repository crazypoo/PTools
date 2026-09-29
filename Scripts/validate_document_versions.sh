#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

version="$(tr -d '[:space:]' < VERSION)"
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'FAIL [VERSION_SOURCE_INVALID]\nFile: VERSION\nExpected: semantic version X.Y.Z\nActual: %s\nRule: VERSION is the canonical development version\n' "$version" >&2
  exit 1
fi
contains_fixed() {
  local needle="$1"
  local file="$2"
  if command -v rg >/dev/null 2>&1; then
    rg -q --fixed-strings "$needle" "$file"
  else
    grep -Fq -- "$needle" "$file"
  fi
}

contains_regex() {
  local pattern="$1"
  local file="$2"
  if command -v rg >/dev/null 2>&1; then
    rg -q "$pattern" "$file"
  else
    grep -Eq -- "$pattern" "$file"
  fi
}

contains_fixed "version_path = File.join(__dir__, 'VERSION')" PooTools.podspec \
  || { printf 'FAIL [VERSION_PODSPEC_SOURCE]\nFile: PooTools.podspec\nExpected: VERSION-backed podspec\nActual: no VERSION source\nRule: podspec must read the canonical version source\n' >&2; exit 1; }
contains_fixed 's.version     = version' PooTools.podspec \
  || { printf 'FAIL [VERSION_PODSPEC_ASSIGNMENT]\nFile: PooTools.podspec\nExpected: s.version = version\nActual: assignment not found\nRule: podspec must use VERSION without a second product-version source\n' >&2; exit 1; }
pod_version="$(pod ipc spec PooTools.podspec | ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("version")')"
[[ "$pod_version" == "$version" ]] || {
  printf 'FAIL [VERSION_PODSPEC_MISMATCH]\nFile: PooTools.podspec\nExpected: %s\nActual: %s\nRule: CocoaPods must resolve the canonical VERSION\n' "$version" "$pod_version" >&2
  exit 1
}

# English: Ignore a future or malformed repository tag while validating the current development line.
# Español: Ignora una etiqueta futura o mal formada al validar la línea de desarrollo actual.
# 中文：校验当前开发线时忽略未来版本或仓库中的错误标签。
latest_tag="$(ruby Scripts/CI/version_facts.rb latest-formal-tag)"
[[ -n "$latest_tag" ]] || {
  printf 'FAIL [VERSION_NO_FORMAL_TAG]\nFile: .git/refs/tags\nExpected: at least one formal semantic tag\nActual: none\nRule: development validation needs a prior valid release tag\n' >&2
  exit 1
}

contains_fixed "PooTools/Core ($version)" Podfile.lock \
  || { printf 'FAIL [VERSION_LOCK_MISMATCH]\nFile: Podfile.lock\nExpected: PooTools/Core (%s)\nActual: missing or different resolved version\nRule: lockfile must follow VERSION\n' "$version" >&2; exit 1; }
contains_fixed "当前代码基线：\`$version\`" ROADMAP.md \
  || { printf 'FAIL [VERSION_ROADMAP_MISMATCH]\nFile: ROADMAP.md\nExpected: %s\nActual: current baseline is different\nRule: ROADMAP current development version must match VERSION\n' "$version" >&2; exit 1; }
contains_fixed "## $latest_tag" CHANGELOG.md \
  || { printf 'FAIL [VERSION_CHANGELOG_TAG_MISSING]\nFile: CHANGELOG.md\nExpected: ## %s\nActual: section not found\nRule: latest formal tag must have a changelog section\n' "$latest_tag" >&2; exit 1; }
contains_fixed "Unreleased" CHANGELOG.md \
  || { printf 'FAIL [VERSION_CHANGELOG_UNRELEASED_MISSING]\nFile: CHANGELOG.md\nExpected: Unreleased section\nActual: section not found\nRule: development changes must remain distinguishable from releases\n' >&2; exit 1; }
contains_fixed "$version" CHANGELOG.md \
  || { printf 'FAIL [VERSION_CHANGELOG_BASELINE_MISSING]\nFile: CHANGELOG.md\nExpected: %s\nActual: version not found\nRule: changelog must identify the current development baseline\n' "$version" >&2; exit 1; }

if contains_regex 'tag[[:space:]]*=>|pod[[:space:]]+[^#]*[,[:space:]]['"']5\.[0-9]+\.[0-9]+['"']' README.md; then
  printf 'FAIL: README.md contains a hardcoded CocoaPods tag or version\n' >&2
  exit 1
fi

if contains_regex 'Blocked candidate|Architecture slice|Permission boundary slice' CHANGELOG.md; then
  printf 'FAIL: CHANGELOG.md contains an internal milestone instead of a release entry\n' >&2
  exit 1
fi

if contains_regex '[0-9]+\.[0-9]+\.[0-9]+' docs/maintainers/RELEASE.md; then
  printf 'FAIL: RELEASE.md contains a hardcoded product version\n' >&2
  exit 1
fi

printf 'PASS: document versions aligned (development=%s, latest formal tag=%s)\n' "$version" "$latest_tag"
