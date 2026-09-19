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

if rg -n '^import (UIKit|Photos|AVFoundation|Kingfisher|SnapKit|Alamofire)' \
  PooToolsSource/PToolsCore PooToolsSource/PToolsPermissionCore PooToolsSource/PToolsMediaCore; then
  printf 'FAIL: standalone foundation target imports a feature or UI framework\n' >&2
  exit 1
fi

printf 'PASS: standalone foundation module contract\n'
