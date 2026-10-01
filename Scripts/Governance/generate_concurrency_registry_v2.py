#!/usr/bin/env python3

# English: Convert the legacy file-level concurrency allowlist into auditable symbol entries.
# Español: Convierte la lista heredada por archivo en entradas auditables por símbolo.
# 中文：将旧的文件级并发白名单转换为可审计的逐符号条目。

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "Scripts" / "concurrency_exception_registry.json"
SOURCE_ROOT = ROOT / "PooToolsSource"


def find_symbol(lines: list[str], index: int) -> str:
    same_line = re.search(r"\b(?:class|struct|enum|actor|protocol)\s+([A-Za-z_][A-Za-z0-9_]*)", lines[index])
    if same_line:
        return same_line.group(1)
    for candidate in reversed(lines[max(0, index - 24):index + 1]):
        match = re.search(r"\b(?:class|struct|enum|actor|protocol)\s+([A-Za-z_][A-Za-z0-9_]*)", candidate)
        if match:
            return match.group(1)
    return f"anonymous@{index + 1}"


def main() -> None:
    payload = json.loads(REGISTRY.read_text())
    category_entries = {
        entry["path"]: entry
        for entry in payload.get("exceptions", payload.get("files", []))
    }
    definitions = payload["category_definitions"]
    exceptions = []

    for path in sorted(SOURCE_ROOT.rglob("*.swift")):
        relative = path.relative_to(ROOT).as_posix()
        lines = path.read_text(errors="ignore").splitlines()
        if not any("@unchecked Sendable" in line and not line.lstrip().startswith("//") for line in lines):
            continue
        file_entry = category_entries.get(relative)
        if not file_entry:
            raise SystemExit(f"unregistered unchecked-sendable file: {relative}")
        category = file_entry["category"]
        definition = definitions[category]
        owner = relative.split("/")[1] if len(relative.split("/")) > 1 else "Core"
        for index, line in enumerate(lines):
            if "@unchecked Sendable" not in line or line.lstrip().startswith("//"):
                continue
            symbol = find_symbol(lines, index)
            exceptions.append(
                {
                    "path": relative,
                    "symbol": symbol,
                    "category": category,
                    "systemType": definition["system_type"],
                    "reason": f"Audited compatibility boundary for {symbol}; mutable state is not treated as implicitly safe.",
                    "protection": definition["protection"],
                    "owner": owner,
                    "replacementPlan": definition["replacement_plan"],
                    "removeIn": None if category == "SYSTEM_WRAPPER" else "6.0.0",
                }
            )

    output = {
        "schema_version": 2,
        "required_fields": [
            "path", "symbol", "category", "systemType", "reason",
            "protection", "owner", "replacementPlan", "removeIn",
        ],
        "category_definitions": definitions,
        "nonisolated_unsafe_files": [],
        "exceptions": exceptions,
    }
    REGISTRY.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n")
    print(f"PASS [CONCURRENCY_REGISTRY_GENERATED] symbols={len(exceptions)}")


if __name__ == "__main__":
    main()
