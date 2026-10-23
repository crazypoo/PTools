#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# English: Generate the full UIKit inventory before validating the shared Duo contract.
# Español: Genera el inventario UIKit completo antes de validar el contrato Duo compartido.
# 中文：在验证共享 Duo 契约前，先生成完整 UIKit 清单。
python3 "$repo_root/Scripts/audit_duo_uikit_coverage.py" "$repo_root" --strict
python3 "$repo_root/Scripts/audit_duo_uikit_coverage.py" "$repo_root" --check --strict

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

for report in \
  report/current/duo_uikit_inventory.csv \
  report/current/duo_global_geometry_hits.json \
  report/current/duo_coverage.md \
  report/current/duo_findings_closed.md \
  report/current/duo_test_matrix.md; do
  require_file "$report"
done

for file in \
  PooToolsSource/Category/UIImageView+PTEX.swift \
  PooToolsSource/Category/UIImage+PTEX.swift \
  PooToolsSource/Base/PTBaseWebViewController.swift \
  PooToolsSource/PhotoPicker/PTMediaLibViewController.swift \
  PooToolsSource/PhotoPicker/PTMediaLibAlbumListViewController.swift \
  PooToolsSource/MediaViewer/PTMediaBrowserCell.swift \
  PooToolsSource/Inspector/ElementInspectorConfiguration.swift \
  PooToolsSource/Inspector/ViewHierarchyRoot.swift \
  PooToolsSource/QRCodeScan/PTScanQRController.swift \
  PooToolsSource/DebugNetwork/PTNetworkWatcherViewController.swift \
  PooToolsSource/DebugNetwork/PTNetworkHelper.swift \
  PooToolsSource/WhereIsMyEye/PTEyeTrackingDataManager.swift \
  PooToolsSource/WhereIsMyEye/PTEyeTrackingManager.swift \
  PooToolsSource/WhereIsMyEye/PTEyeTrackingTestUtility.swift; do
  for forbidden in "UIScreen.main" "kSCREEN_WIDTH" "kSCREEN_HEIGHT" "kNavBarHeight_Total" "statusBarHeight()" "UIDevice.current.orientation" ".convert(.*to: nil"; do
    if [[ "$forbidden" == ".convert(.*to: nil" ]]; then
      if grep -Eq '\.convert\([^\n]*to:[[:space:]]*nil' "$repo_root/$file"; then
        printf 'FAIL: forbidden convert-to-nil in %s\n' "$file" >&2
        exit 1
      fi
    elif has_fixed "$forbidden" "$repo_root/$file"; then
      printf 'FAIL: forbidden %s in %s\n' "$forbidden" "$file" >&2
      exit 1
    fi
  done
done

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
  PooToolsSource/Base/PTAdaptiveVisibleRegionResolver.swift \
  Tests/PToolsUIFoundationTests/PTAdaptiveBarLayoutTests.swift; do
  require_file "$file"
done

require_fixed "if #available(iOS 27.1, *)" PooToolsSource/Base/PTAdaptiveBarLayoutContext.swift
require_fixed "guard #available(iOS 27.1, *)" PooToolsSource/Base/PTAdaptiveSystemBarBridge.swift
require_fixed "navigation.duo-adaptive-bars" PooTools/PTDemoCatalog.swift
require_fixed "navigation.duo-adaptive-bars" Data/demo-registry.yml
for demo_id in \
  "duo.photo-picker-grid" \
  "duo.image-editor-controls" \
  "duo.video-editor-controls" \
  "duo.media-viewer-paging" \
  "duo.media-viewer-bottom" \
  "duo.message-kit-chat" \
  "duo.large-title-navigation" \
  "duo.tab-accessory-search" \
  "duo.paging-segmented" \
  "duo.unified-collision-stress"; do
  require_fixed "$demo_id" PooTools/PTDemoCatalog.swift
  require_fixed "$demo_id" Data/demo-registry.yml
done
require_fixed "testVerticalNavAndTabsNeverOverlap" Tests/PToolsUIFoundationTests/PTAdaptiveBarLayoutTests.swift
require_fixed "testMultiSceneStateDoesNotLeak" Tests/PToolsUIFoundationTests/PTAdaptiveBarLayoutTests.swift
for test_name in \
  "testVisiblePanesExcludeEveryActiveReservedRegion" \
  "testNoInteractiveFrameOverlapsReservedRegion" \
  "testVerticalRailNavTabAccessoryOverflowNoCollision" \
  "testLayoutSignatureChangesOnlyWithGeometry" \
  "testNoInfiniteLayoutInvalidationOnResize" \
  "testPhotoGridItemFramesStayWithinUsablePanes" \
  "testPagingFourMediaAfterResizePreservesItemIdentity" \
  "testEditorCropCoordinatesAfterResize" \
  "testKeyboardFormFooterAndPopoverAvoidOcclusion" \
  "testSplitViewCollapseExpandRetainsSelection" \
  "testRTLVerticalEdgeFollowsSystem" \
  "testMultiSceneDoesNotReuseStaleGeometry"; do
  require_fixed "$test_name" Tests/PToolsUIFoundationTests/PTAdaptiveBarLayoutTests.swift
done
require_fixed "availablePanes" PooToolsSource/Base/PTAdaptiveVisibleRegionResolver.swift

# English: These shared bar files must use local geometry rather than screen or device heuristics.
# Español: Estos archivos compartidos deben usar geometría local y no heurísticas de pantalla o dispositivo.
# 中文：这些共享 Bar 文件必须使用局部几何，不能依赖全局屏幕或设备特征判断。
for file in \
  PooToolsSource/Base/PTBaseTabBarViewController.swift \
  PooToolsSource/Base/PTNavBar.swift \
  PooToolsSource/Base/PTBaseViewController+Navigation.swift \
  PooToolsSource/Base/PTTabBarView.swift \
  PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift \
  PooToolsSource/Guide/PTGuidePageHUD.swift \
  PooToolsSource/Base/PTCollectionView.swift \
  PooToolsSource/Base/PTCollectionIndexCoordinator.swift \
  PooToolsSource/Share/PTActivityViewController.swift \
  PooToolsSource/MediaViewer/PTMediaBrowserController.swift \
  PooToolsSource/MediaViewer/PTMediaBrowserBottom.swift \
  PooToolsSource/MessageKit/PTChatConfig.swift \
  PooToolsSource/MessageKit/PTChatView.swift \
  PooToolsSource/MessageKit/PTChatTextCell.swift \
  PooToolsSource/PhotoPicker/PTMediaLibViewController.swift \
  PooToolsSource/PhotoPicker/PTMediaLibCell.swift \
  PooToolsSource/ImageEditor/PTEditImageViewController.swift \
  PooToolsSource/ImageEditor/PTCutViewController.swift \
  PooToolsSource/VideoEditor/PTVideoEditorToolsCropControl.swift \
  PooToolsSource/VideoEditor/PTVideoEditorBaseFloatingViewController.swift \
  PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift \
  PooToolsSource/MediaViewer/PTMediaBrowserCell.swift \
  PooToolsSource/SegmentControl/PTPaging.swift; do
  for forbidden in "UIScreen.main" "kSCREEN_WIDTH" "isFaceIDCapable" "UIDevice.current.orientation"; do
    if has_fixed "$forbidden" "$repo_root/$file"; then
      printf 'FAIL: forbidden %s in %s\n' "$forbidden" "$file" >&2
      exit 1
    fi
  done
done

printf 'PASS: iPhone Duo adaptive navigation and TabBar source contract\n'
