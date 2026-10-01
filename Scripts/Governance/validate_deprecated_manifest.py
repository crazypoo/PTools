#!/usr/bin/env python3

# English: Validate deprecated compatibility entries without scan-required placeholders.
# Español: Valida las entradas de compatibilidad obsoletas sin placeholders de escaneo pendiente.
# 中文：校验弃用兼容入口，禁止遗留待扫描占位符。

from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "Scripts/deprecated_6_removal_manifest.json"


def fail(message: str) -> None:
    print(f"FAIL [DEPRECATED_MANIFEST] {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    payload = json.loads(MANIFEST.read_text())
    required = {"symbol", "replacement", "internalUsage", "exampleUsage", "testsUsage", "canonicalReplacementExists", "compatibilityForwarding", "migrationDoc", "consumerEvidence", "removeIn"}
    for entry in payload.get("entries", []):
        missing = required - set(entry)
        if missing:
            fail(f"missing fields {sorted(missing)} for {entry.get('symbol')}")
        text = json.dumps(entry, ensure_ascii=False).lower()
        if any(marker in text for marker in ("scan required", "unknown", "tbd")):
            fail(f"placeholder remains for {entry['symbol']}")
        if entry["removeIn"] != "6.0.0":
            fail(f"removeIn must be 6.0.0 for {entry['symbol']}")
        if not entry["migrationDoc"] or not entry["consumerEvidence"]:
            fail(f"missing migration evidence for {entry['symbol']}")
    print(f"PASS [DEPRECATED_MANIFEST] entries={len(payload.get('entries', []))}")


if __name__ == "__main__":
    main()
