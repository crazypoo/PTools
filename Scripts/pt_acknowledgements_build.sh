#!/usr/bin/env bash
# English: Generate the offline acknowledgement manifest during the host build.
# Español: Genera el manifest offline de acknowledgements durante la compilación del host.
# 中文：在宿主构建阶段生成离线许可证致谢清单。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${DERIVED_FILE_DIR:-$ROOT_DIR/.build/acknowledgements}"
OUTPUT_PATH="$OUTPUT_DIR/PTAcknowledgements.json"
REPORT_PATH="$OUTPUT_DIR/PTAcknowledgements.report.json"
PACKAGE_RESOLVED="${PT_ACK_PACKAGE_RESOLVED:-$ROOT_DIR/Package.resolved}"
PODFILE_LOCK="${PT_ACK_PODFILE_LOCK:-$ROOT_DIR/Podfile.lock}"

command -v swift >/dev/null 2>&1 || {
  echo "swift 不可用 / Swift no está disponible / Swift is unavailable" >&2
  exit 1
}

args=(generate --output "$OUTPUT_PATH" --report "$REPORT_PATH")
input_count=0
if [[ -f "$PACKAGE_RESOLVED" ]]; then
  args+=(--resolved "$PACKAGE_RESOLVED")
  input_count=$((input_count + 1))
fi
if [[ -f "$PODFILE_LOCK" ]]; then
  args+=(--podfile-lock "$PODFILE_LOCK")
  input_count=$((input_count + 1))
fi
if [[ -n "${PT_ACK_OVERRIDES:-}" && -f "$PT_ACK_OVERRIDES" ]]; then
  args+=(--overrides "$PT_ACK_OVERRIDES")
fi
if [[ "${PT_ACK_ALLOW_NETWORK:-0}" == "1" ]]; then
  args+=(--allow-network)
fi

if [[ "$input_count" -eq 0 ]]; then
  echo "找不到 Package.resolved 或 Podfile.lock / No se encontró Package.resolved ni Podfile.lock / Neither input lockfile was found" >&2
  exit 1
fi

cd "$ROOT_DIR"
swift run --disable-sandbox --package-path "$ROOT_DIR" pt-acknowledgements "${args[@]}"
