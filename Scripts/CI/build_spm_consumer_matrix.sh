#!/usr/bin/env bash
# English: Refresh the SwiftPM consumer matrix and never convert an absent host build into a pass.
# Español: Actualiza la matriz de consumidores de SwiftPM y nunca convierte la falta de un host en aprobado.
# 中文：刷新 SwiftPM 消费者矩阵，缺少宿主构建时绝不伪装为通过。

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"
require_build=0
if [[ "${1:-}" == "--require-build" ]]; then
  require_build=1
fi

python3 Scripts/CI/audit_spm_target_graph.py
python3 Scripts/CI/generate_spm_consumer_fixtures.py

fixture_project="${SPM_CONSUMER_FIXTURE_PROJECT:-}"
fixture_scheme="${SPM_CONSUMER_SCHEME:-}"
if [[ -z "$fixture_project" || -z "$fixture_scheme" ]]; then
  printf 'BLOCKED: set SPM_CONSUMER_FIXTURE_PROJECT and SPM_CONSUMER_SCHEME for an iOS isolated-consumer host.\n' >&2
  if [[ "$require_build" == 1 ]]; then
    exit 2
  fi
  exit 0
fi

derived_data="${SPM_CONSUMER_DERIVED_DATA:-/tmp/PTools-SPM-ConsumerDerivedData}"
for configuration in Debug Release; do
  xcodebuild -project "$fixture_project" -scheme "$fixture_scheme" \
    -configuration "$configuration" -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$derived_data/$configuration" CODE_SIGNING_ALLOWED=NO build
done

printf 'Consumer host build completed; product-level status remains tied to the fixture matrix and must be recorded by the host.\n'
