#!/usr/bin/env bash

set -euo pipefail

# English: Run static, runtime, visual, and migration gates; NOT_RUN is never a release pass.
# Español: Ejecuta las puertas estáticas, runtime, visuales y de migración; NOT_RUN nunca es un pase de publicación.
# 中文：执行静态、运行时、视觉和迁移门禁；NOT_RUN 永远不能作为发布通过。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
python3 "$repo_root/Scripts/CI/validate_layout_negative_fixtures_567.py" --execution-report report/layout/runtime_parity_5.67.1.json
python3 "$repo_root/Scripts/CI/validate_layout_source_ownership_567.py"
python3 "$repo_root/Scripts/CI/validate_layout_no_snapkit_dependency_567.py"
python3 "$repo_root/Scripts/CI/validate_layout_demo_catalog_567.py"
python3 "$repo_root/Scripts/CI/audit_layout_567.py"
python3 "$repo_root/Scripts/CI/validate_ptlayout_migration_scope.py"
bash "$repo_root/Scripts/CI/run_ptlayout_typecheck.sh"
python3 "$repo_root/Scripts/CI/validate_ptlayout_runtime_release_gate.py" \
  --execution-report report/layout/runtime_parity_5.67.1.json \
  --visual-report report/layout/visual_regression_5.67.1.json
python3 "$repo_root/Scripts/CI/validate_spm_release_gate.py"
git -C "$repo_root" diff --check
printf 'PTLayout 5.67.1 release gates: static, runtime, visual, and consumer evidence passed\n'
