#!/usr/bin/env python3

# English: Verify that every reported UI/scene singleton has an explicit ownership decision.
# Español: Verifica que cada singleton de UI/escena tenga una decisión explícita de ownership.
# 中文：校验报告中的每个 UI/场景单例都具有明确的所有权决策。

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "report/current/singletons.json"
MANIFEST = ROOT / "Scripts/ui_singleton_ownership.json"


def fail(message: str) -> None:
    print(f"FAIL [UI_SINGLETON_OWNERSHIP] {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    report = json.loads(REPORT.read_text())
    manifest = json.loads(MANIFEST.read_text())
    if manifest.get("schemaVersion") != 1:
        fail("unsupported manifest schema")

    entries = manifest.get("entries", [])
    by_symbol = {entry.get("symbol"): entry for entry in entries}
    if len(by_symbol) != len(entries):
        fail("duplicate singleton symbols in manifest")

    expected_paths: Counter[str] = Counter()
    for declaration in report.get("declarations", []):
        if declaration.get("category") != "D":
            continue
        path = declaration["path"]
        expected_paths[path] += 1

    actual_paths: Counter[str] = Counter()
    for symbol, entry in by_symbol.items():
        path = entry.get("path")
        actual_paths[path] += 1
        if not entry.get("ownership") or not entry.get("instanceEntryPoint"):
            fail(f"incomplete ownership decision for {symbol}")
        if not entry.get("sharedCompatibility"):
            fail(f"shared compatibility policy missing for {symbol}")
        if entry.get("migrationStatus") not in {"READY", "DOCUMENTED"}:
            fail(f"invalid migration status for {symbol}")

    if actual_paths != expected_paths:
        fail(f"path coverage mismatch: expected={dict(expected_paths)} actual={dict(actual_paths)}")
    print(f"PASS [UI_SINGLETON_OWNERSHIP] decisions={sum(expected_paths.values())}")


if __name__ == "__main__":
    main()
