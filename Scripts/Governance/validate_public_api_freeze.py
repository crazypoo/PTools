#!/usr/bin/env python3

# English: Require every current public declaration to have an explicit stability class.
# Español: Exige una clase de estabilidad explícita para cada declaración pública actual.
# 中文：要求当前每个公开声明都具备明确的稳定性分类。

from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "report/current/public_api.json"
CLASSIFICATION = ROOT / "Scripts/public_api_classification.json"


def fail(message: str) -> None:
    print(f"FAIL [PUBLIC_API_FREEZE] {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    report = json.loads(REPORT.read_text())
    manifest = json.loads(CLASSIFICATION.read_text())
    if manifest.get("schemaVersion") != 1:
        fail("classification schemaVersion must be 1")
    allowed = {"canonical", "compatibility", "experimental", "internal"}
    current = {f"{entry['key']}@{entry['line']}" for entry in report.get("declarations", [])}
    entries = manifest.get("classifications", [])
    classified = set()
    for entry in entries:
        required = {"symbol", "module", "category", "replacement", "owner", "since", "removeIn"}
        missing = required - set(entry)
        if missing:
            fail(f"missing fields {sorted(missing)} in {entry}")
        if entry["category"] not in allowed:
            fail(f"unknown category {entry['category']} for {entry['symbol']}")
        if entry["symbol"] in classified:
            fail(f"duplicate classification {entry['symbol']}")
        classified.add(entry["symbol"])
        if entry["category"] == "compatibility" and (not entry["replacement"] or entry["removeIn"] != "6.0.0"):
            fail(f"compatibility symbol lacks migration metadata: {entry['symbol']}")
    missing = sorted(current - classified)
    orphan = sorted(classified - current)
    if missing:
        fail("unclassified public API: " + ", ".join(missing[:10]))
    if orphan:
        fail("orphan public API classifications: " + ", ".join(orphan[:10]))
    print(f"PASS [PUBLIC_API_FREEZE] classified={len(classified)}")


if __name__ == "__main__":
    main()
