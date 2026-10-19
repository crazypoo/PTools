#!/usr/bin/env bash

set -euo pipefail

# English: Require real screenshot evidence; a static page list is not visual validation.
# Español: Exige evidencia real de capturas; una lista estática de páginas no es validación visual.
# 中文：必须提供真实截图证据；静态页面清单不等于视觉验证。
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
report_path="${PTLAYOUT_VISUAL_REPORT:-$repo_root/report/layout/visual_regression_5.67.1.json}"

if [[ -n "${PTLAYOUT_VISUAL_RUNNER:-}" ]]; then
  "$PTLAYOUT_VISUAL_RUNNER"
fi

python3 - "$report_path" "$repo_root" <<'PY'
import json
import pathlib
import sys

report = pathlib.Path(sys.argv[1])
root = pathlib.Path(sys.argv[2])
if not report.is_file():
    raise SystemExit(f"FAIL: missing visual regression report: {report}")
data = json.loads(report.read_text(encoding="utf-8"))
if data.get("status") != "passed":
    raise SystemExit(f"FAIL: visual regression status is {data.get('status')!r}, not passed")
screenshots = data.get("screenshots", [])
if not screenshots:
    raise SystemExit("FAIL: visual regression report has no screenshots")
missing = [item for item in screenshots if not (root / item).is_file()]
if missing:
    raise SystemExit("FAIL: missing visual evidence: " + ", ".join(missing))
print(f"PTLayout visual regression: {len(screenshots)} screenshots passed")
PY
