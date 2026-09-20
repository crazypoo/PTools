#!/usr/bin/env bash

set -euo pipefail

# English: Validate the Search container contract without requiring a runtime host.
# Español: Valida el contrato del contenedor Search sin exigir un host en ejecución.
# 中文：在不依赖运行时宿主的情况下校验 Search 容器契约。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

search_sources=(PooToolsSource/Search/*.swift)
for source in "${search_sources[@]}"; do
  [[ -f "$source" ]] || {
    printf 'FAIL: missing Search source: %s\n' "$source" >&2
    exit 1
  }
done

require_fragment() {
  local file="$1"
  local fragment="$2"
  local description="$3"
  if ! rg -q --fixed-strings "$fragment" "$file"; then
    printf 'FAIL: %s (%s)\n' "$description" "$file" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$description"
}

require_fragment "PooToolsSource/Search/PTSearchViewController.swift" "open class PTSearchViewController" "Search base controller"
require_fragment "PooToolsSource/Search/PTSearchViewController.swift" "PTSearchTaskCoordinator" "central task ownership"
require_fragment "PooToolsSource/Search/PTSearchViewController.swift" "PTSearchSnapshot" "request snapshot protection"
require_fragment "PooToolsSource/Search/PTSearchMode.swift" "case hybrid" "hybrid search mode"
require_fragment "PooToolsSource/Search/PTSearchPlacement.swift" "case navigationBarExpanded" "navigation placement"
require_fragment "PooToolsSource/Search/PTSearchHistoryProvider.swift" "PTUserDefaultsSearchHistoryProvider" "history provider"
require_fragment "PooToolsSource/Search/PTSearchPagination.swift" "canLoadMore" "pagination guard"
require_fragment "PooToolsSource/SearchBar/PTSearchBar.swift" "case glass" "glass search style"
require_fragment "Package.swift" ".library(name: \"PooToolsSearch\"" "SwiftPM Search product"
require_fragment "PooTools.podspec" "s.subspec 'Search'" "CocoaPods Search subspec"
require_fragment "PooTools.podspec" "subspec.dependency 'PooTools/Search'" "InputAll Search dependency"

if rg -n '@unchecked Sendable|nonisolated\(unsafe\)|try!|as!' PooToolsSource/Search PooToolsSource/SearchBar; then
  printf 'FAIL: Search sources introduce an unsafe declaration or forceful operation\n' >&2
  exit 1
fi

sdk_path="$(xcrun --sdk iphonesimulator --show-sdk-path)"
for source in "${search_sources[@]}" PooToolsSource/SearchBar/PTSearchBar.swift; do
  xcrun swiftc -frontend -parse -sdk "$sdk_path" -target arm64-apple-ios17.0-simulator "$source"
done

swift package dump-package >/dev/null
pod ipc spec PooTools.podspec >/dev/null
git diff --check

printf 'PASS: PTools 5.18.1 Search contract\n'
