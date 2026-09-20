#!/usr/bin/env bash

set -euo pipefail

# English: Validate the 5.15 Media source contract and its canonical ownership boundaries.
# Español: Valida el contrato multimedia de 5.15 y sus límites de propiedad canónicos.
# 中文：校验 5.15 Media 源码契约和唯一实现边界。

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

errors=0

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    errors=$((errors + 1))
}

require_text() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    if ! rg -q -- "$pattern" "$file"; then
        fail "$description ($file)"
    fi
}

# English: Validate the media contract against the current development version instead of freezing an old release number.
# Español: Valida el contrato multimedia contra la versión de desarrollo actual, sin congelar un número antiguo.
# 中文：媒体契约校验当前开发版本，不再绑定已经完成的旧版本号。
current_version="$(sed -nE "s/^[[:space:]]*s\\.version[[:space:]]*=.*'([^']+)'.*/\\1/p" PooTools.podspec | head -n 1)"
[[ -n "$current_version" ]] || fail "podspec version is missing"
require_text PooToolsSource/PToolsMediaCore/PTMediaCoreContracts.swift "public struct PTMediaAsset" "typed media asset contract"
require_text PooToolsSource/PToolsMediaCore/PTMediaCoreContracts.swift "public enum PTMediaType" "typed media type contract"
require_text PooToolsSource/PToolsMediaCore/PTMediaCoreContracts.swift "public struct PTMediaMetadata" "typed media metadata contract"
require_text PooToolsSource/Core/PTImageDownsampler.swift "public enum PTImageDownsampler" "canonical image downsampler"
require_text PooToolsSource/Core/PTImageDownsampler.swift "CGImageSourceCreateThumbnailAtIndex" "ImageIO thumbnail decode"
require_text PooToolsSource/Core/PTMediaCache.swift "public actor PTMediaCache" "actor media cache"
require_text PooToolsSource/Core/PTMediaCache.swift "case videoThumbnail" "typed cache variants"
require_text PooToolsSource/Category/PTVideoThumbnailService.swift "public enum PTVideoThumbnailService" "canonical video thumbnail service"
require_text PooToolsSource/Core/PTMediaSaveService.swift "public enum PTMediaSaveResult" "typed media save result"
require_text PooToolsSource/PhotoPicker/PTMediaRequestCoordinator.swift "cancelAll" "PhotoKit request cancellation"
require_text PooToolsSource/ImagePicker/PTImagePicker.swift "public enum PTSystemMediaPicker" "system picker canonical entry"
require_text PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift "public func invalidate" "video editor lifecycle invalidation"
require_text PooToolsSource/Base/PTVideoCoverCache.swift "allowsResume: true" "resumable video cache download"
require_text PooToolsSource/Base/PTVideoCoverCache.swift "PTVideoFileDownloadCoordinator" "deduplicated video cache download"

if rg -n "try!|as!|nonisolated\(unsafe\)" \
    PooToolsSource/Core/PTImageDownsampler.swift \
    PooToolsSource/Core/PTMediaCache.swift \
    PooToolsSource/Core/PTMediaLifecycle.swift \
    PooToolsSource/PToolsMediaCore/PTMediaCoreContracts.swift; then
    fail "canonical Media files contain a forbidden unsafe construct"
fi

new_unsafe="$(git diff --unified=0 -- '*.swift' | rg '^\+[^+].*(nonisolated\(unsafe\)|try!|as!)' || true)"
if [[ -n "$new_unsafe" ]]; then
    printf '%s\n' "$new_unsafe" >&2
    fail "this change adds an unsafe construct"
fi

if ! git diff --check; then
    fail "git diff --check failed"
fi

if (( errors > 0 )); then
    printf '5.15 Media validation failed: %d issue(s)\n' "$errors" >&2
    exit 1
fi

printf '5.15 Media validation passed.\n'
