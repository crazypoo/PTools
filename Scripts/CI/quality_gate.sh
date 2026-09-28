#!/usr/bin/env bash

set -euo pipefail

# English: Run one diagnosable quality gate and persist a small machine-readable result.
# Español: Ejecuta una puerta de calidad diagnosticable y guarda un resultado pequeño legible por máquinas.
# 中文：执行一个可诊断的质量门禁，并保存简洁的机器可读结果。

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"

gate="all"
if [[ "$#" -gt 0 ]]; then
  gate="$1"
fi
report_dir="$(printenv QUALITY_REPORT_DIR || true)"
if [[ -z "$report_dir" ]]; then
  report_root="$(printenv RUNNER_TEMP || true)"
  if [[ -z "$report_root" ]]; then
    report_root="$(printenv TMPDIR || true)"
  fi
  if [[ -z "$report_root" ]]; then
    report_root="/tmp"
  fi
  report_dir="$report_root/ptools-quality-report"
fi
mkdir -p "$report_dir"
export QUALITY_REPORT_DIR="$report_dir"

append_step_summary() {
  local summary_path
  summary_path="$(printenv GITHUB_STEP_SUMMARY || true)"
  [[ -n "$summary_path" ]] || return 0
  cat "$1" >> "$summary_path"
}

write_gate_result() {
  local gate_id="$1"
  local status="$2"
  local code="$3"
  local duration="$4"
  local log_path="$5"
  local repository_version
  repository_version="$(tr -d '[:space:]' < VERSION)"
  local commit
  commit="$(git rev-parse HEAD 2>/dev/null || true)"
  ruby -rjson - "$report_dir/$gate_id.json" "$gate_id" "$status" "$code" "$duration" "$log_path" "$repository_version" "$commit" <<'RUBY'
path, gate_id, status, code, duration, log_path, repository_version, commit = ARGV
File.write(
  path,
  JSON.pretty_generate(
    "schemaVersion" => 1,
    "gate" => gate_id,
    "repositoryVersion" => repository_version,
    "commit" => commit,
    "status" => status,
    "failureCode" => (status == "pass" ? nil : code),
    "durationSeconds" => duration.to_f,
    "log" => log_path
  ) + "\n"
)
RUBY
}

run_gate() {
  local gate_id="$1"
  shift
  local log_path="$report_dir/$gate_id.log"
  local start_time end_time duration status exit_code failure_code summary_path display_code
  start_time="$(date +%s)"
  printf '[QUALITY][%s] START\n' "$gate_id"

  set +e
  "$@" >"$log_path" 2>&1
  exit_code=$?
  set -e
  cat "$log_path"

  end_time="$(date +%s)"
  duration=$((end_time - start_time))
  failure_code="$(rg -o 'FAIL \[[A-Z0-9_]+\]' "$log_path" | head -1 | sed -E 's/.*\[([^]]+)\].*/\1/' || true)"
  if [[ -z "$failure_code" ]]; then
    failure_code="$gate_id"_FAILURE
  fi
  if [[ "$exit_code" -eq 0 ]]; then
    status="pass"
    printf '[QUALITY][%s] PASS\n' "$gate_id"
  else
    status="fail"
    printf '[QUALITY][%s][%s] FAIL\n' "$gate_id" "$failure_code" >&2
  fi
  write_gate_result "$gate_id" "$status" "$failure_code" "$duration" "$log_path"
  if [[ "$status" == "pass" ]]; then
    display_code="—"
  else
    display_code="$failure_code"
  fi
  summary_path="$report_dir/$gate_id.md"
  local status_label
  status_label="$(printf '%s' "$status" | tr '[:lower:]' '[:upper:]')"
  {
    printf '## Quality / %s\n\n' "$gate_id"
    printf -- '- Status: **%s**\n' "$status_label"
    printf -- '- Failure code: `%s`\n' "$display_code"
    printf -- '- Log: `%s`\n' "$log_path"
  } > "$summary_path"
  append_step_summary "$summary_path"
  return "$exit_code"
}

