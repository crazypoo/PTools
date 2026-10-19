#!/usr/bin/env python3
# English: Assert that the named F01-F56 failure contract remains complete.
# Español: Comprueba que el contrato nombrado F01-F56 siga completo.
# 中文：断言 F01-F56 具名故障契约保持完整。
import json
import argparse
from pathlib import Path

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument("--execution-report", help="optional runtime mapping report; does not mark cases passed")
args = parser.parse_args()
fixture = root / "Scripts/CI/fixtures/PTLayoutFailureInjectionCases_567.json"
cases = json.loads(fixture.read_text(encoding="utf-8"))
expected = [f"F{index:02d}" for index in range(1, 57)]
actual = [case.get("id") for case in cases]
if actual != expected:
    raise SystemExit("F01-F56 fixture contract is incomplete or out of order")
print(f"PTLayout negative fixtures: {len(cases)}/56 registered")
if args.execution_report:
    report = root / args.execution_report
    if not report.is_file():
        raise SystemExit(f"runtime execution report is missing: {args.execution_report}")
    execution = json.loads(report.read_text(encoding="utf-8"))
    mapped = [row.get("case_id") for row in execution.get("cases", [])]
    if mapped != expected:
        raise SystemExit("runtime execution report is not mapped to F01-F56")
    print("PTLayout negative fixtures: runtime mapping present; pass/fail remains a separate gate")
