#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
derived_data="$(mktemp -d "${TMPDIR:-/tmp}/ptools-xcode-warnings.XXXXXX")"
build_log_dir="$(mktemp -d "${TMPDIR:-/tmp}/ptools-xcode-warnings-logs.XXXXXX")"
cleanup() {
  while IFS= read -r process_id; do
    [[ -n "$process_id" && "$process_id" != "$$" ]] || continue
    kill "$process_id" 2>/dev/null || true
  done < <(pgrep -f -- "$derived_data" || true)
  rm -rf "$derived_data" "$build_log_dir"
}
trap cleanup EXIT

read_build_setting() {
  local target="$1"
  local key="$2"
  xcodebuild \
    -project "$repo_root/Pods/Pods.xcodeproj" \
    -target "$target" \
    -configuration Debug \
    -showBuildSettings 2>/dev/null \
    | sed -n "s/^[[:space:]]*$key = //p" \
    | head -1
}

ptools_swift_version="$(read_build_setting PooTools SWIFT_VERSION)"
ptools_deployment_target="$(read_build_setting PooTools IPHONEOS_DEPLOYMENT_TARGET)"
snapkit_swift_version="$(read_build_setting SnapKit SWIFT_VERSION)"

[[ "$ptools_swift_version" == "6.0" ]] \
  || { printf 'FAIL: PooTools target must use Swift 6.0 (actual: %s)\n' "$ptools_swift_version" >&2; exit 1; }
[[ "$ptools_deployment_target" == "17.0" ]] \
  || { printf 'FAIL: PooTools target must use iOS 17.0 (actual: %s)\n' "$ptools_deployment_target" >&2; exit 1; }
[[ "$snapkit_swift_version" == "5.0" ]] \
  || { printf 'FAIL: SnapKit target should retain its declared Swift 5.0 mode (actual: %s)\n' "$snapkit_swift_version" >&2; exit 1; }

run_build() {
  local configuration="$1"
  local build_log="$build_log_dir/$configuration.log"

  set +e
  xcodebuild \
    -workspace "$repo_root/PooTools.xcworkspace" \
    -scheme PooTools-Example \
    -configuration "$configuration" \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$derived_data" \
    CODE_SIGNING_ALLOWED=NO \
    ARCHS=arm64 \
    ONLY_ACTIVE_ARCH=YES \
    build >"$build_log" 2>&1
  local build_exit=$?
  set -e

  local source_errors
  local source_warnings
  local dependency_warnings
  local project_warnings
  source_errors="$(rg -n -- "$repo_root/PooToolsSource/[^:]+:[0-9]+:[0-9]+: error:" "$build_log" || true)"
  source_warnings="$(rg -n -- "$repo_root/PooToolsSource/[^:]+:[0-9]+:[0-9]+: warning:" "$build_log" || true)"
  dependency_warnings="$(rg -n 'warning:' "$build_log" | rg --fixed-strings "$repo_root/Pods/" || true)"
  project_warnings="$(rg -n 'warning:' "$build_log" \
    | rg -v --fixed-strings "$repo_root/PooToolsSource/" \
    | rg -v --fixed-strings "$repo_root/Pods/" || true)"

  if [[ -n "$source_errors" ]]; then
    printf '%s\n' "$source_errors" >&2
    printf 'FAIL: PooTools source compiler errors remain in %s\n' "$configuration" >&2
    return 1
  fi

  if [[ -n "$source_warnings" ]]; then
    printf '%s\n' "$source_warnings" >&2
    printf 'FAIL: PooTools source compiler warnings remain in %s\n' "$configuration" >&2
    return 1
  fi

  # Do not treat an Xcode log containing an error diagnostic as a successful build when xcodebuild reports zero.
  # No trates como compilación correcta un registro de Xcode con errores aunque xcodebuild devuelva cero.
  # 即使 xcodebuild 返回 0，只要日志含有错误诊断，也不能判定构建成功。
  if [[ "$build_exit" -eq 0 ]]; then
    non_source_errors="$(rg -n '(^|[^[:alnum:]_])error:' "$build_log" \
      | rg -v --fixed-strings "$repo_root/PooToolsSource/" || true)"
    if [[ -n "$non_source_errors" ]]; then
      printf '%s\n' "$non_source_errors" | head -40 >&2
      printf 'BLOCKED: Xcode emitted non-PooTools error diagnostics in %s despite exit code 0\n' "$configuration" >&2
      return 4
    fi
  fi

  if [[ "$build_exit" -ne 0 ]]; then
    local dependency_blockers='Unable to resolve module dependency|could not build module|SmartCodable-Swift.h|Failed to clone repository|failed to clone repository|unable to access .*(github.com|gitlab.com)|could not resolve package|SwiftSyntax.*(error|failed)|swift-syntax.*(error|failed)|/(Pods|SourcePackages/checkouts)/[^:]+:[0-9]+:[0-9]+: error:'
    local configuration_blockers='search path .* not found|linker command failed|xcodebuild: error:|The workspace named .* does not contain a scheme'
    if rg -q "$dependency_blockers" "$build_log"; then
      local direct_source_errors
      direct_source_errors="$(printf '%s\n' "$source_errors" \
        | rg -v 'no such module|could not build module|failed to build module|SmartCodable-Swift.h' || true)"
      if [[ -z "$direct_source_errors" ]]; then
        printf 'BLOCKED: external dependency build failed in %s.\n' "$configuration" >&2
        rg -n "$dependency_blockers" "$build_log" | head -40 >&2 || true
        return 2
      fi
    fi
    if rg -q "$dependency_blockers" "$build_log" && [[ -z "$source_errors" ]]; then
      printf 'BLOCKED: external dependency build failed in %s.\n' "$configuration" >&2
      rg -n "$dependency_blockers" "$build_log" | head -40 >&2 || true
      return 2
    fi
    if rg -qi "$configuration_blockers" "$build_log"; then
      printf 'BLOCKED: project configuration or linker setup failed in %s.\n' "$configuration" >&2
      rg -ni "$configuration_blockers" "$build_log" | head -40 >&2 || true
      return 3
    fi
    tail -80 "$build_log" >&2
    printf 'FAIL: Xcode %s build failed without a classified dependency blocker\n' "$configuration" >&2
    return "$build_exit"
  fi

  if [[ -n "$dependency_warnings" ]]; then
    printf 'INFO: %s dependency warning lines were reported in %s (not counted as PooTools source warnings).\n' \
      "$(printf '%s\n' "$dependency_warnings" | wc -l | tr -d ' ')" "$configuration"
  fi
  if [[ -n "$project_warnings" ]]; then
    printf 'INFO: %s project or toolchain warning lines were reported in %s (reported separately).\n' \
      "$(printf '%s\n' "$project_warnings" | wc -l | tr -d ' ')" "$configuration"
  fi

  printf 'PASS: no PooTools source compiler warnings in %s\n' "$configuration"
}

printf 'PASS: target settings resolve to PooTools Swift %s / iOS %s and SnapKit Swift %s\n' \
  "$ptools_swift_version" "$ptools_deployment_target" "$snapkit_swift_version"
run_build Debug
run_build Release
