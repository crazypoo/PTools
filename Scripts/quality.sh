#!/usr/bin/env bash

set -euo pipefail

# English: Keep one local entry point identical to the CI quality implementation.
# Español: Mantiene un único punto de entrada local idéntico a la implementación de CI.
# 中文：让本地入口与 CI 使用同一套质量实现。

script_dir="$(cd "$(dirname "$0")" && pwd)"
exec "$script_dir/CI/quality_gate.sh" "$@"
