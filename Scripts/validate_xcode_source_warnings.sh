#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
derived_data="$(mktemp -d "${TMPDIR:-/tmp}/ptools-xcode-warnings.XXXXXX")"
build_log_dir="$(mktemp -d "${TMPDIR:-/tmp}/ptools-xcode-warnings-logs.XXXXXX")"

# English: Prefer ripgrep, but keep the warning gate usable on minimal CI images.
# Español: Prefiere ripgrep, pero mantiene la puerta de warnings utilizable en CI mínimo.
# 中文：优先使用 ripgrep，同时保证精简 CI 环境也能运行警告门禁。
if command -v rg >/dev/null 2>&1; then
  search_regex() { rg "$@"; }
  search_fixed() { rg --fixed-strings "$@"; }
  search_not_fixed() { rg -v --fixed-strings "$@"; }
else
  search_regex() { grep -En "$@"; }
  search_fixed() { grep -Fn -- "$@"; }
  search_not_fixed() { grep -Fv -- "$@"; }
fi

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
  local strict_args=""
  if [[ "$(printenv PTOOLS_STRICT_CONCURRENCY || true)" == "1" ]]; then
    # English: Keep strict concurrency opt-in so legacy Pods retain their declared Swift mode.
    # Español: Mantiene la concurrencia estricta como opción para que los Pods heredados conserven su modo Swift declarado.
    # 中文：严格并发只在专用门禁中启用，避免改变旧 Pods 自身声明的 Swift 模式。
    strict_args="SWIFT_STRICT_CONCURRENCY=complete SWIFT_TREAT_WARNINGS_AS_ERRORS=YES"
  fi

  set +e
  xcodebuild \
    -workspace "$repo_root/PooTools.xcworkspace" \
    -scheme PooTools-Example \
    -configuration "$configuration" \
    -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$derived_data" \
    $strict_args \
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
  source_errors="$(search_regex -n -- "$repo_root/PooToolsSource/[^:]+:[0-9]+:[0-9]+: error:" "$build_log" || true)"
  source_warnings="$(search_regex -n -- "$repo_root/PooToolsSource/[^:]+:[0-9]+:[0-9]+: warning:" "$build_log" || true)"
  dependency_warnings="$(search_regex -n 'warning:' "$build_log" | search_fixed "$repo_root/Pods/" || true)"
  project_warnings="$(search_regex -n 'warning:' "$build_log" \
    | search_not_fixed "$repo_root/PooToolsSource/" \
    | search_not_fixed "$repo_root/Pods/" || true)"

  if [[ -n "$source_errors" ]]; then
    printf '%s\n' "$source_errors" >&2
    printf 'FAIL [PTOOLS_SOURCE_COMPILER_ERROR] File %s Expected no PooTools source compiler errors Actual source errors in %s Rule PooTools source diagnostics must be zero\n' \
      "$build_log" "$configuration" >&2
    return 1
  fi

  if [[ -n "$source_warnings" ]]; then
    printf '%s\n' "$source_warnings" >&2
    printf 'FAIL [PTOOLS_SOURCE_COMPILER_WARNING] File %s Expected no PooTools source compiler warnings Actual source warnings in %s Rule PooTools source diagnostics must be zero\n' \
      "$build_log" "$configuration" >&2
    return 1
  fi

  # English: Only classify concrete file/line compiler diagnostics as errors; tool command text may contain the word "error".
  # Español: Solo clasifica como error un diagnóstico concreto con archivo y línea; el texto de una herramienta puede contener "error".
  # 中文：只把带有文件和行号的真实编译器诊断视为错误，工具命令文本可能只是包含 “error” 单词。
  if [[ "$build_exit" -eq 0 ]]; then
    non_source_errors="$(search_regex -n '(^|/)[^:[:space:]]+:[0-9]+:[0-9]+: (fatal )?error:' "$build_log" \
      | search_not_fixed "$repo_root/PooToolsSource/" || true)"
    if [[ -n "$non_source_errors" ]]; then
      printf '%s\n' "$non_source_errors" | head -40 >&2
      printf 'BLOCKED: Xcode emitted non-PooTools error diagnostics in %s despite exit code 0\n' "$configuration" >&2
      return 4
    fi
  fi

  if [[ "$build_exit" -ne 0 ]]; then
    local dependency_blockers='Unable to resolve module dependency|could not build module|SmartCodable-Swift.h|Failed to clone repository|failed to clone repository|unable to access .*(github.com|gitlab.com)|could not resolve package|SwiftSyntax.*(error|failed)|swift-syntax.*(error|failed)|/(Pods|SourcePackages/checkouts)/[^:]+:[0-9]+:[0-9]+: error:'
    local configuration_blockers='search path .* not found|linker command failed|xcodebuild: error:|The workspace named .* does not contain a scheme'
    if search_regex -q "$dependency_blockers" "$build_log"; then
      local direct_source_errors
      direct_source_errors="$(printf '%s\n' "$source_errors" \
        | search_regex -v 'no such module|could not build module|failed to build module|SmartCodable-Swift.h' || true)"
      if [[ -z "$direct_source_errors" ]]; then
        printf 'BLOCKED: external dependency build failed in %s.\n' "$configuration" >&2
        search_regex -n "$dependency_blockers" "$build_log" | head -40 >&2 || true
        printf 'FAIL [XCODE_EXTERNAL_DEPENDENCY] File %s Expected external dependencies build without blocking diagnostics Actual dependency diagnostics in %s Rule classify Pods and toolchain failures separately from PooTools source diagnostics\n' \
          "$build_log" "$configuration" >&2
        return 2
      fi
    fi
    if search_regex -q "$dependency_blockers" "$build_log" && [[ -z "$source_errors" ]]; then
      printf 'BLOCKED: external dependency build failed in %s.\n' "$configuration" >&2
      search_regex -n "$dependency_blockers" "$build_log" | head -40 >&2 || true
      printf 'FAIL [XCODE_EXTERNAL_DEPENDENCY] File %s Expected external dependencies build without blocking diagnostics Actual dependency diagnostics in %s Rule classify Pods and toolchain failures separately from PooTools source diagnostics\n' \
        "$build_log" "$configuration" >&2
      return 2
    fi
    if search_regex -qi "$configuration_blockers" "$build_log"; then
      printf 'BLOCKED: project configuration or linker setup failed in %s.\n' "$configuration" >&2
      search_regex -ni "$configuration_blockers" "$build_log" | head -40 >&2 || true
      printf 'FAIL [XCODE_CONFIGURATION_BLOCKER] File %s Expected workspace and linker configuration to resolve Actual configuration diagnostics in %s Rule classify project setup failures separately from PooTools source diagnostics\n' \
        "$build_log" "$configuration" >&2
      return 3
    fi
    tail -80 "$build_log" >&2
    printf 'FAIL [XCODE_BUILD_FAILURE] File %s Expected Xcode build success Actual unclassified build failure in %s Rule every non-dependency build failure must remain visible\n' \
      "$build_log" "$configuration" >&2
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
