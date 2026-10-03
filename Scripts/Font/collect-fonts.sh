#!/usr/bin/env bash

set -euo pipefail

# English: Keep collection inside an iOS host; macOS fonts are never used as an iOS catalog source.
# Español: Mantiene la recolección dentro de un host iOS; las fuentes de macOS nunca son fuente del catálogo iOS.
# 中文：字体采集必须在 iOS 宿主内完成，禁止把 macOS 字体当作 iOS 目录来源。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
output="${1:-$repo_root/PooToolsSource/Font/Resources/FontCatalog/runtime-fonts.json}"

cat >&2 <<'MESSAGE'
Run PTFontRuntime.snapshotJSON(runtime:) from a booted iOS Simulator host and save the returned Data to the output path.
Ejecuta PTFontRuntime.snapshotJSON(runtime:) dentro de un host iOS Simulator iniciado y guarda el Data devuelto en la ruta de salida.
请在已启动的 iOS Simulator 宿主中调用 PTFontRuntime.snapshotJSON(runtime:)，再把返回的 Data 保存到输出路径。
MESSAGE
printf 'INFO [FONT_COLLECTOR] expected output: %s\n' "$output"
printf 'INFO [FONT_COLLECTOR] formal FontCatalog.json was not modified\n'
