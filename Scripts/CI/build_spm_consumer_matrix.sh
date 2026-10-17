#!/usr/bin/env bash
# English: Build each applicable SwiftPM product in an independent iOS host target.
# Español: Compila cada producto SwiftPM aplicable en un target host iOS independiente.
# 中文：在独立 iOS 宿主 target 中逐个构建所有适用的 SwiftPM product。

set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
require_build=0
product_filter=""
changed_only=0
configurations=(Debug Release)
host_project="Tests/SPMConsumerHost/SPMConsumerHost.xcodeproj"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --require-build) require_build=1 ;;
    --product) product_filter="${2:-}"; shift ;;
    --changed-only) changed_only=1 ;;
    --configurations) IFS=',' read -r -a configurations <<< "${2:-Debug,Release}"; shift ;;
    --host-project) host_project="${2:-}"; shift ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

python3 Scripts/CI/audit_spm_target_graph.py >/tmp/ptools-spm-graph.log 2>&1
graph_rc=$?
python3 Scripts/CI/generate_spm_consumer_fixtures.py >/tmp/ptools-spm-fixtures.log 2>&1
fixture_rc=$?
ruby Scripts/CI/generate_spm_consumer_host.rb >/tmp/ptools-spm-host.log 2>&1
host_rc=$?
if [[ $graph_rc -ne 0 || $fixture_rc -ne 0 || $host_rc -ne 0 ]]; then
  cat /tmp/ptools-spm-graph.log /tmp/ptools-spm-fixtures.log /tmp/ptools-spm-host.log >&2
  exit 2
fi

matrix_dir="$repo_root/report/spm/onepass/consumer"
mkdir -p "$matrix_dir"
index_path="$repo_root/Tests/SPMConsumerFixtures/Generated/ProductIndex.json"
version="$(tr -d '[:space:]' < VERSION)"
sha="$(git rev-parse HEAD 2>/dev/null || printf 'working-tree')"
xcode_version="$(xcodebuild -version | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g')"
sdk_version="$(xcrun --sdk iphonesimulator --show-sdk-version 2>/dev/null || printf 'unknown')"
dependency_hash="$(shasum -a 256 Package.swift Package.resolved 2>/dev/null | shasum -a 256 | awk '{print $1}')"
source_hash="$(git diff --no-ext-diff --binary | shasum -a 256 | awk '{print $1}')"

python3 - "$index_path" "$product_filter" "$changed_only" <<'PY' > /tmp/ptools-spm-products.tsv
import json, subprocess, sys
index = json.load(open(sys.argv[1]))
name_filter = {item for item in sys.argv[2].split(",") if item}
changed_only = sys.argv[3] == "1"
changed = subprocess.run(["git", "diff", "--name-only", "HEAD"], text=True, capture_output=True).stdout.splitlines()
changed_text = "\n".join(changed)
for item in index:
    if item["kind"] != "library":
        continue
    if name_filter and item["product"] not in name_filter:
        continue
    if changed_only and item["product"] not in changed_text and not any(target in changed_text for target in item["targets"]):
        continue
    print("\t".join([item["product"], item["targetName"], ";".join(item["modules"])]))
PY

rows_file="$(mktemp /tmp/ptools-spm-matrix.XXXXXX)"
trap 'rm -f "$rows_file"' EXIT
for configuration in "${configurations[@]}"; do
  rm -rf "$matrix_dir/DerivedData-$configuration"
done
while IFS=$'\t' read -r product target modules; do
  [[ -z "$product" ]] && continue
  for configuration in "${configurations[@]}"; do
    safe_product="${product//[^A-Za-z0-9_]/_}"
    safe_config="${configuration//[^A-Za-z0-9_]/_}"
    output_dir="$matrix_dir/$safe_product"
    mkdir -p "$output_dir"
    log_path="$output_dir/$safe_config.log"
    result_path="$output_dir/$safe_config.xcresult"
    derived_path="$matrix_dir/DerivedData-$safe_config"
    rm -rf "$result_path"
    set +e
    build_selector=(-scheme "$target")
    if [[ "$product" == "PooToolsNetwork" ]]; then
      # English: Use the generated scheme for the legacy spelling so -derivedDataPath remains valid.
      # Español: Usa el scheme generado para la grafía heredada y mantiene válido -derivedDataPath.
      # 中文：使用旧拼写对应的生成 scheme，确保 -derivedDataPath 参数有效。
      build_selector=(-scheme "SPMConsumer_$target")
    fi
    xcodebuild -project "$host_project" "${build_selector[@]}" -configuration "$configuration" \
      -destination 'generic/platform=iOS Simulator' -derivedDataPath "$derived_path" \
      -resultBundlePath "$result_path" ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
      CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build >"$log_path" 2>&1
    build_rc=$?
    set -e
    status="failed"
    if [[ $build_rc -eq 0 && -d "$derived_path/Build/Products/$configuration-iphonesimulator" ]]; then
      status="pass"
    elif grep -qE 'unable to resolve module dependency|Unable to resolve module dependency|No such module' "$log_path"; then
      status="blocked"
    fi
    diagnostics="$(grep -cE ' error: |fatal error:|warning: ' "$log_path" || true)"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$sha" "$version" "$xcode_version" "$sdk_version" "iOS Simulator" "$product" "$modules" "library" "$configuration" "$dependency_hash" "$source_hash" "$status" "$diagnostics" "${log_path#$repo_root/}" "${result_path#$repo_root/}" >> "$rows_file"
    printf '%-42s %-7s %s\n' "$product" "$configuration" "$status"
  done
done < /tmp/ptools-spm-products.tsv

python3 - "$rows_file" "$repo_root/report/spm/spm_product_matrix.csv" <<'PY'
import csv, sys
columns = ["sha","version","xcode","ios_sdk","platform","product","module","product_kind","configuration","dependency_hash","source_hash","status","diagnostics_count","log_path","xcresult_path"]
rows = []
with open(sys.argv[1]) as handle:
    for line in handle:
        values = line.rstrip("\n").split("\t")
        if len(values) == len(columns):
            rows.append(dict(zip(columns, values)))
with open(sys.argv[2], "w", newline="") as handle:
    writer = csv.DictWriter(handle, fieldnames=columns, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
PY

failed_count="$(awk -F, 'NR > 1 && $12 != "pass" {n++} END {print n+0}' report/spm/spm_product_matrix.csv)"
if [[ "$require_build" == 1 && "$failed_count" -ne 0 ]]; then
  echo "FAIL: consumer matrix has $failed_count non-pass rows" >&2
  exit 1
fi
exit 0
