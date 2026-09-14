#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

version="$(sed -nE "s/^[[:space:]]*s\.version[[:space:]]*=.*'([^']+)'.*/\1/p" PooTools.podspec | head -n 1)"
[[ -n "$version" ]] || { printf 'FAIL: PooTools.podspec version is missing\n' >&2; exit 1; }

latest_tag="$(git tag --list | ruby -e 'require "rubygems"; tags = STDIN.readlines(chomp: true).select { |tag| tag.match?("\\A\\d+\\.\\d+\\.\\d+\\z") }; puts(tags.max_by { |tag| Gem::Version.new(tag) } || "")')"
[[ -n "$latest_tag" ]] || { printf 'FAIL: no semantic release tag is available\n' >&2; exit 1; }

rg -q --fixed-strings "PooTools/Core ($version)" Podfile.lock \
  || { printf 'FAIL: Podfile.lock does not contain PooTools/Core (%s)\n' "$version" >&2; exit 1; }
rg -q --fixed-strings "当前代码基线：\`$version\`" ROADMAP.md \
  || { printf 'FAIL: ROADMAP.md baseline is not aligned to %s\n' "$version" >&2; exit 1; }
rg -q --fixed-strings "## $latest_tag" CHANGELOG.md \
  || { printf 'FAIL: CHANGELOG.md has no section for latest formal tag %s\n' "$latest_tag" >&2; exit 1; }
rg -q --fixed-strings "Unreleased" CHANGELOG.md \
  || { printf 'FAIL: CHANGELOG.md must retain one Unreleased section\n' >&2; exit 1; }
rg -q --fixed-strings "$version" CHANGELOG.md \
  || { printf 'FAIL: CHANGELOG.md does not identify the current development baseline %s\n' "$version" >&2; exit 1; }

if rg -n 'tag[[:space:]]*=>|pod[[:space:]]+[^#]*[,[:space:]]['"']5\.[0-9]+\.[0-9]+['"']' README.md >/dev/null; then
  printf 'FAIL: README.md contains a hardcoded CocoaPods tag or version\n' >&2
  exit 1
fi

if rg -n 'Blocked candidate|Architecture slice|Permission boundary slice' CHANGELOG.md >/dev/null; then
  printf 'FAIL: CHANGELOG.md contains an internal milestone instead of a release entry\n' >&2
  exit 1
fi

if rg -n '[0-9]+\.[0-9]+\.[0-9]+' docs/maintainers/RELEASE.md >/dev/null; then
  printf 'FAIL: RELEASE.md contains a hardcoded product version\n' >&2
  exit 1
fi

printf 'PASS: document versions aligned (development=%s, latest formal tag=%s)\n' "$version" "$latest_tag"
