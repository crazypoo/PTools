#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# English: Keep the Duo gate portable on machines that do not install ripgrep.
# Español: Mantiene la puerta Duo portátil en máquinas sin ripgrep instalado.
# 中文：让 Duo 门禁在未安装 ripgrep 的机器上也能运行。
if command -v rg >/dev/null 2>&1; then
  has_fixed() { rg -q --fixed-strings "$1" "$2"; }
else
  has_fixed() { grep -Fq -- "$1" "$2"; }
fi

require_file() {
  local relative_path="$1"
  [[ -f "$repo_root/$relative_path" ]] || {
    printf 'FAIL: missing %s\n' "$relative_path" >&2
    exit 1
  }
}

require_fixed() {
  local needle="$1"
  local relative_path="$2"
  has_fixed "$needle" "$repo_root/$relative_path" || {
    printf 'FAIL: %s missing from %s\n' "$needle" "$relative_path" >&2
    exit 1
  }
}

for file in \
  PooToolsSource/Base/PTAdaptiveBarLayoutContext.swift \
  PooToolsSource/Base/PTAdaptiveBarLayoutResolver.swift \
  PooToolsSource/Base/PTAdaptiveBarCoordinator.swift \
  PooToolsSource/Base/PTAdaptiveBarPresentationPolicy.swift \
  PooToolsSource/Base/PTAdaptiveBarHostView.swift \
  PooToolsSource/Base/PTVerticalBarRailView.swift \
  PooToolsSource/Base/PTAdaptiveBarOverflowController.swift \
  PooToolsSource/Base/PTAdaptiveSystemBarBridge.swift \
  PooToolsSource/Base/PTAdaptiveBarDebugOverlay.swift \
  Tests/PToolsUIFoundationTests/PTAdaptiveBarLayoutTests.swift; do
  require_file "$file"
done

require_fixed "if #available(iOS 27.1, *)" PooToolsSource/Base/PTAdaptiveBarLayoutContext.swift
require_fixed "guard #available(iOS 27.1, *)" PooToolsSource/Base/PTAdaptiveSystemBarBridge.swift
require_fixed "navigation.duo-adaptive-bars" PooTools/PTDemoCatalog.swift
require_fixed "navigation.duo-adaptive-bars" Data/demo-registry.yml
require_fixed "testVerticalNavAndTabsNeverOverlap" Tests/PToolsUIFoundationTests/PTAdaptiveBarLayoutTests.swift
require_fixed "testMultiSceneStateDoesNotLeak" Tests/PToolsUIFoundationTests/PTAdaptiveBarLayoutTests.swift

# English: These shared bar files must use local geometry rather than screen or device heuristics.
# Español: Estos archivos compartidos deben usar geometría local y no heurísticas de pantalla o dispositivo.
# 中文：这些共享 Bar 文件必须使用局部几何，不能依赖全局屏幕或设备特征判断。
for file in \
  PooToolsSource/Base/PTBaseTabBarViewController.swift \
  PooToolsSource/Base/PTNavBar.swift \
  PooToolsSource/Base/PTBaseViewController+Navigation.swift \
  PooToolsSource/Base/PTTabBarView.swift; do
  for forbidden in "UIScreen.main" "kSCREEN_WIDTH" "isFaceIDCapable"; do
    if has_fixed "$forbidden" "$repo_root/$file"; then
      printf 'FAIL: forbidden %s in %s\n' "$forbidden" "$file" >&2
      exit 1
    fi
  done
done

printf 'PASS: iPhone Duo adaptive navigation and TabBar source contract\n'
