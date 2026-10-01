#!/usr/bin/env python3

# English: Validate frozen dependency decisions against the direct SPM and CocoaPods graph.
# Español: Valida las decisiones congeladas contra el grafo directo de SPM y CocoaPods.
# 中文：根据 SwiftPM 与 CocoaPods 的直接依赖图校验冻结决策。

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def normalize(name: str) -> str:
    return {"swift-protobuf": "Protobuf"}.get(name, name)


def direct_dependencies() -> set[str]:
    package = (ROOT / "Package.swift").read_text()
    spm = {
        normalize(match.group(1))
        for match in re.finditer(r"\.package\([^\n]*?url:\s*\"[^\"]+/([^/]+?)(?:\.git)?\"", package)
    }
    podspec = (ROOT / "PooTools.podspec").read_text()
    pods = {
        match.group(1)
        for match in re.finditer(r"(?:subspec\.)?dependency ['\"]([^'\"]+)", podspec)
        if not match.group(1).startswith("PooTools/")
    }
    return spm | pods


def fail(message: str) -> None:
    print(f"FAIL [DEPENDENCY_FREEZE] {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    manifest = json.loads((ROOT / "Scripts/dependency_freeze.json").read_text())
    if manifest.get("schemaVersion") != 2:
        fail("schemaVersion must be 2")
    required = {"dependency", "decision", "publicAPIExposure", "packageProduct", "podSubspec", "consumerEvidence", "removalPreconditions", "reason", "owner", "removeIn"}
    entries = manifest.get("decisions", [])
    names: set[str] = set()
    for entry in entries:
        missing = required - set(entry)
        if missing:
            fail(f"missing fields {sorted(missing)} for {entry}")
        name = entry["dependency"]
        if name in names:
            fail(f"duplicate decision: {name}")
        names.add(name)
        if entry["decision"] not in manifest.get("allowedDecisions", []):
            fail(f"unknown decision {entry['decision']} for {name}")
        text = json.dumps(entry, ensure_ascii=False).lower()
        if any(marker in text for marker in ("tbd", "scan required", "reassessment", "unknown")):
            fail(f"placeholder governance text remains for {name}")
        if not entry["owner"].strip() or not entry["reason"].strip() or not entry["consumerEvidence"].strip():
            fail(f"empty ownership/evidence for {name}")
        if not isinstance(entry["removalPreconditions"], list) or not entry["removalPreconditions"]:
            fail(f"removalPreconditions must be a non-empty list for {name}")
        if entry["decision"] == "REMOVE_IN_6" and entry["removeIn"] != "6.0.0":
            fail(f"REMOVE_IN_6 must removeIn=6.0.0 for {name}")
        if entry["decision"] != "REMOVE_IN_6" and entry["removeIn"] is not None:
            fail(f"non-removal decision must have removeIn=null for {name}")

    direct = direct_dependencies()
    missing = sorted(direct - names)
    if missing:
        fail("direct dependencies without decisions: " + ", ".join(missing))

    podspec = (ROOT / "PooTools.podspec").read_text()
    core_match = re.search(r"s\.subspec ['\"]Core['\"].*?(?=\n\s*s\.subspec |\Z)", podspec, re.S)
    core_block = core_match.group(0) if core_match else ""
    for entry in entries:
        if entry["decision"] != "OPTIONAL_PRODUCT":
            continue
        pod = entry["podSubspec"]
        if pod and (f"dependency '{entry['dependency']}'" in core_block or f"dependency '{pod}'" in core_block):
            fail(f"OPTIONAL_PRODUCT is directly required by default Core: {entry['dependency']}")

    lock_path = ROOT / "Podfile.lock"
    if lock_path.exists():
        lock = lock_path.read_text()
        for entry in entries:
            pod = entry["podSubspec"]
            if pod and entry["dependency"] in direct and pod not in lock and entry["dependency"] not in lock:
                fail(f"Podfile.lock has no evidence for {entry['dependency']}/{pod}")

    print(f"PASS [DEPENDENCY_FREEZE] decisions={len(entries)} direct_dependencies={len(direct)}")


if __name__ == "__main__":
    main()
