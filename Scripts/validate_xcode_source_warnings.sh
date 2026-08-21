#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
derived_data="$(mktemp -d "${TMPDIR:-/tmp}/ptools-xcode-warnings.XXXXXX")"
build_log="$(mktemp "${TMPDIR:-/tmp}/ptools-xcode-warnings.XXXXXX.log")"
cleanup() {
  rm -rf "$derived_data" "$build_log"
}
trap cleanup EXIT

set +e
xcodebuild \
  -workspace "$repo_root/PooTools.xcworkspace" \
  -scheme PooTools-Example \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$derived_data" \
  CODE_SIGNING_ALLOWED=NO \
  SWIFT_VERSION=6.0 \
  SWIFT_STRICT_CONCURRENCY=complete \
  build >"$build_log" 2>&1
build_exit=$?
set -e

source_warnings="$(rg -n 'warning:' "$build_log" | rg '/PooToolsSource/|/PooTools/' || true)"
if [[ -n "$source_warnings" ]]; then
  printf '%s\n' "$source_warnings" >&2
  printf 'FAIL: PooTools source compiler warnings remain\n' >&2
  exit 1
fi

dependency_blockers='Unable to resolve module dependency|search path .* not found|could not build module|SmartCodable-Swift.h|/Pods/[^:]+:.*error:'
if rg -q "$dependency_blockers" "$build_log"; then
  printf 'BLOCKED: Xcode dependency artifacts are unavailable; source warnings were not observable.\n' >&2
  rg -n "$dependency_blockers" "$build_log" | head -40 >&2 || true
  exit 2
fi

if [[ "$build_exit" -ne 0 ]]; then
  tail -80 "$build_log" >&2
  printf 'FAIL: Xcode build failed without a classified dependency blocker\n' >&2
  exit "$build_exit"
fi

printf 'PASS: no PooTools source compiler warnings\n'
