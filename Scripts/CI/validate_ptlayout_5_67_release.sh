#!/usr/bin/env bash

set -euo pipefail

# English: Run the deterministic static gates for PTLayout 5.67 before Xcode runtime gates.
# Español: Ejecuta las puertas estáticas deterministas antes de las puertas runtime de Xcode.
# 中文：在 Xcode 运行时门禁前执行 PTLayout 5.67 的确定性静态门禁。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
python3 "$repo_root/Scripts/CI/validate_layout_negative_fixtures_567.py"
python3 "$repo_root/Scripts/CI/validate_layout_source_ownership_567.py"
python3 "$repo_root/Scripts/CI/validate_layout_no_snapkit_dependency_567.py"
python3 "$repo_root/Scripts/CI/validate_layout_demo_catalog_567.py"
python3 "$repo_root/Scripts/CI/audit_layout_567.py"
bash "$repo_root/Scripts/CI/run_ptlayout_differential_tests.sh"
git -C "$repo_root" diff --check
printf 'PTLayout 5.67 static release gates: passed; Xcode Debug/Release and external host runtime remain explicit gates\n'
