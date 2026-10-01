#!/usr/bin/env python3

# English: Replace placeholder deprecated-entry usage fields with reproducible source scans.
# Español: Sustituye los campos placeholder de APIs obsoletas por escaneos reproducibles.
# 中文：用可重复的源码扫描替换弃用条目中的占位字段。

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "Scripts/deprecated_6_removal_manifest.json"


def occurrences(pattern: str, roots: list[Path]) -> list[str]:
    matches: list[str] = []
    for root in roots:
        if not root.exists():
            continue
        for path in sorted(root.rglob("*.swift")):
            for number, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
                if pattern in line:
                    matches.append(f"{path.relative_to(ROOT)}:{number}")
    return matches


def main() -> None:
    payload = json.loads(MANIFEST.read_text())
    for entry in payload.get("entries", []):
        symbol = entry["symbol"]
        replacement = entry["replacement"]
        internal = occurrences(symbol, [ROOT / "PooToolsSource"])
        example = occurrences(symbol, [ROOT / "PooTools-Example"])
        tests = occurrences(symbol, [ROOT / "Tests"])
        replacement_sources = occurrences(replacement, [ROOT / "PooToolsSource"])
        entry["internalUsage"] = {"count": len(internal), "locations": internal[:50]}
        entry["exampleUsage"] = {"count": len(example), "locations": example[:50]}
        entry["testsUsage"] = {"count": len(tests), "locations": tests[:50]}
        entry["canonicalReplacementExists"] = bool(replacement_sources)
        entry["compatibilityForwarding"] = bool(internal) and bool(replacement_sources)
        entry["migrationDoc"] = "CHANGELOG.md"
        entry["consumerEvidence"] = "Deterministic source/example/test scan at VERSION 5.59.0."
        entry["removeIn"] = "6.0.0"
    MANIFEST.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    print(f"PASS [DEPRECATED_MANIFEST_GENERATED] entries={len(payload.get('entries', []))}")


if __name__ == "__main__":
    main()
