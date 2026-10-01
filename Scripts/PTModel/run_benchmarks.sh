#!/usr/bin/env bash
set -euo pipefail

# English: Run the real PTModel benchmark target and keep the output machine-readable.
# Español: Ejecuta el target real de benchmark PTModel y conserva una salida legible por máquinas.
# 中文：运行真实的 PTModel 基准测试 target，并保留机器可读输出。

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
count="${PTMODEL_BENCHMARK_COUNT:-1000}"
iterations="${PTMODEL_BENCHMARK_ITERATIONS:-5}"
configuration="${PTMODEL_BENCHMARK_CONFIGURATION:-debug}"

cd "$repo_root"
exec swift run -c "$configuration" PTModelBenchmark --count "$count" --iterations "$iterations"
