#!/usr/bin/env bash

set -euo pipefail

# English: Enforce the 5.28.0 native HTTP server boundary and the zero-runtime-dependency rule.
# Español: Refuerza el límite del servidor HTTP nativo de 5.28.0 y la regla de cero dependencias de runtime.
# 中文：强制执行 5.28.0 原生 HTTP Server 边界和运行时零第三方依赖规则。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

active_matches="$(rg -n --hidden --glob '*.swift' --glob '!Pods/**' \
  'import GCDWebServer|GCDWebUploader|GCDWebServerRequest|GCDWebServerResponse' \
  PooToolsSource PooTools Tests 2>/dev/null || true)"
if [[ -n "$active_matches" ]]; then
  printf '%s\n' "$active_matches" >&2
  fail 'GCDWebServer runtime types remain in active Swift sources'
fi

pod_dependency_matches="$(rg -n --hidden "dependency ['\"]GCDWebServer|dependency ['\"]GCDWebServer/WebUploader" PooTools.podspec 2>/dev/null || true)"
if [[ -n "$pod_dependency_matches" ]]; then
  printf '%s\n' "$pod_dependency_matches" >&2
  fail 'CocoaPods still declares the removed GCDWebServer dependency'
fi

if rg -n 'GCDWebServer|GCDWebUploader' Podfile.lock 2>/dev/null; then
  fail 'Podfile.lock still resolves GCDWebServer or WebUploader'
fi

[[ -f PooToolsSource/PToolsHTTPServer/PTHTTPServer.swift ]] || fail 'missing PTHTTPServer implementation'
[[ -f PooToolsSource/PToolsHTTPFilePortal/PTHTTPFilePortal.swift ]] || fail 'missing PTHTTPFilePortal implementation'
rg -q 'PToolsHTTPServer' Package.swift || fail 'SwiftPM PToolsHTTPServer product/target is missing'
rg -q "subspec 'HTTPServer'" PooTools.podspec || fail 'CocoaPods HTTPServer subspec is missing'
rg -q "subspec 'HTTPFilePortal'" PooTools.podspec || fail 'CocoaPods HTTPFilePortal subspec is missing'
rg -q "subspec 'GCDWebServer'" PooTools.podspec || fail 'legacy GCDWebServer compatibility alias is missing'

printf 'PASS: 5.28.0 GCDWebServer removal and native HTTP server contract\n'
