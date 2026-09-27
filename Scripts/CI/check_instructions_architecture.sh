#!/usr/bin/env bash

set -euo pipefail

# English: Keep instruction presentation on the shared OverlayCore boundary.
# Español: Mantén la presentación de instrucciones en el límite compartido de OverlayCore.
# 中文：确保引导展示始终位于共享 OverlayCore 边界内。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

rg -q --fixed-strings 'dependencies: ["PToolsOverlay"]' Package.swift \
  || { printf 'FAIL: SwiftPM Instructions target does not depend on PToolsOverlay\n' >&2; exit 1; }
rg -q --fixed-strings "subspec.dependency 'PooTools/Overlay'" PooTools.podspec \
  || { printf 'FAIL: CocoaPods Instructions subspec does not depend on Overlay\n' >&2; exit 1; }

if rg -n 'PTInstruction(Window|SceneResolver|PassthroughWindow|AnchorEngine|ArrowEngine)|UIWindow\s*\(' PooToolsSource/Instructions >/tmp/ptools-instructions-architecture.txt; then
  cat /tmp/ptools-instructions-architecture.txt >&2
  printf 'FAIL: Instructions introduces duplicate window or geometry infrastructure\n' >&2
  exit 1
fi

printf 'PASS: Instructions uses the shared OverlayCore boundary\n'
