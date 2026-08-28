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
  'empty state      -> PooToolsSource/Base/PTUnavailableFunction.swift'

printf '\n%s\n' 'Review each group for a canonical implementation, a compatibility wrapper, or an intentional semantic difference.'
