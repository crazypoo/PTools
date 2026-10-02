#!/usr/bin/env python3

# English: Require every registered resource cache to declare limits, ownership and its runtime contract.
# Español: Exige límites, propiedad y contrato de ejecución para cada caché registrada.
# 中文：要求每个登记的资源缓存明确容量、所有者和运行时契约。

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
    if payload.get("schemaVersion") != 2:
        fail("schemaVersion must be 2")
    required = {"name", "path", "namespace", "implementation", "countLimit", "costLimit", "diskLimit", "expirationSeconds", "memoryWarning", "lowDisk", "metrics", "owner", "threadIsolation"}
    contracts = {"NATIVE_PT_CACHE", "ADAPTED_PT_CACHE", "DEPENDENCY_MANAGED"}
    names: set[str] = set()
    for entry in payload.get("entries", []):
        missing = required - set(entry)
        if missing:
            fail(f"{entry.get('name')} misses {sorted(missing)}")
        if entry["name"] in names:
            fail(f"duplicate cache entry {entry['name']}")
        names.add(entry["name"])
        source_path = ROOT / entry["path"]
        if not source_path.is_file():
            fail(f"cache source does not exist: {entry['path']}")
        contract = entry.get("contract")
        if contract not in contracts:
            fail(f"invalid contract for {entry['name']}: {contract}")
        source = source_path.read_text(encoding="utf-8", errors="ignore")
        if contract in {"NATIVE_PT_CACHE", "ADAPTED_PT_CACHE"}:
            policy_symbol = entry.get("policySymbol")
            if not isinstance(policy_symbol, str) or not policy_symbol.strip():
                fail(f"policySymbol is required for {entry['name']}")
            policy_references = source.count(policy_symbol)
            if policy_references < 2:
                fail(f"policySymbol {policy_symbol} is not wired in {entry['path']}")
        if contract == "DEPENDENCY_MANAGED":
            dependency = entry.get("dependency")
            if not isinstance(dependency, str) or not dependency.strip():
                fail(f"dependency is required for {entry['name']}")
            if dependency not in source:
                fail(f"dependency {dependency} is not referenced by {entry['path']}")
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
