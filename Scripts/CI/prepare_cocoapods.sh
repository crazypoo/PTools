#!/usr/bin/env bash

set -euo pipefail

# English: Generate Pods before any workspace build or strict-concurrency source check.
# Español: Genera Pods antes de cualquier compilación del workspace o comprobación de concurrencia estricta.
# 中文：在任何 workspace 构建或严格并发源码检查前生成 Pods。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

bash Scripts/CI/prepare_quality_environment.sh --cocoapods
pod install --no-repo-update

[[ -d "$repo_root/Pods/Pods.xcodeproj" ]] || {
  printf 'FAIL [PODS_PREREQUISITE] Pods/Pods.xcodeproj was not generated\n' >&2
  exit 1
}
[[ -f "$repo_root/Pods/Target Support Files/Pods-PooTools_Example/Pods-PooTools_Example.debug.xcconfig" ]] || {
  printf 'FAIL [PODS_PREREQUISITE] Pods-PooTools_Example.debug.xcconfig was not generated\n' >&2
  exit 1
}

printf 'PASS [PODS_PREREQUISITE] workspace Pods are ready\n'
