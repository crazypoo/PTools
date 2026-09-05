#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# English: Every repeated entry must name its canonical implementation and its migration state.
# Español: Cada entrada repetida debe indicar su implementación canónica y su estado de migración.
# 中文：每组重复入口都必须声明唯一实现和迁移状态。
classification_rows=(
  'media save|PTMediaSaveService|PHPhotoLibrary/UIImage/PTMediaLibManager|VideoEditor resource replacement|none|6.0.0'
  'image request|PTMediaLibManager.requestImage/requestImageData|fetchImage/fetchOriginalImage/fetchOriginalImageData|PHAsset convenience adapter|coordinator adoption in remaining cells|6.0.0'
  'video request|PTMediaLibManager.requestVideo|fetchVideo|fetchAVAsset returns AVAsset for editor/player integration|none|6.0.0'
  'video thumbnail|PTVideoThumbnailService|UIImage/PHAsset first-frame conveniences|PTVideoCoverCache adds disk cache|none|6.0.0'
  'image loading|PTLoadImageFunction.loadImage(source:)|dynamic Any adapters retained for source compatibility|UIView applies UI presentation configuration|migrate new callers to PTImageSource|6.0.0'
  'network|Network internal executor|requestApi/requestBodyAPI/fileUpload/imageUpload|callback/stream signatures|typed progress stream adoption|6.0.0'
  'empty state|PTUnavailableManager.render|UIView/UIViewController convenience entry points|none|none|6.0.0'
  'scene/window|PTSceneContext|legacy PTUtils window helpers|none|remaining callers outside 5.2 Core scope|6.0.0'
  'UI dispatch|PTMainActorBridge|PTGCDManager main-queue helpers|none|remaining legacy callers outside 5.2 Core scope|6.0.0'
  'scroll banner|PTBannerView|PTCycleScrollView|legacy properties and factory methods|none|6.0.0'
  'page control|PTBasePageControl|individual visual PageControl subclasses|visual implementations differ|none|6.0.0'
  'picker strategy|PTSystemMediaPicker|deprecated PTImagePicker convenience wrappers|PhotoPicker remains the advanced PhotoKit browser|legacy generic Controller and custom configuration|6.0.0'
  'wheel picker|PTBasePickerView configure/show(in:)|legacy show wrappers|String/Date/Tree keep mode-specific state|migrate new embedded callers to typed configure APIs|6.0.0'
)

valid_groups=(
  'media save' 'image request' 'video request' 'video thumbnail' 'image loading'
  'network' 'empty state' 'scene/window' 'UI dispatch' 'scroll banner' 'page control' 'picker strategy' 'wheel picker'
)

for row in "${classification_rows[@]}"; do
  IFS='|' read -r group canonical wrapper semantic_difference pending removal_gate <<< "$row"
  if [[ -z "$group" || -z "$canonical" || -z "$wrapper" || -z "$semantic_difference" || -z "$pending" || -z "$removal_gate" ]]; then
    printf 'FAIL: duplicate-entry classification has an empty field: %s\n' "$row" >&2
    exit 1
  fi
  if [[ ! " ${valid_groups[*]} " == *" $group "* ]]; then
    printf 'FAIL: duplicate-entry classification has an unknown group: %s\n' "$group" >&2
    exit 1
  fi
  if [[ "$removal_gate" != "6.0.0" ]]; then
    printf 'FAIL: duplicate-entry classification must define the 6.0.0 removal gate: %s\n' "$row" >&2
    exit 1
  fi
done

printf '%s\n' 'PTools duplicate-entry inventory (intentional wrappers are expected):'

report_group() {
  local title="$1"
  shift
  printf '\n[%s]\n' "$title"
  for pattern in "$@"; do
    rg -n --glob '*.swift' "$pattern" PooToolsSource || true
  done
}

report_group 'media save' \
  'func saveVideoToAlbum' \
  'func (saveImageToAlbum|saveImageUrlToAlbum|savePhotosImageToAlbum)' \
  'func saveMediaToAlbum' \
  'func saveToAlbumAsync'

report_group 'media request' \
  'func (requestImage|fetchImage)' \
  'func (requestImageData|fetchOriginalImageData)' \
  'func (requestVideo|fetchVideo|fetchVideoFirstFrame)'

