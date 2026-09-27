#!/usr/bin/env bash

set -euo pipefail

# English: Verify the P0 platform layers remain independently publishable and dependency-light.
# Español: Verifica que las capas de plataforma P0 sigan siendo publicables de forma independiente y con pocas dependencias.
# 中文：校验 P0 平台层仍可独立发布且保持轻依赖。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

modules=(
  PToolsConnectivity PToolsStorageCore PToolsStorage PToolsRouteCore
  PToolsDeepLink PToolsNotifications PToolsBackgroundTasks
)

for module in "${modules[@]}"; do
  test -d "PooToolsSource/$module"
  test -n "$(find "PooToolsSource/$module" -name '*.swift' -print -quit)"
  rg -q --fixed-strings "name: \"$module\"" Package.swift
done

foundation_modules=(PToolsConnectivity PToolsStorageCore PToolsStorage PToolsRouteCore PToolsDeepLink)
if rg -n --glob '*.swift' 'import UIKit|import PooToolsDEBUG|import PooToolsNetWork' \
    "${foundation_modules[@]/#/PooToolsSource/}"; then
  printf 'FAIL: Foundation platform layers import UI, Debug or concrete Network code\n' >&2
  exit 1
fi

if rg -n --glob '*.swift' '@unchecked Sendable|nonisolated\(unsafe\)' \
    "${modules[@]/#/PooToolsSource/}"; then
  printf 'FAIL: P0 platform layers contain an unregistered unsafe concurrency escape\n' >&2
  exit 1
fi

if rg -n --glob '*.swift' '\[AnyHashable: Any\]' \
    PooToolsSource/PToolsConnectivity PooToolsSource/PToolsStorageCore \
    PooToolsSource/PToolsStorage PooToolsSource/PToolsRouteCore PooToolsSource/PToolsDeepLink; then
  printf 'FAIL: typed P0 value layers expose dynamic payload dictionaries\n' >&2
  exit 1
fi

for subspec in Connectivity StorageCore Storage RouteCore DeepLink Notifications BackgroundTasks; do
  rg -q --fixed-strings "s.subspec '$subspec'" PooTools.podspec
done

printf 'P0 platform module contract OK\n'
