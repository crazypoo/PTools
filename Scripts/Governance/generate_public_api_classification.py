#!/usr/bin/env python3

# English: Generate a deterministic per-symbol public API classification from the source report.
# Español: Genera una clasificación determinista por símbolo a partir del informe de API pública.
# 中文：根据公开 API 源码报告生成确定性的逐符号分类表。

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "report/current/public_api.json"
OUTPUT = ROOT / "Scripts/public_api_classification.json"


def category(entry: dict[str, str]) -> str:
    path = entry["path"].lower()
    declaration = entry["declaration"].lower()
    if any(token in path or token in declaration for token in ("legacy", "compatibility", "deprecated")):
        return "compatibility"
    if any(token in path for token in ("debug", "inspector", "example")):
        return "experimental"
    return "canonical"


def main() -> None:
    source = json.loads(REPORT.read_text())
    classifications = []
    for entry in source.get("declarations", []):
        kind = category(entry)
        classifications.append(
            {
                "symbol": f"{entry['key']}@{entry['line']}",
                "module": entry["path"].split("/")[1] if "/" in entry["path"] else "Core",
                "category": kind,
                "replacement": "See migration manifest" if kind == "compatibility" else None,
                "owner": entry["path"].split("/")[1] if "/" in entry["path"] else "Core",
                "since": "5.0.0",
                "removeIn": "6.0.0" if kind == "compatibility" else None,
            }
        )
    payload = {
        "schemaVersion": 1,
        "versionSource": "VERSION",
        "baseline": "report/current/public_api.json",
        "classifications": classifications,
    }
    OUTPUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    print(f"PASS [PUBLIC_API_CLASSIFICATION_GENERATED] symbols={len(classifications)}")


if __name__ == "__main__":
    main()
