#!/usr/bin/env bash

set -euo pipefail

# English: Validate the 5.36.1 closure artifacts without pretending hardware coverage is complete.
# Español: Valida los artefactos de cierre de 5.36.1 sin fingir que la cobertura de hardware está completa.
# 中文：校验 5.36.1 收口产物，但不伪装硬件验收已经完成。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

version="$(tr -d '[:space:]' < VERSION)"
[[ "$version" == "5.36.1" ]] || { printf 'FAIL: expected VERSION 5.36.1, got %s\n' "$version" >&2; exit 1; }

required_files=(
  PooToolsSource/PToolsCore/PTFeedbackCenter.swift
  PooToolsSource/PToolsContentState/PTBaseViewController+ContentState.swift
  PooToolsSource/PToolsDocuments/PTDocumentPDFBridge.swift
  PooToolsSource/Router/PTRouteHostCoordinator.swift
  Example/P0/README.md
  Example/P1/README.md
  Example/P2/README.md
  Example/Extensions/PToolsExampleIntentsExtension.swift
  Example/Extensions/PToolsExampleWidgetExtension.swift
  Example/Extensions/PToolsExampleLiveActivity.swift
  Example/Extensions/extension_targets.json
  docs/migrations/5.36.1_FINALIZATION.md
  docs/architecture/PTOOLS_5_36_1_FINALIZATION_MATRIX.md
)
for file in "${required_files[@]}"; do
  [[ -f "$file" ]] || { printf 'FAIL: missing closure artifact %s\n' "$file" >&2; exit 1; }
done

if rg -n --glob '*.swift' 'import Security' PooToolsSource/PToolsStorage; then
  printf 'FAIL: PToolsStorage contains a second Security implementation\n' >&2
  exit 1
fi

if rg -n --glob '*.swift' 'import PToolsLocation|PToolsLocation' PooToolsSource/PToolsNotifications; then
  printf 'FAIL: Notifications depends on the concrete PToolsLocation module\n' >&2
  exit 1
fi

if rg -n --glob '*.swift' 'UIApplication\.shared\.(windows|keyWindow)|connectedScenes' PooToolsSource/Router/PTRouteHostCoordinator.swift; then
  printf 'FAIL: route host uses global window discovery\n' >&2
  exit 1
fi

python3 -m json.tool Example/Extensions/extension_targets.json >/dev/null
swift package dump-package >/dev/null
pod ipc spec PooTools.podspec >/dev/null
git diff --check

printf 'PASS: PTools 5.36.1 static closure contract\n'
printf 'INFO: real BLE, audio/haptics, notification lifecycle, extension host and lock-screen checks remain device/host gates.\n'
