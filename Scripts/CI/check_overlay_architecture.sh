#!/usr/bin/env bash
# English: Prevent feature modules from copying OverlayCore scene and window infrastructure.
# Español: Evita que los módulos de funciones copien la infraestructura de escenas y ventanas de OverlayCore.
# 中文：防止功能模块复制 OverlayCore 的 Scene 和 Window 基础设施。

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
scan_paths=("$repo_root/PooToolsSource" "$repo_root/Sources" "$repo_root/Tests")
forbidden='PTPopoverSceneResolver|PTPopoverOverlayWindow|PTPopoverPassthroughWindow|PTPopoverHost|PTPopoverRegistry|PTPopoverZOrderManager|PTBannerSceneResolver|PTBannerOverlayWindow|PTBannerPassthroughWindow'

existing_paths=()
for path in "${scan_paths[@]}"; do
  [[ -e "$path" ]] && existing_paths+=("$path")
done

if rg -n "$forbidden" "${existing_paths[@]}"; then
  echo "FAIL: duplicated OverlayCore infrastructure detected." >&2
  exit 1
fi

echo "Overlay architecture guard passed."
