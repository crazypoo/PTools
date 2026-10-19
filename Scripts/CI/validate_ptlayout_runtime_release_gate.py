#!/usr/bin/env python3
# English: Fail release when any PTLayout runtime or visual case is missing, skipped, or not passed.
# Español: Bloquea la publicación cuando falta, se omite o falla cualquier caso runtime o visual de PTLayout.
# 中文：任何 PTLayout 运行时或视觉案例缺失、跳过或失败时阻断发布。

from __future__ import annotations

import argparse
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--execution-report", required=True)
    parser.add_argument("--visual-report", required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    failures: list[str] = []

    execution_path = root / args.execution_report
    visual_path = root / args.visual_report
    if not execution_path.is_file():
        failures.append(f"missing execution report: {args.execution_report}")
    if not visual_path.is_file():
        failures.append(f"missing visual report: {args.visual_report}")
    if failures:
        for failure in failures:
            print("FAIL: " + failure)
        return 1

    execution = json.loads(execution_path.read_text(encoding="utf-8"))
    rows = execution.get("cases", [])
    expected = [f"F{index:02d}" for index in range(1, 57)]
    actual = [row.get("case_id") for row in rows]
    if actual != expected:
        failures.append("runtime report must contain F01-F56 exactly once and in order")
    for row in rows:
        for field in ("runtime_test_name", "simulator", "os", "xcresult_path"):
            if not row.get(field):
                failures.append(f"runtime evidence missing {field}: {row.get('case_id')}")
        if row.get("ran") is not True or row.get("passed") is not True:
            failures.append(f"runtime case not passed: {row.get('case_id')}")
        result = root / row.get("xcresult_path", "missing")
        if not result.exists():
            failures.append(f"runtime xcresult missing: {row.get('case_id')}")

    visual = json.loads(visual_path.read_text(encoding="utf-8"))
    if visual.get("status") != "passed":
        failures.append(f"visual regression status is {visual.get('status')!r}")
    for screenshot in visual.get("screenshots", []):
        if not (root / screenshot).is_file():
            failures.append(f"visual screenshot missing: {screenshot}")
    if not visual.get("screenshots"):
        failures.append("visual regression has no screenshots")

    if failures:
        for failure in failures:
            print("FAIL: " + failure)
        return 1
    print("PASS: PTLayout runtime and visual release gate")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
