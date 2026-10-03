#!/usr/bin/env python3

# English: Ensure the deprecated freeze manifest covers the current source scan exactly.
# Español: Garantiza que el manifiesto cubra exactamente el escaneo actual del código fuente.
# 中文：确保弃用冻结清单与当前源码扫描结果完全一致。

from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "Scripts/deprecated_6_freeze_manifest.json"


def fail(message: str) -> None:
    print(f"FAIL [DEPRECATED_FREEZE] {message}", file=sys.stderr)
    raise SystemExit(1)


def scan_ids() -> set[str]:
    aliases = {
        "Network.gobalUrl",
        "Network.socketGobalUrl",
        "GobalNavControl",
        "gobalWebImageLoadOption",
        "heightlightColor",
        "netRequsetTime",
        "downloadRequsetTime",
        "pullDismissThreshod",
        "PTCoreUserDefultsWrapper",
        "BilogyID",
        "MeidaPermission",
    }
    ids: set[str] = set()
    for path in sorted((ROOT / "PooToolsSource").rglob("*.swift")):
        relative = path.relative_to(ROOT).as_posix()
        for line_number, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
            for symbol in sorted(aliases):
                if symbol in line:
                    ids.add(f"{relative}:{line_number}:{symbol}")
            if "@available" in line and "deprecated" in line:
                ids.add(f"{relative}:{line_number}:@available deprecated")
    return ids


def main() -> None:
    payload = json.loads(MANIFEST.read_text())
    if payload.get("schemaVersion") != 1 or payload.get("removalVersion") != "6.0.0":
        fail("manifest version contract is invalid")
    entries = payload.get("entries", [])
    ids = [entry.get("id") for entry in entries]
    if len(ids) != len(set(ids)):
        fail("duplicate entry id")
    required = {"id", "path", "line", "symbol", "replacement", "classification", "status", "removeIn", "migrationEvidence"}
    for entry in entries:
        missing = required - set(entry)
        if missing:
            fail(f"missing fields {sorted(missing)} for {entry.get('id')}")
        if entry["status"] != "KEEP_UNTIL_6_0" or entry["removeIn"] != "6.0.0":
            fail(f"invalid freeze status for {entry['id']}")
        if entry["classification"] not in {"ALIAS", "DEPRECATED_API", "GENERATED_COMPATIBILITY"}:
            fail(f"invalid classification for {entry['id']}")
        source = ROOT / entry["path"]
        if not source.exists():
            fail(f"source file missing for {entry['id']}")

    expected = scan_ids()
    actual = set(ids)
    if expected != actual:
        missing = sorted(expected - actual)
        extra = sorted(actual - expected)
        fail(f"source scan drift; missing={missing[:5]} extra={extra[:5]}")
    print(f"PASS [DEPRECATED_FREEZE] entries={len(entries)}")


if __name__ == "__main__":
    main()
