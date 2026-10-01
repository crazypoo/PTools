#!/usr/bin/env bash

set -euo pipefail

# English: Rebuild current reports from real generators without touching the working tree in check mode.
# Español: Reconstruye los informes actuales desde generadores reales sin tocar el árbol en modo check.
# 中文：通过真实生成器重建 current 报告，check 模式绝不修改工作区。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

mode="${1:---check}"
case "$mode" in
  --check|--write) ;;
  *) printf 'Usage: %s [--check|--write]\n' "$0" >&2; exit 64 ;;
esac

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/ptools-current-reports.XXXXXX")"
tmp_reports="$tmp_root/current"
mkdir -p "$tmp_reports"

cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

# English: Start from committed reports so non-generator historical inventories remain visible.
# Español: Parte de los informes versionados para conservar inventarios históricos no generados.
# 中文：从已提交的报告开始，保留没有独立生成器的历史清单。
if [[ -d report/current ]]; then
  cp -R report/current/. "$tmp_reports/"
fi

export PTOOLS_REPORT_DIR="$tmp_reports"

ruby Scripts/report_concurrency.rb
ruby Scripts/report_sendable_exceptions.rb
ruby Scripts/report_mainactor_heavy_work.rb
ruby Scripts/report_cache_inventory.rb
ruby Scripts/report_singletons.rb
ruby Scripts/report_accessibility.rb
ruby Scripts/report_public_api.rb
ruby Scripts/report_spm_dependency_graph.rb
ruby Scripts/report_cocoapods_subspec_graph.rb
bash Scripts/validate_file_size_gate.sh
bash Scripts/validate_module_parity.sh --update
bash Scripts/validate_dependency_direction.sh
python3 Scripts/Governance/generate_runtime_validation_report.py
ruby Scripts/report_current_summaries.rb
ruby Scripts/Governance/generate_current_reports.rb

if [[ "$mode" == "--write" ]]; then
  rm -rf report/current
  mkdir -p report/current
  cp -R "$tmp_reports"/. report/current/
  printf 'PASS [CURRENT_REPORT_REGENERATED] %s\n' "$(ruby Scripts/Governance/source_inputs_digest.rb)"
  exit 0
fi

ruby Scripts/Governance/compare_current_reports.rb report/current "$tmp_reports"
printf 'PASS [CURRENT_REPORT_REPRODUCIBLE] %s\n' "$(ruby Scripts/Governance/source_inputs_digest.rb)"
