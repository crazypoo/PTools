#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

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
printf '%s\n' \
  'media save      | canonical: PTMediaSaveService | deprecated wrapper: PHPhotoLibrary/UIImage/PTMediaLibManager | semantic difference: VideoEditor resource replacement | pending: none' \
  'image request   | canonical: PTMediaLibManager.requestImage/requestImageData | deprecated wrapper: fetchImage/fetchOriginalImage/fetchOriginalImageData | semantic difference: PHAsset convenience adapter | pending: coordinator adoption in remaining cells' \
  'video request   | canonical: PTMediaLibManager.requestVideo | deprecated wrapper: fetchVideo | semantic difference: fetchAVAsset returns AVAsset for editor/player integration | pending: none' \
  'video thumbnail | canonical: PTVideoThumbnailService | deprecated wrapper: UIImage/PHAsset first-frame conveniences | semantic difference: PTVideoCoverCache adds disk cache | pending: none' \
  'image loading    | canonical: PTLoadImageFunction.loadImage(source:) | deprecated wrapper: dynamic Any adapters retained for source compatibility | semantic difference: UIView applies UI presentation configuration | pending: migrate new callers to PTImageSource' \
  'network         | canonical: Network internal executor | deprecated wrapper: requestApi/requestBodyAPI/fileUpload/imageUpload | semantic difference: callback/stream signatures | pending: typed progress stream adoption' \
  'empty state     | canonical: PTUnavailableManager.render | deprecated wrapper: UIView/UIViewController convenience entry points | semantic difference: none | pending: none' \
  'scene/window    | canonical: PTSceneContext | deprecated wrapper: legacy PTUtils window helpers | semantic difference: none | pending: migrate remaining callers' \
  'UI dispatch     | canonical: PTMainActorBridge | deprecated wrapper: PTGCDManager main-queue helpers | semantic difference: none | pending: remove nested dispatches'

printf '\n%s\n' 'Each group is explicitly classified as canonical, deprecated wrapper, semantic difference, or pending work.'
