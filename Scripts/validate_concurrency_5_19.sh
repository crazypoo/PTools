#!/usr/bin/env bash

set -euo pipefail

# English: Keep the 5.19.x concurrency boundary focused on real unsafe crossings.
# Español: Mantiene el límite de concurrencia de 5.19.x enfocado en cruces realmente inseguros.
# 中文：让 5.19.x 并发边界门禁只关注真实的不安全跨越。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

source_root="PooToolsSource"

if rg -n --glob '*.swift' 'nonisolated\(unsafe\)' "$source_root"; then
  printf 'FAIL: production source contains nonisolated(unsafe)\n' >&2
  exit 1
fi

# English: These legacy misuse patterns must stay absent after the snapshot migration.
# Español: Estos patrones heredados de uso incorrecto deben permanecer ausentes tras la migración de instantáneas.
# 中文：快照迁移完成后，这些历史不安全用法必须保持不存在。
if rg -n --no-filename 'Task\.detached|DispatchQueue\.global\(\)\.async' \
  "$source_root/BioID/PTBiologyID.swift" \
  "$source_root/WebKit/PTHTMLHeightCalculator.swift" \
  "$source_root/Colors/UIImage+PTColorEX.swift" \
  "$source_root/Base/PTVideoCoverCache.swift" \
  | rg 'LAContext|context|UIImage|CIImage|webView|image\.jpegData|global\(\)\.async'; then
  printf 'FAIL: non-Sendable system object crosses a detached/background boundary\n' >&2
  exit 1
fi

required_patterns=(
  'PooToolsSource/DebugCategory/UIWindow+PTDebugEx.swift|OSAllocatedUnfairLock<CGPoint?>'
  'PooToolsSource/Language/PTLanguage.swift|OSAllocatedUnfairLock'
  'PooToolsSource/PhotoPicker/PTMediaLibAlbumListViewController.swift|titleViewMode = .auto'
  'PooToolsSource/Vision/PTVision.swift|public static var share: PTVision'
)
for requirement in "${required_patterns[@]}"; do
  path="${requirement%%|*}"
  pattern="${requirement#*|}"
  rg -q --fixed-strings "$pattern" "$path" \
    || { printf 'FAIL: concurrency boundary marker missing: %s (%s)\n' "$path" "$pattern" >&2; exit 1; }
done

printf 'PASS: PTools 5.19.5 concurrency boundaries\n'
