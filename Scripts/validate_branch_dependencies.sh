#!/usr/bin/env bash

set -euo pipefail

# English: Reject floating dependency branches in the package manifest.
# Español: Rechaza ramas flotantes de dependencias en el manifiesto del paquete.
# 中文：拒绝 Package.swift 中不可复现的浮动依赖分支。
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

if rg -n 'branch:' Package.swift; then
  printf 'FAIL: Package.swift contains a floating dependency branch\n' >&2
  exit 1
fi

printf 'PASS: Package.swift dependencies are revision or version pinned\n'
