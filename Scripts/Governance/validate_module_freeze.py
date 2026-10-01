#!/usr/bin/env python3

# English: Validate module ownership and machine-readable parity resolutions.
# Español: Valida la propiedad de módulos y las resoluciones de paridad legibles por máquina.
# 中文：校验模块归属及机器可读的 parity 差异处理记录。

from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def fail(message: str) -> None:
    print(f"FAIL [MODULE_FREEZE] {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    freeze = json.loads((ROOT / "Scripts/module_freeze.json").read_text())
    registry = json.loads((ROOT / "Scripts/module_registry.json").read_text())
    parity = json.loads((ROOT / "report/current/module_parity.json").read_text())
    if freeze.get("schemaVersion") != 1 or freeze.get("unknownDrift") != 0:
        fail("module freeze contract is not closed")
    names: set[str] = set()
    for module in registry.get("modules", []):
        required = {"name", "spm_product", "spm_target", "pod_subspec", "source_path", "dependencies", "compile_flags", "resources", "category"}
        missing = required - set(module)
        if missing:
            fail(f"module {module.get('name')} misses {sorted(missing)}")
        if module["name"] in names:
            fail(f"duplicate module owner: {module['name']}")
        names.add(module["name"])
        if not (ROOT / module["source_path"]).exists():
            fail(f"module source path does not exist: {module['source_path']}")

    known_only = {(entry["kind"], entry["module"]) for entry in registry.get("known_module_only", [])}
    for kind in ("spm_only", "pod_only"):
        for module in parity.get(kind, []):
            if (kind, module) not in known_only:
                fail(f"unresolved module parity entry: {kind}/{module}")

    known_drift = {(entry["kind"], entry["module"], entry.get("field")) for entry in registry.get("known_drift", [])}
    for kind, section in (("source", "source_drift"), ("dependency", "dependency_drift"), ("settings", "settings_drift")):
        for entry in parity.get(section, []):
            identity = (kind, entry["module"], entry.get("field", "source_directories") if kind == "source" else entry.get("field"))
            if identity not in known_drift:
                fail(f"unresolved parity drift: {identity}")

    print(f"PASS [MODULE_FREEZE] owned_modules={len(names)} known_drift={len(known_drift)}")


if __name__ == "__main__":
    main()
