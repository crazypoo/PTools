#!/usr/bin/env bash

set -euo pipefail

# English: Prove that split foundation targets keep their imports and manifest boundaries minimal.
# Español: Demuestra que los targets base separados mantienen imports y límites mínimos.
# 中文：验证拆分后的基础 target 保持最小 import 和 manifest 边界。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

swift package dump-package >/dev/null

for path in PooToolsSource/PToolsCore PooToolsSource/PToolsPermissionCore PooToolsSource/PToolsMediaCore; do
  [[ -d "$path" ]] || { printf 'FAIL: missing standalone source path %s\n' "$path" >&2; exit 1; }
done

# The permission core contains one narrowly gated iOS app-settings launcher.
# Other Foundation cores and all other permission-core sources remain UI-free.
if rg -n '^import (UIKit|Photos|AVFoundation|Kingfisher|SnapKit|Alamofire)' \
  PooToolsSource/PToolsCore PooToolsSource/PToolsMediaCore; then
  printf 'FAIL: standalone foundation target imports a feature or UI framework\n' >&2
  exit 1
fi

if rg -n '^import (Photos|AVFoundation|Kingfisher|SnapKit|Alamofire)' PooToolsSource/PToolsPermissionCore; then
  printf 'FAIL: standalone permission contract imports a feature framework\n' >&2
  exit 1
fi

if rg -n '^import UIKit' PooToolsSource/PToolsPermissionCore --glob '!PTPermissionCore.swift'; then
  printf 'FAIL: unexpected UIKit dependency in standalone permission contract\n' >&2
  exit 1
fi

if ! rg -q --fixed-strings '#if canImport(UIKit) && os(iOS)' PooToolsSource/PToolsPermissionCore/PTPermissionCore.swift; then
  printf 'FAIL: native permission settings opener is missing the iOS guard\n' >&2
  exit 1
fi

printf 'PASS: standalone foundation contract (iOS app-settings launcher excepted)\n'
