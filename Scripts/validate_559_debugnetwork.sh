#!/usr/bin/env bash

set -euo pipefail

# English: Keep DebugNetwork observer-only and fail on the removed business behaviors.
# Español: Mantiene DebugNetwork como observador y falla ante comportamientos de negocio eliminados.
# 中文：保持 DebugNetwork 仅观测，并对已删除的业务行为直接失败。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail() { printf 'FAIL [DEBUGNETWORK_559] %s\n' "$1" >&2; exit 1; }
require_file() { [[ -f "$1" ]] || fail "missing $1"; }
require_text() { grep -Fq -- "$2" "$1" || fail "missing '$2' in $1"; }

for file in \
  PooToolsSource/DebugNetwork/PTNetworkCaptureModels.swift \
  PooToolsSource/DebugNetwork/PTNetworkCaptureStore.swift \
  PooToolsSource/DebugNetwork/PTNetworkRedactor.swift \
  PooToolsSource/DebugNetwork/PTNetworkExporters.swift \
  PooToolsSource/DebugNetwork/PTNetworkDebugSupport.swift \
  PooToolsSource/DebugNetwork/PTNetworkModuleCaptureAdapter.swift \
  docs/debug/DEBUG_NETWORK.md \
  docs/debug/DEBUG_NETWORK_ARCHITECTURE.md \
  docs/debug/DEBUG_NETWORK_CAPABILITY_MATRIX.md \
  docs/debug/DEBUG_NETWORK_PRIVACY.md \
  docs/debug/DEBUG_NETWORK_MIGRATION_6.md; do
  require_file "$file"
done

require_text PooToolsSource/DebugNetwork/PTNetworkCaptureStore.swift 'public actor PTNetworkCaptureStore'
require_text PooToolsSource/DebugNetwork/PTNetworkCaptureStore.swift 'func changes() -> AsyncStream<PTNetworkCaptureChange>'
require_text PooToolsSource/DebugNetwork/PTNetworkCaptureModels.swift 'public struct PTNetworkCaptureRecord'
require_text PooToolsSource/DebugNetwork/PTNetworkCaptureModels.swift 'httpBodyStream'
require_text PooToolsSource/DebugNetwork/PTNetworkRedactor.swift '"authorization"'
require_text PooToolsSource/DebugNetwork/PTNetworkExporters.swift '"version": "1.2"'
require_text PooToolsSource/DebugNetwork/PTNetworkWatcherViewController.swift 'PTLoopbackThroughputBenchmark'
require_text PooToolsSource/DebugNetwork/PTNetworkHelper.swift 'private let lifecycleBag = PTLifecycleBag()'
require_text PooToolsSource/DebugCategory/URLSessionConfiguration+PTSwizzle.swift 'urlsessionconfiguration.swizzle'

protocol_file=PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift
for forbidden in 'NetworkCache.shared' 'PTThreadOperator' 'UncheckedSendableBox' 'fakeResponse'; do
  if grep -Fq -- "$forbidden" "$protocol_file"; then
    fail "$forbidden remains in URLProtocol adapter"
  fi
done
[[ ! -f PooToolsSource/DebugNetwork/PTThreadOperator.swift ]] || fail 'PTThreadOperator.swift still exists'
[[ ! -f PooToolsSource/DebugNetwork/PTCacheStoragePolicy.swift ]] || fail 'PTCacheStoragePolicy.swift still exists'

printf 'PASS [DEBUGNETWORK_559] observer-only capture contract\n'