report_group 'image loading' \
  'func loadImage\(contentData' \
  'func pt_loadCoreImage'

report_group 'network request' \
  'func request(Codable)?Api' \
  'func request(Codable)?BodyAPI' \
  'func (file|image)(Codable)?Upload' \
  'func download'

report_group 'empty state' \
  'func (showEmptyView|showEmptyLoadingView|hideUnavailableView|render)'

report_group 'scroll banner' \
  'class (PTBannerView|PTCycleScrollView)' \
  'func (scrollToPage|scrollByDirection|automaticScroll|scollToIndex)'

report_group 'page control' \
  'class (PTBasePageControl|PTFilledPageControl|PTPillPageControl|PTSnakePageControl|PTScrollingPageControl|PTImagePageControl)' \
  'func (setProgress|setCurrentPage|update|addPageControlAction)'

report_group 'picker strategy' \
  'class (Controller|PTSystemMediaPickerCoordinator)' \
  'func (openAlbum|photograph|pick|capture|openCamera)'

report_group 'wheel picker' \
  'class (PTBasePickerView|PTStringPickerView|PTDatePickerView|PTTreePickerView)' \
  'func (configure|show|selectRow)'

printf '\n%s\n' 'Canonical implementation map:'
printf '%s\n' \
  'media save      -> PooToolsSource/Core/PTMediaSaveService.swift' \
  'image requests  -> PooToolsSource/PhotoPicker/PTMediaRequestCoordinator.swift + PTMediaLibManager.swift' \
  'video thumbnails -> PooToolsSource/Category/PTVideoThumbnailService.swift' \
  'image loading    -> PooToolsSource/Core/PTLoadImageFunction.swift' \
  'network pipeline -> PooToolsSource/NetWork/Network.swift' \
  'empty state      -> PooToolsSource/Base/PTUnavailableFunction.swift' \
  'scene/window     -> PooToolsSource/Core/PTUtils+SceneConcurrency.swift (PTSceneContext)' \
  'UI dispatch      -> PooToolsSource/Core/PTUtils+SceneConcurrency.swift (PTMainActorBridge)' \
  'scroll banner    -> PooToolsSource/ScrollBanner/PTBannerView.swift' \
  'page control     -> PooToolsSource/PageControl/PTPageControllable.swift + concrete controls' \
  'picker strategy  -> PooToolsSource/ImagePicker/PTImagePicker.swift (PTSystemMediaPicker)' \
  'wheel picker     -> PooToolsSource/Picker/PTBasePickerView.swift (typed configure + explicit host)' \
  'background work  -> PooToolsSource/Core/PTGCDManager.swift'

printf '\n%s\n' 'Split-file ownership map:'
printf '%s\n' \
  'PTBaseViewController navigation | canonical: PooToolsSource/Base/PTBaseViewController+Navigation.swift | status: complete' \
  'PTBaseTabBarController support | canonical: PooToolsSource/Base/PTBaseTabBarViewController+Support.swift | status: complete' \
  'PTBaseTabBarController system tabs | canonical: PooToolsSource/Base/PTBaseTabBarViewController+SystemTabs.swift | status: complete' \
  'PTCollectionView type surface | canonical: PooToolsSource/Base/PTCollectionViewTypes.swift | status: complete' \
  'UIView constraints | canonical: PooToolsSource/Category/UIView+PTEX+Constraints.swift | status: complete' \
  'UIImage GIF | canonical: PooToolsSource/Category/UIImage+PTEX+GIF.swift | status: complete' \
  'String crypto | canonical: PooToolsSource/Category/String+PTEX+Crypto.swift | status: complete'

printf '\n%s\n' 'Status classification:'
for row in "${classification_rows[@]}"; do
  IFS='|' read -r group canonical wrapper semantic_difference pending removal_gate <<< "$row"
  printf '%-16s | canonical: %s | deprecated wrapper: %s | semantic difference: %s | pending: %s | removal gate: %s\n' \
    "$group" "$canonical" "$wrapper" "$semantic_difference" "$pending" "$removal_gate"
done

printf '\n%s\n' 'Each group is explicitly classified as canonical, deprecated wrapper, semantic difference, or pending work.'
