#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

failures=()
ui_files=(
  PooToolsSource/Base/PTNavigationBarManager.swift
  PooToolsSource/Base/PTBaseTabBarViewController.swift
  PooToolsSource/Base/PTTabBarView.swift
  PooToolsSource/Base/PTCollectionView.swift
  PooToolsSource/Base/PTCollectionViewTypes.swift
  PooToolsSource/Base/PTBaseCellOption.swift
  PooToolsSource/Category/UICollectionView+PTEX.swift
  PooToolsSource/PToolsUIFoundation/PTUIFoundationSnapKitEX.swift
)

# English: UI foundation code must resolve windows through the owning view or scene context.
# Español: El código UI foundation debe resolver ventanas mediante la vista o el contexto de escena propietario.
# 中文：UIFoundation 代码必须通过所属视图或场景上下文解析窗口。
global_window_lookup="$(rg -n 'UIApplication\.shared\.(windows|keyWindow|connectedScenes)|AppWindows' "${ui_files[@]}" \
  | rg -v ':[[:space:]]*///|:[[:space:]]*//' || true)"
if [[ -n "$global_window_lookup" ]]; then
  printf '%s\n' "$global_window_lookup"
  failures+=("UIFoundation/navigation/list files contain a global window lookup")
fi

required_fragments=(
  "private func apply(item: PTNavBarItem,"
  "public func restoreVisibilityState()"
  "func reloadData()"
  "func refreshLocalization()"
  "public final class PTReusableTaskBag"
  "case snapshotApplyInProgress"
  "public enum PTUIFoundationContext"
)

for fragment in "${required_fragments[@]}"; do
  if ! rg -q --fixed-strings "$fragment" "${ui_files[@]}"; then
    failures+=("missing 5.13 UI contract: $fragment")
  fi
done

if rg -n 'cellRowCount: viewConfig\.rowCount|rowCount: config\.rowCount' PooToolsSource/Base/PTCollectionView.swift; then
  failures+=("collection layouts do not normalize rowCount")
fi

if ((${#failures[@]} > 0)); then
  printf 'FAIL: 5.13 UIFoundation / Navigation / Tabbar / Collection contract\n' >&2
  printf ' - %s\n' "${failures[@]}" >&2
  exit 1
fi

printf 'PASS: 5.13 UIFoundation / Navigation / Tabbar / Collection contract\n'
