#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

critical_files=(
  PooToolsSource/Router/PTRouter.swift
  PooToolsSource/Picker/PTBasePickerView.swift
  PooToolsSource/Share/PTActivityViewController.swift
  PooToolsSource/Category/UIApplication+PTEX.swift
  PooToolsSource/Contact/PTContact.swift
  PooToolsSource/Debug/PTDebugFunction.swift
  PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift
  PooToolsSource/Animation/PTAnimationFunction.swift
  PooToolsSource/PhotoPicker
  PooToolsSource/VideoEditor
)

if rg -n 'try!|as!' "${critical_files[@]}"; then
  printf 'FAIL: forceful error/type casts remain in production Swift sources\n' >&2
  exit 1
fi

if rg -n --glob '*.swift' 'nonisolated\(unsafe\)' PooToolsSource/CheckUpdate PooToolsSource/Contact PooToolsSource/NFC PooToolsSource/NetWork PooToolsSource/PhotoPicker PooToolsSource/VideoEditor; then
  printf 'FAIL: business-level nonisolated(unsafe) remains in P0 modules\n' >&2
  exit 1
fi

new_unchecked="$(git diff --unified=0 -- '*.swift' | rg '^\+[^+].*@unchecked Sendable' | rg -v 'PTSystemPixelBufferBox|PTSystemAVAssetBox' || true)"
if [[ -n "$new_unchecked" ]]; then
  printf '%s\n' "$new_unchecked" >&2
  printf 'FAIL: this change introduces a new @unchecked Sendable declaration\n' >&2
  exit 1
fi

printf 'PASS: Swift 6 safety scans\n'