run_named_gate() {
  case "$1" in
    version)
      run_gate VERSION bash Scripts/validate_document_versions.sh
      ;;
    docs)
      run_gate DOCS bash -c 'bash Scripts/validate_docs.sh && python3 Scripts/Docs/audit_docs.py --check'
      ;;
    architecture)
      run_gate ARCHITECTURE bash -c 'bash Scripts/validate_build_entries.sh && bash Scripts/validate_quality_scans.sh && git diff --check'
      ;;
    tests)
      run_gate TESTS bash -c '
        set -euo pipefail
        for test_product in PToolsPlatformTests PToolsAdvancedTests; do
          swift test \
            --test-product "$test_product" \
            --enable-xctest \
            --disable-swift-testing \
            --no-parallel
        done
        for test_target in PToolsP2Tests PToolsMediaTests; do
          swift build \
            --triple arm64-apple-ios17.0-simulator \
            --target "$test_target"
        done
      '
      ;;
    concurrency)
      run_gate CONCURRENCY env PTOOLS_STRICT_CONCURRENCY=1 bash Scripts/validate_xcode_source_warnings.sh
      ;;
    pods)
      run_gate PODS bash -c '
        set -euo pipefail
        bash Scripts/validate_module_parity.sh --check
        if ! pod lib lint PooTools.podspec --allow-warnings --skip-tests; then
          printf "FAIL [PODS_LINT_FAILURE] File PooTools.podspec Expected CocoaPods lint to pass Actual pod lib lint failed or was cancelled Rule CocoaPods packaging must remain independently diagnosable\\n" >&2
          exit 1
        fi
      '
      ;;
    xcode)
      run_gate XCODE bash -c '
        set -euo pipefail
        derived_data="$QUALITY_REPORT_DIR/DerivedData"
        for configuration in Debug Release; do
          xcodebuild \
            -workspace PooTools.xcworkspace \
            -scheme PooTools-Example \
            -configuration "$configuration" \
            -sdk iphonesimulator \
            -destination "generic/platform=iOS Simulator" \
            -derivedDataPath "$derived_data" \
            -resultBundlePath "$QUALITY_REPORT_DIR/PooTools-Example-$configuration.xcresult" \
            CODE_SIGNING_ALLOWED=NO \
            ARCHS=arm64 \
            ONLY_ACTIVE_ARCH=YES \
            build
        done
        bash Scripts/CI/check_p2_modern_modules.sh
      '
      ;;
    release)
      run_gate RELEASE bash Scripts/validate_release.sh --metadata-only
      ;;
    *)
      printf 'Unknown quality gate: %s\n' "$1" >&2
      return 64
      ;;
  esac
}

write_summary() {
  ruby -rjson - "$report_dir" "$repo_root/VERSION" <<'RUBY'
require "fileutils"

# English: Summarize independent jobs without re-running their checks.
# Español: Resume trabajos independientes sin repetir sus comprobaciones.
# 中文：汇总独立任务结果，不重复执行检查。

report_dir, version_path = ARGV
required = %w[VERSION DOCS ARCHITECTURE TESTS CONCURRENCY PODS XCODE RELEASE]
results = Dir.glob(File.join(report_dir, "**", "*.json")).filter_map do |path|
  next if File.basename(path) == "quality-report.json"
  JSON.parse(File.read(path))
rescue JSON::ParserError
  nil
end
by_gate = results.to_h { |result| [result.fetch("gate"), result] }
rows = required.map do |gate|
  result = by_gate[gate]
  [gate, result ? result.fetch("status") : "not_run", result && result["failureCode"]]
end
overall = rows.all? { |(_, status, _)| status == "pass" }
version = File.read(version_path).strip

json = {
  "schemaVersion" => 1,
  "repositoryVersion" => version,
  "gates" => rows.to_h { |gate, status, code| [gate.downcase, { "status" => status, "failureCode" => code }] },
  "finalStatus" => (overall ? "pass" : "fail")
}
File.write(File.join(report_dir, "quality-report.json"), JSON.pretty_generate(json) + "\n")

markdown = [
  "## PTools Quality Summary",
  "",
  "- Version: #{version}",
  "- Final Quality: **#{overall ? "PASS" : "FAIL"}**",
  "",
  "| Gate | Status | Failure code |",
  "| --- | --- | --- |",
  *rows.map { |gate, status, code| "| #{gate} | #{status.upcase} | #{code || "—"} |" },
  ""
]
File.write(File.join(report_dir, "quality-report.md"), markdown.join("\n"))
exit(overall ? 0 : 1)
RUBY
}

case "$gate" in
  all)
    export QUALITY_REPORT_DIR="$report_dir"
    overall_status=0
    for gate_name in version docs architecture tests concurrency pods xcode release; do
      if ! "$0" "$gate_name"; then
        overall_status=1
      fi
    done
    if ! "$0" summary; then
      overall_status=1
    fi
    exit "$overall_status"
    ;;
  summary)
    if write_summary; then
      cat "$report_dir/quality-report.md"
      append_step_summary "$report_dir/quality-report.md"
      exit 0
    else
      cat "$report_dir/quality-report.md" >&2
      append_step_summary "$report_dir/quality-report.md"
      exit 1
    fi
    ;;
  version|docs|architecture|tests|concurrency|pods|xcode|release)
    run_named_gate "$gate"
    ;;
  *)
    printf 'Usage: Scripts/CI/quality_gate.sh [version|docs|architecture|tests|concurrency|pods|xcode|release|all|summary]\n' >&2
    exit 64
    ;;
esac
