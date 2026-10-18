#!/usr/bin/env python3
# English: Assert that the named F01-F56 failure contract remains complete.
# Español: Comprueba que el contrato nombrado F01-F56 siga completo.
# 中文：断言 F01-F56 具名故障契约保持完整。
import json
from pathlib import Path

root = Path(__file__).resolve().parents[2]
fixture = root / "Scripts/CI/fixtures/PTLayoutFailureInjectionCases_567.json"
cases = json.loads(fixture.read_text(encoding="utf-8"))
expected = [f"F{index:02d}" for index in range(1, 57)]
actual = [case.get("id") for case in cases]
if actual != expected:
    raise SystemExit("F01-F56 fixture contract is incomplete or out of order")
print(f"PTLayout negative fixtures: {len(cases)}/56 registered")
