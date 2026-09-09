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
bash Scripts/validate_deprecated_inventory.sh
ruby Scripts/compare_public_api.rb PUBLIC_API_5_8.json PUBLIC_API_5_9.json
bash Scripts/validate_build_entries.sh
bash Scripts/validate_quality_scans.sh
swift package dump-package >/dev/null
git diff --check

for report in \
  report/concurrency_5_9.md \
  report/singletons_5_9.md \
  report/cache_inventory_5_9.md \
  report/accessibility_5_9.md; do
  [[ -f "$report" ]] || {
    printf 'FAIL: required 5.9 report is missing: %s\n' "$report" >&2
    exit 1
  }
done

printf 'PASS: 5.9.x source and migration contracts\n'
