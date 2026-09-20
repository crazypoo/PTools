#!/usr/bin/env bash
set -euo pipefail

# English: Validate the 5.14 Network, Socket, and Security source contract.
# Español: Valida el contrato de código fuente de Network, Socket y Security de 5.14.
# 中文：校验 5.14 Network、Socket 和 Security 的源码契约。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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

require_text PooTools.podspec "s.version[[:space:]]*=[[:space:]]*'5\\.14\\.0'" "podspec version is 5.14.0"
require_text README.md '当前开发基线为 `5\.14\.0`' "README version is 5.14.0"
require_text ROADMAP.md '当前代码基线：`5\.14\.0`' "roadmap version is 5.14.0"
require_text CHANGELOG.md "## 5\\.14\\.0" "changelog contains 5.14.0"
require_text Podfile.lock "PooTools/Security \\(5\\.14\\.0\\)" "Podfile.lock contains Security 5.14.0"

require_text PooToolsSource/NetWork/PTNetworkArchitecture.swift "public struct PTNetworkRequest" "typed Network request contract"
require_text PooToolsSource/NetWork/PTNetworkArchitecture.swift "public actor PTNetworkExecutor" "canonical Network executor"
require_text PooToolsSource/NetWork/NetworkTypes.swift "public struct PTRetryPolicy" "typed retry policy"
require_text PooToolsSource/NetWork/NetworkSupport.swift "Cache-Control" "HTTP cache metadata"
require_text PooToolsSource/NetWork/Network.swift "authRefreshCoordinator" "coalesced authentication refresh"
require_text PooToolsSource/SocketKit/PTWebSocketClient.swift "public actor PTWebSocketClient" "native actor WebSocket client"
require_text PooToolsSource/SocketKit/PTWebSocketClient.swift "URLSessionWebSocketTask" "native URLSession WebSocket transport"
require_text PooToolsSource/Security/PTSecurity.swift "public enum PTSecurity" "native Security facade"

# English: New canonical files must not add unsafe escape hatches or force-crash operators.
# Español: Los archivos canónicos nuevos no deben añadir escapes inseguros ni operadores de fallo forzado.
# 中文：新的 canonical 文件不得新增不安全逃逸方式或强制崩溃运算符。
canonical_files=(
    PooToolsSource/NetWork/PTNetworkArchitecture.swift
    PooToolsSource/NetWork/NetworkTypes.swift
    PooToolsSource/SocketKit/PTWebSocketClient.swift
    PooToolsSource/Security/PTSecurity.swift
)
if rg -n "try!|as!|nonisolated\\(unsafe\\)" "${canonical_files[@]}"; then
    fail "canonical 5.14 files contain a forbidden unsafe construct"
fi

# English: The new Security facade must not leak legacy third-party types.
# Español: La nueva fachada Security no debe filtrar tipos heredados de terceros.
# 中文：新的 Security 门面不得泄漏旧第三方类型。
if rg -n "CryptoSwift|IOSSecuritySuite|SocketRocket|Alamofire|KakaJSON" PooToolsSource/Security/PTSecurity.swift; then
    fail "PTSecurity exposes a legacy third-party type"
fi

# English: SocketRocket and CryptoSwift remain only in compatibility implementations during 5.x.
# Español: SocketRocket y CryptoSwift permanecen solo en implementaciones de compatibilidad durante 5.x.
# 中文：5.x 期间 SocketRocket 和 CryptoSwift 只允许存在于兼容实现中。
require_text PooToolsSource/SocketKit/PTSocketManager.swift "SocketRocket" "legacy SocketRocket compatibility entry"
require_text PooToolsSource/AESAndDES/PTDataEncryption.swift "CryptoSwift" "legacy CryptoSwift compatibility entry"

if ! git diff --check; then
    fail "git diff --check failed"
fi

if (( errors > 0 )); then
    printf '5.14 Network/Socket/Security validation failed: %d issue(s)\n' "$errors" >&2
    exit 1
fi

printf '5.14 Network/Socket/Security validation passed.\n'
