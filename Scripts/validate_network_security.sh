#!/usr/bin/env bash

set -euo pipefail

# English: Validate the current Network, Socket, and Security source contract.
# Español: Valida el contrato actual de código fuente de Network, Socket y Security.
# 中文：校验当前 Network、Socket 和 Security 的源码契约。

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

errors=0
fail() {
    printf 'FAIL: %s\n' "$1" >&2
    errors=$((errors + 1))
}

require_text() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    if ! rg -q -- "$pattern" "$file"; then
        fail "$description ($file)"
    fi
}

require_text PooToolsSource/NetWork/PTNetworkArchitecture.swift "public actor PTNetworkExecutor" "canonical Network executor"
require_text PooToolsSource/NetWork/NetworkTypes.swift "public struct PTRetryPolicy" "typed retry policy"
require_text PooToolsSource/SocketKit/PTWebSocketClient.swift "public actor PTWebSocketClient" "native WebSocket client"
require_text PooToolsSource/Security/PTSecurity.swift "public enum PTSecurity" "native Security facade"

if rg -n "try!|as!|nonisolated\(unsafe\)" \
    PooToolsSource/NetWork/PTNetworkArchitecture.swift \
    PooToolsSource/NetWork/NetworkTypes.swift \
    PooToolsSource/SocketKit/PTWebSocketClient.swift \
    PooToolsSource/Security/PTSecurity.swift; then
    fail "canonical Network/Socket/Security files contain a forbidden unsafe construct"
fi

if rg -n "CryptoSwift|IOSSecuritySuite|SocketRocket|Alamofire|KakaJSON" PooToolsSource/Security/PTSecurity.swift; then
    fail "PTSecurity exposes a legacy third-party type"
fi

if ! git diff --check; then
    fail "git diff --check failed"
fi

if (( errors > 0 )); then
    printf 'Network/Socket/Security validation failed: %d issue(s)\n' "$errors" >&2
    exit 1
fi

printf 'Network/Socket/Security validation passed.\n'
