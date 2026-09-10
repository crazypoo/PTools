#!/usr/bin/env bash

set -euo pipefail

# English: Run the deterministic 5.8.x packaging, dependency, and architecture contract gates.
# Español: Ejecuta las puertas deterministas de empaquetado, dependencias y arquitectura de 5.8.x.
# 中文：执行 5.8.x 的可重复打包、依赖和架构契约门禁。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mode="--check"
if [[ "${1:-}" == "--update" ]]; then
  mode="--update"
elif [[ "${1:-}" != "" && "${1:-}" != "--check" ]]; then
  printf 'Usage: %s [--check|--update]\n' "${BASH_SOURCE[0]}" >&2
  exit 2
fi

cd "$repo_root"
ruby Scripts/report_spm_dependency_graph.rb
ruby Scripts/report_cocoapods_subspec_graph.rb
bash Scripts/validate_module_parity.sh "$mode"
bash Scripts/validate_dependency_direction.sh
bash Scripts/validate_permission_source_contract.sh
bash Scripts/validate_file_size_gate.sh
ruby Scripts/report_sendable_exceptions.rb
ruby Scripts/report_public_api_5_8.rb
swift package dump-package >/dev/null
git diff --check
for report in \
  ARCHITECTURE_5_8.md \
  DEPENDENCY_GRAPH_5_8.md \
  PUBLIC_API_5_8.json \
  SENDABLE_EXCEPTIONS_5_8.md \
  PERFORMANCE_BASELINE_5_8.md \
  report/build_validation_5_8_9.md; do
  [[ -f "$report" ]] || {
    printf 'FAIL: required 5.8.9 report is missing: %s\n' "$report" >&2
    exit 1
  }
done
printf 'PASS: 5.8.x dependency, architecture, and packaging contracts\n'
