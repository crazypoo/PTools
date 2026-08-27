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
  PooToolsSource/QRCodeScan/PTScanQRController.swift
  PooToolsSource/Category/UIScreen+PTEX.swift
  PooToolsSource/Category/UIViewController+Swizzled.swift
  PooToolsSource/LocalConsole/LocalConsole.swift
  PooToolsSource/PhotoPicker
  PooToolsSource/VideoEditor
)

if rg -n 'try!|as!' "${critical_files[@]}"; then
  printf 'FAIL: forceful error/type casts remain in production Swift sources\n' >&2
  exit 1
fi

bash Scripts/report_duplicate_entries.sh >/dev/null
bash Scripts/validate_localizations.sh

if rg -n --glob '*.swift' 'nonisolated\(unsafe\)' PooToolsSource/CheckUpdate PooToolsSource/Contact PooToolsSource/NFC PooToolsSource/NetWork PooToolsSource/PhotoPicker PooToolsSource/VideoEditor; then
  printf 'FAIL: business-level nonisolated(unsafe) remains in P0 modules\n' >&2
  exit 1
fi

allowlist="Scripts/unchecked_sendable_allowlist.txt"
current_unchecked="$(rg -l --glob '*.swift' '@unchecked Sendable' PooToolsSource | sort)"
allowed_unchecked="$(rg -v '^\s*(#|$)' "$allowlist" | sort)"
unlisted_unchecked="$(comm -23 <(printf '%s\n' "$current_unchecked") <(printf '%s\n' "$allowed_unchecked") || true)"
if [[ -n "$unlisted_unchecked" ]]; then
  printf '%s\n' "$unlisted_unchecked" >&2
  printf 'FAIL: @unchecked Sendable declaration is outside the centralized allowlist\n' >&2
  exit 1
fi

new_unchecked="$(git diff --unified=0 -- '*.swift' | rg '^\+[^+].*@unchecked Sendable' | rg -v 'PTSystemPixelBufferBox|PTSystemAVAssetBox' || true)"
if [[ -n "$new_unchecked" ]]; then
  printf '%s\n' "$new_unchecked" >&2
  printf 'FAIL: this change introduces a new @unchecked Sendable declaration\n' >&2
  exit 1
fi

new_unsafe="$(git diff --unified=0 -- '*.swift' | rg '^\+[^+].*nonisolated\(unsafe\)' || true)"
if [[ -n "$new_unsafe" ]]; then
  printf '%s\n' "$new_unsafe" >&2
  printf 'FAIL: this change introduces a new nonisolated(unsafe) declaration\n' >&2
  exit 1
fi

new_forceful_operations="$(git diff --unified=0 -- '*.swift' \
  | rg '^\+[^+]' \
  | rg 'try!|as!' \
  | rg -v '^\+[[:space:]]*(//|/\*|\*)' || true)"
if [[ -n "$new_forceful_operations" ]]; then
  printf '%s\n' "$new_forceful_operations" >&2
  printf 'FAIL: this change introduces a new try! or as! operation\n' >&2
  exit 1
fi

printf 'PASS: Swift 6 safety scans\n'
