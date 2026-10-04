#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# English: Keep the SplitView Demo route and adaptive behavior statically verifiable without opening a UI host.
# Español: Mantiene verificables estáticamente la ruta y el comportamiento adaptativo del Demo sin abrir un host UI.
# 中文：无需启动 UI 宿主，也能静态验证 SplitView Demo 路由和自适应行为。
catalog="PooTools/PTDemoCatalog.swift"
demo="PooTools/PTSplitViewDemo.swift"
configuration="PooToolsSource/SplitView/PTSplitConfiguration.swift"
controller="PooToolsSource/SplitView/PTSplitViewController.swift"

require_text() {
  local file="$1"
  local text="$2"
  local label="$3"
  if ! grep -F "$text" "$file" >/dev/null 2>&1; then
    printf 'FAIL [SPLITVIEW_DEMO_REGRESSION] missing %s in %s\n' "$label" "$file" >&2
    exit 1
  fi
}

require_text "$catalog" '"navigation.split-view"' 'SplitView descriptor'
require_text "$catalog" '.rootContainer' 'root-container presentation'
require_text "$catalog" '"iphone"' 'iPhone metadata tag'
require_text "$catalog" '"inspector"' 'Inspector metadata tag'
require_text "$catalog" 'case .rootContainer:' 'root-container coordinator branch'
require_text "$catalog" 'PT5_61SplitViewDemoViewController()' 'SplitView factory'
require_text "$configuration" 'case compact' 'compact column contract'
require_text "$controller" 'public var activeNavigationController' 'active navigation contract'
require_text "$controller" 'case .automatic:' 'automatic presentation contract'
require_text "$demo" 'PTRouter.generate' 'Router demo action'
require_text "$demo" 'Save State' 'state save control'
require_text "$demo" 'Restore State' 'state restore control'
require_text "$demo" 'Native Inspector' 'Inspector runtime state'
require_text "$demo" 'setCompact' 'compact demo setup'

if grep -n -E 'UIDevice\.current\.userInterfaceIdiom|UIScreen\.main\.bounds' \
    "$configuration" "$controller" "$demo" >/dev/null 2>&1; then
  printf 'FAIL [SPLITVIEW_DEMO_REGRESSION] device-idiom or fixed-screen branching remains\n' >&2
  exit 1
fi

printf 'PASS [SPLITVIEW_DEMO_REGRESSION] adaptive route, compact contract, state controls, and device-independent checks\n'
