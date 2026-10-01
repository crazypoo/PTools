#!/usr/bin/env python3

# English: Validate every unchecked-sendable declaration against the symbol-level registry.
# Español: Valida cada declaración unchecked-sendable contra el registro por símbolo.
# 中文：将每个 unchecked-sendable 声明与逐符号登记表进行校验。

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE_ROOT = ROOT / "PooToolsSource"
REGISTRY = ROOT / "Scripts" / "concurrency_exception_registry.json"
ALLOWLIST = ROOT / "Scripts" / "unchecked_sendable_allowlist.txt"


def fail(message: str) -> None:
    print(f"FAIL [CONCURRENCY_REGISTRY] {message}", file=sys.stderr)
    raise SystemExit(1)


def source_declarations() -> list[tuple[str, int]]:
    entries: list[tuple[str, int]] = []
    for path in sorted(SOURCE_ROOT.rglob("*.swift")):
        for number, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
            if "@unchecked Sendable" in line and not line.lstrip().startswith("//"):
                entries.append((path.relative_to(ROOT).as_posix(), number))
    return entries


def main() -> None:
    payload = json.loads(REGISTRY.read_text())
    if payload.get("schema_version") != 2:
        fail("registry must use schema_version=2")
    required = set(payload.get("required_fields", []))
    exceptions = payload.get("exceptions", [])
    if not exceptions:
        fail("symbol registry is empty")

    keys: set[tuple[str, str]] = set()
    registry_paths: set[str] = set()
    for entry in exceptions:
        missing = required - set(entry)
        if missing:
            fail(f"missing fields {sorted(missing)} for {entry}")
        key = (entry["path"], entry["symbol"])
        if key in keys:
            fail(f"duplicate symbol entry {key}")
        keys.add(key)
        registry_paths.add(entry["path"])
        if entry["category"] == "TEMPORARY":
            fail(f"TEMPORARY exception remains: {entry['path']}::{entry['symbol']}")
        if not (ROOT / entry["path"]).is_file():
            fail(f"registered file does not exist: {entry['path']}")
        if not entry["reason"].strip() or not entry["owner"].strip() or not entry["protection"].strip():
            fail(f"empty audit metadata: {entry['path']}::{entry['symbol']}")

    declaration_paths = {path for path, _ in source_declarations()}
    allowlisted = {
        line.strip() for line in ALLOWLIST.read_text().splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }
    if declaration_paths != allowlisted:
        fail(f"allowlist drift: source={len(declaration_paths)} allowlist={len(allowlisted)}")
    if declaration_paths != registry_paths:
        fail(f"registry path drift: source={len(declaration_paths)} registry={len(registry_paths)}")

    generic_box = re.compile(r"\b(?:SendableBox|SafeMediaBox)\s*<")
    generic_hits = []
    unsafe_hits = []
    for path in sorted(SOURCE_ROOT.rglob("*.swift")):
        for number, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
            if generic_box.search(line) and "@unchecked Sendable" in line:
                generic_hits.append(f"{path.relative_to(ROOT)}:{number}")
            if "nonisolated(unsafe)" in line:
                unsafe_hits.append(f"{path.relative_to(ROOT)}:{number}")
    if generic_hits:
        fail("generic unchecked box remains: " + ", ".join(generic_hits))
    if unsafe_hits:
        fail("business nonisolated(unsafe) remains: " + ", ".join(unsafe_hits))

    business = sum(entry["category"] in {"LEGACY_MODEL", "MAIN_ACTOR_ONLY", "LOCK_PROTECTED"} for entry in exceptions)
    print(f"PASS [CONCURRENCY_REGISTRY] symbols={len(exceptions)} business_compatibility_entries={business}")


if __name__ == "__main__":
    main()
