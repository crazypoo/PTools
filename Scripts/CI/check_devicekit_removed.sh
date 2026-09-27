#!/usr/bin/env bash

set -euo pipefail

# English: Block direct DeviceKit references in production and build contracts.
# Español: Bloquea referencias directas a DeviceKit en producción y contratos de compilación.
# 中文：阻止生产代码和构建契约重新直接引用 DeviceKit。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

if rg -n --glob '*.swift' --glob '*.m' --glob '*.h' '(^|[[:space:]])import[[:space:]]+DeviceKit([[:space:]]|$)|\bDeviceKit\b' PooToolsSource PooTools Tests; then
  printf 'FAIL: DeviceKit source reference found\n' >&2
  exit 1
fi

if rg -n --fixed-strings 'devicekit/DeviceKit' Package.swift Package.resolved PooTools.podspec Podfile.lock; then
  printf 'FAIL: DeviceKit package dependency found\n' >&2
  exit 1
fi

if rg -n --fixed-strings "dependency 'DeviceKit'" PooTools.podspec; then
  printf 'FAIL: DeviceKit CocoaPods dependency found\n' >&2
  exit 1
fi

[[ -d PooToolsSource/PToolsDevice ]] || { printf 'FAIL: PToolsDevice source is missing\n' >&2; exit 1; }
rg -q --fixed-strings '.library(name: "PToolsDevice"' Package.swift || { printf 'FAIL: SwiftPM PToolsDevice product is missing\n' >&2; exit 1; }
rg -q --fixed-strings "s.subspec 'Device'" PooTools.podspec || { printf 'FAIL: CocoaPods Device subspec is missing\n' >&2; exit 1; }
printf 'PASS: DeviceKit is removed and PToolsDevice is declared\n'
