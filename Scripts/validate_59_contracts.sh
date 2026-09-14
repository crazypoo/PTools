#!/usr/bin/env bash

set -euo pipefail

# English: Run deterministic source, package, API, lifecycle, cache, and migration gates for 5.9.x.
# Español: Ejecuta puertas deterministas de código, paquete, API, ciclo de vida, caché y migración de 5.9.x.
# 中文：执行 5.9.x 的源码、包、API、生命周期、缓存和迁移确定性门禁。
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

ruby Scripts/report_public_api_5_9.rb
ruby Scripts/report_concurrency_5_9.rb
ruby Scripts/report_singletons_5_9.rb
ruby Scripts/report_cache_inventory_5_9.rb
ruby Scripts/report_accessibility_5_9.rb
bash Scripts/validate_branch_dependencies.sh
bash Scripts/validate_dependencies_5_9_6.sh
bash Scripts/validate_migration_5_9_7.sh
bash Scripts/validate_deprecated_inventory.sh

# English: Historical API snapshots document evolution; they are not an exact-equality gate for the current checkout.
# Español: Las instantáneas históricas documentan la evolución; no son una puerta de igualdad exacta para el checkout actual.
# 中文：历史 API 快照用于记录演进，不应要求当前代码与 5.8/5.9 快照完全相等。
for snapshot in \
  report/baselines/5.8/public_api.json \
  report/baselines/5.9/public_api.json \
  report/current/public_api.json; do
  [[ -s "$snapshot" ]] || {
    printf 'FAIL: required API snapshot is missing: %s\n' "$snapshot" >&2
    exit 1
  }
done
bash Scripts/validate_build_entries.sh
bash Scripts/validate_quality_scans.sh
bash Scripts/validate_592_quality.sh
bash Scripts/validate_lifecycle_5_9.sh
swift package dump-package >/dev/null
git diff --check

for report in \
  report/current/concurrency.md \
  report/current/singletons.md \
  report/current/cache_inventory.md \
  report/current/accessibility.md; do
  [[ -f "$report" ]] || {
    printf 'FAIL: required 5.9 report is missing: %s\n' "$report" >&2
    exit 1
  }
done

printf 'PASS: 5.9.x source and migration contracts\n'
