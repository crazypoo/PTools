#!/usr/bin/env bash

set -euo pipefail

# English: Validate reproducible dependency pins and the 5.9.6 supply-chain decisions.
# Español: Valida las versiones reproducibles y las decisiones de cadena de suministro de 5.9.6.
# 中文：校验可复现的依赖固定方式和 5.9.6 供应链决策。
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

require_match() {
  local pattern="$1"
  local file="$2"
  rg -n -- "$pattern" "$file" >/dev/null || fail "missing expected pattern in ${file}: ${pattern}"
}

if rg -n 'branch:' Package.swift >/dev/null; then
  fail 'Package.swift contains a floating branch dependency'
fi

if rg -n -i 'SocketRocket|SRWebSocket|SRReadyState' Package.swift Package.resolved PooTools.podspec Podfile.lock PooToolsSource Tests >/dev/null; then
  fail 'SocketRocket remains in an active manifest or shipped source path'
fi
require_match 'PTWebSocketTransport' PooToolsSource/SocketKit/PTWebSocketClient.swift
require_match 'PTURLSessionWebSocketTransport' PooToolsSource/SocketKit/PTWebSocketClient.swift

# English: Kitura cryptography packages must remain transitive through Swift-JWT until the 6.0 migration.
# Español: Los paquetes criptográficos de Kitura deben seguir siendo transitivos mediante Swift-JWT hasta la migración 6.0.
# 中文：在 6.0 迁移前，Kitura 加密包必须只通过 Swift-JWT 传递引入。
if rg -n 'github\.com/Kitura/(BlueCryptor|BlueRSA|BlueECC|LoggerAPI|KituraContracts)\.git|github\.com/apple/swift-log\.git' Package.swift >/dev/null; then
  fail 'unused Kitura or swift-log package is declared directly by PTools'
fi
require_match 'github\.com/Kitura/Swift-JWT\.git' Package.swift

swift_jwt_imports="$(rg -l '^import SwiftJWT$' PooToolsSource --glob '*.swift' || true)"
[[ "$swift_jwt_imports" == "PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift" ]] \
  || fail "unexpected direct SwiftJWT imports: ${swift_jwt_imports:-none}"

if rg -n "^[[:space:]]*pod[[:space:]]+[\"']Bugly" Podfile >/dev/null; then
  fail 'Podfile still hard-links the legacy Bugly pod'
fi
if rg -n '^[[:space:]-]+Bugly([[:space:]]|$)' Podfile.lock >/dev/null; then
  fail 'Podfile.lock still contains the legacy Bugly pod'
fi
if [[ -e Pods/Bugly/Bugly.framework ]]; then
  fail 'legacy Bugly.framework is still present under Pods'
fi
require_match 'canImport\(Bugly\)' PooTools/AppDelegate.swift

require_match 'PooTools/Core' docs/architecture/DEPENDENCIES.md
[[ -f report/baselines/5.9/dependency_supply_chain_5.9.6.md ]] || fail 'dependency report is missing'

printf 'PASS: 5.9.6 dependency ownership and reproducibility checks\n'
