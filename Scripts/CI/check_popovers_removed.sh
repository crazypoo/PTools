#!/usr/bin/env bash
# English: Fail when the removed Popovers dependency returns to production inputs.
# Español: Falla si la dependencia Popovers eliminada vuelve a las entradas de producción.
# 中文：如果已移除的 Popovers 依赖重新进入生产输入，则检查失败。

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
scan_paths=(
  "$repo_root/Package.swift"
  "$repo_root/PooTools.podspec"
  "$repo_root/PooToolsSource"
  "$repo_root/Sources"
  "$repo_root/Tests"
)

existing_paths=()
for path in "${scan_paths[@]}"; do
  [[ -e "$path" ]] && existing_paths+=("$path")
done

if rg -n -i "import[[:space:]]+Popovers|dependency[[:space:]]+['\"]Popovers|aheze/Popovers" "${existing_paths[@]}"; then
  echo "FAIL: Popovers dependency or runtime import remains in production inputs." >&2
  exit 1
fi

echo "Popovers removal guard passed."
