#!/usr/bin/env python3

# English: Freeze every currently observed legacy/deprecated source entry for the 6.0 migration window.
# Español: Congela cada entrada heredada/obsoleta observada para la ventana de migración 6.0.
# 中文：冻结当前观察到的全部 legacy/deprecated 入口，明确其 6.0 迁移窗口。

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "Scripts/deprecated_6_freeze_manifest.json"
LEGACY_SYMBOLS = {
    "Network.gobalUrl": "Network.globalURL",
    "Network.socketGobalUrl": "Network.socketGlobalURL",
    "GobalNavControl": "globalNavControl",
    "gobalWebImageLoadOption": "webImageLoadOptions",
    "heightlightColor": "highlightColor",
    "netRequsetTime": "requestTimeout",
    "downloadRequsetTime": "downloadRequestTimeout",
    "pullDismissThreshod": "pullDismissThreshold",
    "PTCoreUserDefultsWrapper": "PTCoreUserDefaultsWrapper",
    "BilogyID": "BiologyID",
    "MeidaPermission": "MediaPermission",
}


def main() -> None:
    entries: list[dict[str, object]] = []
    for path in sorted((ROOT / "PooToolsSource").rglob("*.swift")):
        relative = path.relative_to(ROOT).as_posix()
        for line_number, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
            matches = [(symbol, replacement, "ALIAS") for symbol, replacement in LEGACY_SYMBOLS.items() if symbol in line]
            if "@available" in line and "deprecated" in line:
                matches.append(("@available deprecated", "docs/migration/MIGRATION_6.md", "DEPRECATED_API"))
            for symbol, replacement, classification in matches:
                if "/Generated/" in relative:
                    classification = "GENERATED_COMPATIBILITY"
                entry_id = f"{relative}:{line_number}:{symbol}"
                entries.append(
                    {
                        "id": entry_id,
                        "path": relative,
                        "line": line_number,
                        "symbol": symbol,
                        "replacement": replacement,
                        "classification": classification,
                        "status": "KEEP_UNTIL_6_0",
                        "firstDeprecated": "5.x",
                        "removeIn": "6.0.0",
                        "internalUsage": "tracked_by_source_scan",
                        "migrationEvidence": "docs/migration/MIGRATION_6.md",
                    }
                )
    entries.sort(key=lambda item: str(item["id"]))
    payload = {
        "schemaVersion": 1,
        "targetVersion": "5.60.0",
        "removalVersion": "6.0.0",
        "sourceRoots": ["PooToolsSource"],
        "entries": entries,
    }
    OUTPUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    print(f"PASS [DEPRECATED_FREEZE_GENERATED] entries={len(entries)}")


if __name__ == "__main__":
    main()
