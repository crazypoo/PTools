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
    required = {
        "symbol", "replacement", "kind", "internalUsage", "declarationCount", "declarationLocations",
        "exampleUsage", "testsUsage", "canonicalReplacementExists", "canonicalEvidence",
        "compatibilityForwarding", "migrationDoc", "consumerEvidence", "removeIn"
    }
    allowed_kinds = {"swiftSymbol", "moduleAlias", "productAlias", "subspecAlias"}
    for entry in payload.get("entries", []):
        missing = required - set(entry)
        if missing:
            fail(f"missing fields {sorted(missing)} for {entry.get('symbol')}")
        text = json.dumps(entry, ensure_ascii=False).lower()
        if any(marker in text for marker in ("scan required", "unknown", "tbd")):
            fail(f"placeholder remains for {entry['symbol']}")
        if entry["removeIn"] != "6.0.0":
            fail(f"removeIn must be 6.0.0 for {entry['symbol']}")
        if entry["kind"] not in allowed_kinds:
            fail(f"unsupported kind {entry['kind']} for {entry['symbol']}")
        if not isinstance(entry["declarationCount"], int) or entry["declarationCount"] < 0:
            fail(f"invalid declarationCount for {entry['symbol']}")
        if not isinstance(entry["declarationLocations"], list) or not isinstance(entry["canonicalEvidence"], list):
            fail(f"invalid declaration/evidence fields for {entry['symbol']}")
        if entry["internalUsage"].get("count") != 0:
            # English: Internal compatibility call-sites must be migrated before the 6.0 removal window.
            # Español: Las llamadas internas de compatibilidad deben migrarse antes de la ventana de eliminación 6.0.
            # 中文：内部兼容调用点必须在 6.0 删除窗口前迁移完成。
            fail(f"internal call-sites remain for {entry['symbol']}: {entry['internalUsage']}")
        if not entry["canonicalReplacementExists"] or not entry["canonicalEvidence"]:
            fail(f"canonical replacement evidence is missing for {entry['symbol']}")
        if entry["kind"] in {"moduleAlias", "productAlias", "subspecAlias"} and not entry["compatibilityForwarding"]:
            fail(f"module/product alias forwarding evidence is missing for {entry['symbol']}")
        if not entry["migrationDoc"] or not entry["consumerEvidence"]:
            fail(f"missing migration evidence for {entry['symbol']}")
    print(f"PASS [DEPRECATED_MANIFEST] entries={len(payload.get('entries', []))}")


if __name__ == "__main__":
    main()
