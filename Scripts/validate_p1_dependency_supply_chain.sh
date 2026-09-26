#!/usr/bin/env bash

set -euo pipefail

# English: Keep third-party dependency choices reproducible and documented before 6.0.
# Español: Mantén reproducibles y documentadas las dependencias de terceros antes de 6.0.
# 中文：在 6.0 前保持第三方依赖可复现并有文档记录。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if rg -n 'branch:' Package.swift; then
  printf 'FAIL: Package.swift contains a floating branch dependency\n' >&2
  exit 1
fi

for required in 'Swift-JWT.git", exact:' 'KakaJSON.git", exact:'; do
  rg -n -- "$required" Package.swift >/dev/null || {
    printf 'FAIL: missing reproducible dependency policy for %s\n' "$required" >&2
    exit 1
  }
done

if rg -n -i 'SocketRocket|SRWebSocket|SRReadyState' Package.swift Package.resolved PooTools.podspec Podfile.lock PooToolsSource Tests >/dev/null; then
  printf 'FAIL: SocketRocket remains in an active manifest or shipped source path\n' >&2
  exit 1
fi

[[ -f docs/architecture/DEPENDENCIES.md ]] || {
  printf 'FAIL: dependency ownership document is missing\n' >&2
  exit 1
}

printf 'PASS: P1 dependency supply-chain contract\n'
