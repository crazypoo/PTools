#!/usr/bin/env python3
# English: Record conditional-compilation branches so SwiftPM and CocoaPods paths stay reviewable.
# Español: Registra las ramas de compilación condicional para mantener revisables las rutas de SwiftPM y CocoaPods.
# 中文：记录条件编译分支，确保 SwiftPM 和 CocoaPods 路径可审计。

from __future__ import annotations

import csv
import json
import re
from pathlib import Path


DIRECTIVE = re.compile(r"^\s*#\s*(if|elseif|else|endif)\b(?:\s+(.*?))?\s*$")


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    inventory_path = root / "report/spm/inventory/manifest_targets.json"
    if not inventory_path.exists():
        raise SystemExit("manifest target inventory is missing; run audit_spm_target_graph.py first")
    targets = json.loads(inventory_path.read_text())
    output = root / "report/spm/audits"
    output.mkdir(parents=True, exist_ok=True)
    rows = []
    for target in targets:
        owner = target["name"]
        for relative in target.get("sources", []):
            path = root / relative
            if not path.is_file():
                continue
            stack: list[str] = []
            for number, line in enumerate(path.read_text(errors="replace").splitlines(), start=1):
                match = DIRECTIVE.match(line)
                if not match:
                    continue
                kind, condition = match.groups()
                condition = (condition or "").strip()
                if kind == "if":
                    stack.append(condition)
                elif kind == "elseif":
                    if stack:
                        stack[-1] = condition
                elif kind == "else":
                    if stack:
                        stack[-1] = f"else of {stack[-1]}"
                elif kind == "endif":
                    if stack:
                        stack.pop()
                rows.append({
                    "ownerTarget": owner,
                    "path": relative,
                    "line": number,
                    "directive": kind,
                    "condition": condition,
                    "activeBranch": " > ".join(stack),
                    "review": "review-platform-or-package-branch" if condition else "structural",
                })

    package_text = (root / "Package.swift").read_text(errors="replace")
    for number, line in enumerate(package_text.splitlines(), start=1):
        if ".define(" in line:
            rows.append({
                "ownerTarget": "Package.swift",
                "path": "Package.swift",
                "line": number,
                "directive": "swift-setting-define",
                "condition": line.strip(),
                "activeBranch": "manifest",
                "review": "compare-cocoapods-macro",
            })

    with (output / "conditional_compile_matrix.csv").open("w", newline="") as handle:
        fields = ["ownerTarget", "path", "line", "directive", "condition", "activeBranch", "review"]
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    print(f"conditional_branches={len(rows)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
