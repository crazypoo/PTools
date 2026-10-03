#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
derived_data="$(mktemp -d "${TMPDIR:-/tmp}/ptools-xcode-warnings.XXXXXX")"
build_log_dir="$(mktemp -d "${TMPDIR:-/tmp}/ptools-xcode-warnings-logs.XXXXXX")"
strict_project_root=""
keep_xcode_logs="$(printenv PTOOLS_KEEP_XCODE_LOGS || true)"

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
  if [[ -n "$strict_project_root" ]]; then
    while IFS= read -r process_id; do
      [[ -n "$process_id" && "$process_id" != "$$" ]] || continue
      kill "$process_id" 2>/dev/null || true
    done < <(pgrep -f -- "$strict_project_root" || true)
  fi
  if [[ "$keep_xcode_logs" == "1" ]]; then
    # English: Preserve raw diagnostics when a CI dependency blocker needs investigation.
    # Español: Conserva los diagnósticos originales cuando haya que investigar un bloqueo de dependencia en CI.
    # 中文：需要调查 CI 依赖阻断时保留原始诊断日志。
    printf 'INFO: preserved Xcode diagnostics at %s and %s\n' "$build_log_dir" "$strict_project_root" >&2
  else
    rm -rf "$derived_data" "$build_log_dir" "$strict_project_root"
  fi
}
trap cleanup EXIT

prepare_strict_project() {
  strict_project_root="$(mktemp -d "${TMPDIR:-/tmp}/ptools-strict-project.XXXXXX")"
  mkdir -p "$strict_project_root/Pods"
  cp -R "$repo_root/Pods/Pods.xcodeproj" "$strict_project_root/Pods/Pods.xcodeproj"

  # English: Mirror Pods through temporary links so only the temporary project file is mutated.
  # Español: Replica Pods mediante enlaces temporales para modificar únicamente el proyecto temporal.
  # 中文：通过临时链接复用 Pods，只修改临时工程文件。
  for entry in "$repo_root/Pods"/*; do
    local name
    name="$(basename "$entry")"
    [[ "$name" == "Pods.xcodeproj" ]] && continue
    ln -s "$entry" "$strict_project_root/Pods/$name"
    ln -s "$entry" "$strict_project_root/$name"
  done
  ln -s "$repo_root/PooToolsSource" "$strict_project_root/PooToolsSource"

  ruby -rxcodeproj - "$strict_project_root/Pods/Pods.xcodeproj" <<'RUBY'
require "xcodeproj"

project = Xcodeproj::Project.open(ARGV.fetch(0))
target = project.targets.find { |candidate| candidate.name == "PooTools" }
abort "PooTools target is missing from the temporary Pods project" unless target

# English: Keep strict concurrency scoped to PooTools; source warnings are checked by path below.
# Español: Mantiene la concurrencia estricta en PooTools; los warnings de código propio se comprueban por ruta abajo.
# 中文：只为 PooTools target 启用严格并发，源码警告由下面的路径扫描单独判定。
target.build_configurations.each do |configuration|
  configuration.build_settings["SWIFT_STRICT_CONCURRENCY"] = "complete"
  # English: Do not promote deprecations emitted while importing third-party modules into PooTools errors.
  # Español: No conviertas en errores de PooTools las deprecaciones emitidas al importar módulos de terceros.
  # 中文：不要把导入第三方模块时产生的弃用诊断升级为 PooTools 错误。
  configuration.build_settings["SWIFT_TREAT_WARNINGS_AS_ERRORS"] = "NO"
end
project.save
RUBY
}

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
  local strict_mode="$(printenv PTOOLS_STRICT_CONCURRENCY || true)"
  local source_path_pattern
  local dependency_path
  local source_exclusion
  local dependency_exclusion
  local derived_path="$derived_data/$configuration"
  local -a xcode_command

  if [[ "$strict_mode" == "1" ]]; then
    [[ -n "$strict_project_root" ]] || prepare_strict_project
    # English: Build the temporary PooTools target; dependency targets keep their own Swift settings.
    # Español: Compila el objetivo temporal PooTools; los objetivos dependientes conservan sus ajustes Swift.
    # 中文：构建临时 PooTools target，依赖 target 保持各自的 Swift 配置。
    xcode_command=(
      xcodebuild
      -project "$strict_project_root/Pods/Pods.xcodeproj"
      -scheme PooTools
    )
    source_path_pattern='PooToolsSource/[^:]+:[0-9]+:[0-9]+: (fatal )?(error|warning):'
    dependency_path="$strict_project_root/Pods/"
    source_exclusion='PooToolsSource/'
    dependency_exclusion="$strict_project_root/Pods/"
    derived_path="$strict_project_root/DerivedData/$configuration"
  else
    xcode_command=(
      xcodebuild
      -workspace "$repo_root/PooTools.xcworkspace"
      -scheme PooTools-Example
    )
    source_path_pattern="$repo_root/PooToolsSource/[^:]+:[0-9]+:[0-9]+: (fatal )?(error|warning):"
    dependency_path="$repo_root/Pods/"
    source_exclusion="$repo_root/PooToolsSource/"
    dependency_exclusion="$repo_root/Pods/"
  fi

  set +e
  "${xcode_command[@]}" \
    -configuration "$configuration" \
    -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$derived_path" \
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
  source_errors="$(search_regex -n -- "$source_path_pattern" "$build_log" | search_regex 'error:' || true)"
  source_warnings="$(search_regex -n -- "$source_path_pattern" "$build_log" | search_regex 'warning:' || true)"
  dependency_warnings="$(search_regex -n 'warning:' "$build_log" | search_fixed "$dependency_path" || true)"
  project_warnings="$(search_regex -n 'warning:' "$build_log" \
    | search_not_fixed "$source_exclusion" \
    | search_not_fixed "$dependency_exclusion" || true)"

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
      | search_not_fixed "$source_exclusion" || true)"
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
