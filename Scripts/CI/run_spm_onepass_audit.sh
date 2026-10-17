#!/usr/bin/env bash
# English: Run the complete SwiftPM one-pass inventory, ownership, consumer, and gate preparation.
# Español: Ejecuta el inventario, la propiedad, los consumidores y la preparación de la puerta SwiftPM en una pasada.
# 中文：一键执行 SwiftPM 清单、归属、消费者和门禁准备。

set -uo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
mode="inventory-only"
configurations="Debug,Release"
product=""
changed_only=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --inventory-only) mode="inventory-only" ;;
    --build-all) mode="build-all" ;;
    --configurations) configurations="${2:-Debug,Release}"; shift ;;
    --product) product="${2:-}"; shift ;;
    --changed-only) changed_only=1 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

onepass="report/spm/onepass"
mkdir -p "$onepass"
version="$(tr -d '[:space:]' < VERSION)"
{
  echo "version=$version"
  echo "sha=$(git rev-parse HEAD 2>/dev/null || printf working-tree)"
  xcodebuild -version | sed 's/^/xcode=/'
  echo "swift=$(swift --version | head -1)"
  echo "ios_simulator_sdk=$(xcrun --sdk iphonesimulator --show-sdk-version 2>/dev/null || printf unknown)"
  echo "host=$(uname -a)"
} > "$onepass/environment.txt"

set +e
swift package dump-package > "$onepass/manifest.json"
manifest_rc=$?
swift package describe --type json > "$onepass/package-description.json"
describe_rc=$?
python3 Scripts/CI/audit_spm_target_graph.py --strict
graph_rc=$?
python3 Scripts/CI/audit_spm_symbol_ownership.py --strict
symbol_rc=$?
python3 Scripts/CI/audit_spm_conditional_compilation.py
conditional_rc=$?
python3 Scripts/CI/audit_spm_resources.py
resources_rc=$?
python3 Scripts/CI/audit_spm_api_surface.py --strict
api_rc=$?
python3 Scripts/CI/generate_spm_consumer_fixtures.py
fixture_rc=$?
ruby Scripts/CI/generate_spm_consumer_host.rb
host_rc=$?
python3 Scripts/CI/generate_spm_onepass_reports.py
reports_rc=$?
set -e

build_rc=0
if [[ "$mode" == "build-all" ]]; then
  args=(--require-build --configurations "$configurations")
  [[ -n "$product" ]] && args+=(--product "$product")
  [[ "$changed_only" == 1 ]] && args+=(--changed-only)
  set +e
  bash Scripts/CI/build_spm_consumer_matrix.sh "${args[@]}"
  build_rc=$?
  set -e
fi
python3 Scripts/CI/merge_spm_diagnostics.py
merge_rc=$?

cat > "$onepass/summary.md" <<EOF
# SwiftPM one-pass audit $version

- manifest: $manifest_rc
- package description: $describe_rc
- target graph: $graph_rc
- symbol ownership: $symbol_rc
- conditional compilation: $conditional_rc
- resources: $resources_rc
- API surface: $api_rc
- fixtures: $fixture_rc
- consumer host: $host_rc
- one-pass reports: $reports_rc
- consumer matrix: $build_rc
- diagnostic merge: $merge_rc

\`not_run\` is not a pass. BaboBuy/YD1688 is an external consumer and is not included in this repository.
EOF

for rc in "$manifest_rc" "$describe_rc" "$graph_rc" "$symbol_rc" "$conditional_rc" "$resources_rc" "$api_rc" "$fixture_rc" "$host_rc" "$reports_rc" "$build_rc" "$merge_rc"; do
  [[ "$rc" -ne 0 ]] && exit 1
done
exit 0
