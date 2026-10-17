#!/usr/bin/env python3
# English: Run a conservative public API preflight for isolated SwiftPM products.
# Español: Ejecuta una comprobación conservadora de la API pública de productos SwiftPM aislados.
# 中文：对独立 SwiftPM product 执行保守的公开 API 预检。

from __future__ import annotations

import argparse
import csv
import json
import re
from pathlib import Path


PUBLIC = re.compile(r"^\s*(?:@available\([^\n]+\)\s*)?(public|open)\s+(?:final\s+|indirect\s+|static\s+|class\s+|nonisolated\s+)*(class|struct|enum|protocol|actor|func|var|let|init|subscript|typealias)\b")
INTERNAL = re.compile(r"\b(?:internal|fileprivate|private)\s+(?:class|struct|enum|protocol|actor|func|var|let|init|subscript|typealias)\b")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    inventory = root / "report/spm/inventory"
    targets = json.loads((inventory / "manifest_targets.json").read_text())
    output = root / "report/spm/onepass"
    output.mkdir(parents=True, exist_ok=True)
    declarations: list[dict] = []
    findings: list[dict] = []
    for target in targets:
        owner = target["name"]
        for relative in target.get("sources", []):
            path = root / relative
            if not path.is_file() or path.suffix != ".swift":
                continue
            lines = path.read_text(errors="replace").splitlines()
            for number, line in enumerate(lines, 1):
                match = PUBLIC.match(line)
                if not match:
                    continue
                declarations.append({"target": owner, "path": relative, "line": number, "declaration": line.strip()})
                # English: Dynamic values are allowed for compatibility, but their public boundary is recorded for review.
                # Español: Los valores dinámicos se permiten por compatibilidad, pero se registran en la frontera pública.
                # 中文：为兼容性允许动态值，但把公开边界记录下来供审查。
                if re.search(r"\bAny(?:Hashable)?\b|\[\s*String\s*:\s*Any\s*\]", line):
                    findings.append({"target": owner, "path": relative, "line": number, "category": "dynamic-public-api", "severity": "review", "message": line.strip()})
                if "@inlinable" in line and INTERNAL.search(line):
                    findings.append({"target": owner, "path": relative, "line": number, "category": "inlinable-internal", "severity": "high", "message": line.strip()})
    (output / "api_surface.json").write_text(json.dumps({"declarations": declarations, "findings": findings}, ensure_ascii=False, indent=2) + "\n")
    with (output / "api_surface.csv").open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["target", "path", "line", "declaration"], lineterminator="\n")
        writer.writeheader(); writer.writerows(declarations)
    with (output / "api_surface_findings.csv").open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["target", "path", "line", "category", "severity", "message"], lineterminator="\n")
        writer.writeheader(); writer.writerows(findings)
    high = sum(item["severity"] == "high" for item in findings)
    print(f"public_declarations={len(declarations)} findings={len(findings)} high={high}")
    return 1 if args.strict and high else 0


if __name__ == "__main__":
    raise SystemExit(main())
