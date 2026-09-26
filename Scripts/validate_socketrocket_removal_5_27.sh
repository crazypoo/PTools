#!/usr/bin/env bash

set -euo pipefail

# English: Keep SocketRocket out of every 5.27 shipped path.
# Español: Mantén SocketRocket fuera de todas las rutas entregadas de 5.27.
# 中文：确保 5.27 的所有交付路径都不再包含 SocketRocket。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

version="$(tr -d '[:space:]' < VERSION)"
[[ "$version" == 5.27.* ]] || { printf 'FAIL: SocketRocket removal gate requires 5.27.x, got %s\n' "$version" >&2; exit 1; }

active_paths=(Package.swift Package.resolved PooTools.podspec Podfile.lock PooToolsSource Tests)
if rg -n -i 'SocketRocket|SRWebSocket|SRReadyState' "${active_paths[@]}" >/dev/null; then
  printf 'FAIL: SocketRocket symbols remain in an active manifest, source, or test path\n' >&2
  exit 1
fi

required_patterns=(
  'PooToolsSource/SocketKit/PTWebSocketClient.swift|public actor PTWebSocketClient'
  'PooToolsSource/SocketKit/PTWebSocketClient.swift|public protocol PTWebSocketTransport'
  'PooToolsSource/SocketKit/PTWebSocketClient.swift|public actor PTURLSessionWebSocketTransport'
  'PooToolsSource/SocketKit/PTWebSocketClient.swift|PTWebSocketSendBuffer'
  'PooToolsSource/SocketKit/PTWebSocketClient.swift|PTWebSocketTrustPolicy'
  'PooToolsSource/SocketKit/PTWebSocketClient.swift|PTWebSocketMetrics'
  'PooToolsSource/SocketKit/PTSocketManager.swift|public final class PTSocketManager'
  'PooToolsSource/SocketKit/PTSocketManager.swift|PTWebSocketClient'
  'PooToolsSource/SocketKit/PTWebSocketClient.swift|SecTrustEvaluateWithError'
  'docs/audits/SOCKETROCKET_USAGE_AUDIT.md|5.27.0'
  'docs/migrations/SOCKETROCKET_TO_NATIVE_WEBSOCKET.md|PTWebSocketClient'
  'docs/architecture/PTOOLS_WEBSOCKET_GUIDE.md|代际'
  'docs/testing/WEBSOCKET_TEST_MATRIX.md|终结'
)
for requirement in "${required_patterns[@]}"; do
  file="${requirement%%|*}"
  pattern="${requirement#*|}"
  rg -q --fixed-strings "$pattern" "$file" || {
    printf 'FAIL: WebSocket marker missing: %s (%s)\n' "$file" "$pattern" >&2
    exit 1
  }
done

if rg -n -i 'allowAll|trust.?all|disable.*trust' PooToolsSource/SocketKit/PTWebSocketClient.swift >/dev/null; then
  printf 'FAIL: native WebSocket contains a trust-all bypass\n' >&2
  exit 1
fi

if rg -n '^import (UIKit|Network)$' PooToolsSource/SocketKit/PTWebSocketClient.swift >/dev/null; then
  printf 'FAIL: native WebSocket core imports UIKit or Network\n' >&2
  exit 1
fi

git diff --check
printf 'PASS: PTools 5.27 native WebSocket and SocketRocket removal contract\n'
