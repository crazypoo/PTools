#!/usr/bin/env bash

set -euo pipefail

# English: Keep the historical entry as a compatibility wrapper; it is not a runtime parity test.
# Español: Mantiene la entrada histórica como wrapper de compatibilidad; no es una prueba de paridad runtime.
# 中文：保留历史入口作为兼容包装器；它不是运行时差分测试。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bash "$repo_root/Scripts/CI/run_ptlayout_typecheck.sh"
