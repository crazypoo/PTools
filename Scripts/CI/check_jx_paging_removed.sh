#!/usr/bin/env bash
set -euo pipefail

# English: Keep the delivery source free of the absorbed JX paging dependencies.
# Español: Mantiene el código entregable libre de las dependencias JX absorbidas.
# 中文：确保交付源码不再直接依赖已吸收的 JX 分页组件。

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
matches="$(rg -n --hidden \
  -e 'JXSegmentedView|JXSegmented|JXPagingView|JXPaging|JXPager|JXSegmentedListContainer|JXPagingListContainer' \
  -e 'pujiaxin33/JXSegmentedView|pujiaxin33/JXPagingView' \
  -e 'import[[:space:]]+JXSegmentedView|import[[:space:]]+JXPagingView' \
  "$root_dir/Package.swift" \
  "$root_dir/PooTools.podspec" \
  "$root_dir/PooToolsSource" \
  "$root_dir/Sources" \
  "$root_dir/Tests" 2>/dev/null || true)"

if [[ -n "$matches" ]]; then
  printf '%s\n' "JX paging references remain in delivery source:" >&2
  printf '%s\n' "$matches" >&2
  exit 1
fi

printf '%s\n' "JX paging dependency guard passed for Package.swift, PooTools.podspec, PooToolsSource, Sources and Tests."
