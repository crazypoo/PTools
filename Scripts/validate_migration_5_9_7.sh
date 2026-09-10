#!/usr/bin/env bash

set -euo pipefail

# English: Validate the 5.9.7 documentation, Example index, and migration baseline.
# Español: Valida la documentación, el índice de Example y la línea base de migración de 5.9.7.
# 中文：校验 5.9.7 的文档、Example 索引和迁移基线。
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

version="$(sed -nE "s/^[[:space:]]*s\.version[[:space:]]*=.*'([^']+)'.*/\1/p" PooTools.podspec | head -n 1)"
[[ -n "$version" ]] || fail "PooTools.podspec version is missing"

for file in README.md DEPENDENCIES.md MIGRATION_6.md EXAMPLE_MODULES_5_9.md RELEASE.md CHANGELOG.md PTools_PRE_6_ROADMAP.md; do
    [[ -f "$file" ]] || fail "required migration document is missing: $file"
done

rg -q --fixed-strings "tag => '$version'" README.md || fail "README does not use the current Podspec tag"
rg -q --fixed-strings "当前仓库基线：\`$version\`" DEPENDENCIES.md || fail "dependency baseline is stale"
rg -q --fixed-strings "当前源码基线和最新标签为 \`$version\`" MIGRATION_6.md || fail "migration baseline is stale"
rg -q --fixed-strings "PooTools/Core ($version)" Podfile.lock || fail "Podfile.lock does not contain the current PooTools version"
rg -q --fixed-strings "EXAMPLE_MODULES_5_9.md" README.md || fail "README does not link the Example module index"
rg -q --fixed-strings "EXAMPLE_MODULES_5_9.md" MIGRATION_6.md || fail "MIGRATION_6.md does not link the Example module index"

for page in Core Navigation TabBar Collection Network Media Picker Alert Permission Theme Debug Accessibility; do
    rg -q --fixed-strings "| $page |" EXAMPLE_MODULES_5_9.md || fail "Example page is missing: $page"
done

for source in \
    PooTools/SceneDelegate.swift \
    PooTools/PTTestTabbarViewController.swift \
    PooTools/PTFuncNameViewController.swift \
    PooTools/PTFuncDetailViewController.swift \
    PooTools/PTSideController.swift; do
    [[ -f "$source" ]] || fail "Example source entry is missing: $source"
done

for task in \
    "[x] DOC-597-01 README module sets" \
    "[x] DOC-597-02 Dependency docs" \
    "[x] DOC-597-03 Example pages index and module regression guide" \
    "[x] DOC-597-04 MIGRATION_6"; do
    rg -q --fixed-strings "$task" PTools_PRE_6_ROADMAP.md || fail "roadmap task is not complete: $task"
done

printf 'PASS: 5.9.7 documentation, Example, and migration contracts (%s)\n' "$version"
