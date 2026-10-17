#!/usr/bin/env bash
# English: Validate a generated manifest without requiring ripgrep or a UIKit build.
# Español: Valida un manifest generado sin exigir ripgrep ni una compilación UIKit.
# 中文：验证已生成清单，不依赖 ripgrep，也不要求先编译 UIKit。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST_PATH="${PT_ACK_MANIFEST:-${1:-${DERIVED_FILE_DIR:-$ROOT_DIR/.build/acknowledgements}/PTAcknowledgements.json}}"

if [[ ! -f "$MANIFEST_PATH" ]]; then
  echo "清单不存在: $MANIFEST_PATH / Manifest ausente / Manifest missing" >&2
  exit 1
fi

cd "$ROOT_DIR"
swift run --disable-sandbox --package-path "$ROOT_DIR" pt-acknowledgements validate --manifest "$MANIFEST_PATH" --strict
