#!/usr/bin/env python3

# English: Require every registered resource cache to declare limits, ownership and cleanup behavior.
# Español: Exige límites, propiedad y limpieza para cada caché de recursos registrada.
# 中文：要求每个登记的资源缓存明确容量、所有者和清理行为。

from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "Scripts/Governance/cache_governance.json"


def fail(message: str) -> None:
    print(f"FAIL [CACHE_GOVERNANCE] {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    payload = json.loads(MANIFEST.read_text())
    if payload.get("schemaVersion") != 1:
        fail("schemaVersion must be 1")
    required = {"name", "path", "namespace", "implementation", "countLimit", "costLimit", "diskLimit", "expirationSeconds", "memoryWarning", "lowDisk", "metrics", "owner", "threadIsolation"}
    names: set[str] = set()
    for entry in payload.get("entries", []):
        missing = required - set(entry)
        if missing:
            fail(f"{entry.get('name')} misses {sorted(missing)}")
        if entry["name"] in names:
            fail(f"duplicate cache entry {entry['name']}")
        names.add(entry["name"])
        if not (ROOT / entry["path"]).is_file():
            fail(f"cache source does not exist: {entry['path']}")
        if not entry["namespace"].strip() or not entry["owner"].strip() or not entry["threadIsolation"].strip():
            fail(f"incomplete cache ownership: {entry['name']}")
        if not entry["memoryWarning"].strip() or not entry["lowDisk"].strip():
            fail(f"incomplete cache cleanup policy: {entry['name']}")
        for key in ("countLimit", "costLimit", "diskLimit", "expirationSeconds"):
            value = entry[key]
            if value is not None and (not isinstance(value, int) or value <= 0):
                fail(f"invalid {key} for {entry['name']}")
    print(f"PASS [CACHE_GOVERNANCE] caches={len(names)} unresolved=0")


if __name__ == "__main__":
    main()
