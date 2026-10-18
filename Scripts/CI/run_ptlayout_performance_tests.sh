#!/usr/bin/env bash

set -euo pipefail

# English: Produce an honest benchmark placeholder until the same engines run on one host.
# Español: Produce un registro honesto hasta ejecutar los mismos motores en un host.
# 中文：在三套引擎于同一环境运行前，只生成诚实的待测记录。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
python3 "$repo_root/Scripts/CI/audit_layout_567.py" --mode performance
printf 'PTLayout performance: instrumentation is present; no unmeasured speed claim was made\n'
