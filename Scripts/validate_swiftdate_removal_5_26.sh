#!/usr/bin/env bash

set -euo pipefail

# English: Keep SwiftDate out of shipped source, package manifests, and lockfiles after 5.26.0.
# Español: Mantiene SwiftDate fuera del código entregado, manifiestos y lockfiles después de 5.26.0.
# 中文：5.26.0 之后确保交付源码、包清单和锁文件不再包含 SwiftDate。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

implementation_paths=(
  PooToolsSource
  Tests
  Package.swift
  Package.resolved
  PooTools.podspec
  Podfile.lock
)

legacy_hits="$(rg -n --hidden --glob '!Pods/**' --glob '!*.md' \
  'SwiftDate|DateInRegion|\bRegion\b|\bZones\b|\bLocales\b|\.toFormat\(|\.toDate\(|dateAtEndOf|dateAtStartOf|convertTo\(region:|\.int\.seconds' \
  "${implementation_paths[@]}" || true)"
if [[ -n "$legacy_hits" ]]; then
  printf '%s\n' "$legacy_hits" >&2
  printf 'FAIL: SwiftDate runtime or dependency references remain after 5.26.0\n' >&2
  exit 1
fi

if rg -n --fixed-strings 'jx_formatter' PooToolsSource Tests; then
  printf 'FAIL: global mutable jx_formatter remains in shipped Swift sources\n' >&2
  exit 1
fi

required_paths=(
  PooToolsSource/PToolsDate/PTDateContext.swift
  PooToolsSource/PToolsDate/PTZonedDate.swift
  PooToolsSource/PToolsDate/PTDateParser.swift
  docs/audits/SWIFTDATE_USAGE_AUDIT.md
  docs/migrations/SWIFTDATE_TO_PTOOLSDATE.md
  docs/architecture/PTOOLS_DATE_GUIDE.md
  docs/testing/DATE_TIMEZONE_DST_TEST_MATRIX.md
)
for path in "${required_paths[@]}"; do
  [[ -f "$path" ]] || {
    printf 'FAIL: missing 5.26 date migration artifact: %s\n' "$path" >&2
    exit 1
  }
done

printf 'PASS: 5.26.0 SwiftDate removal and PToolsDate contract\n'
