#!/usr/bin/env python3
# English: Cross-check SwiftPM resource ownership against source-level bundle lookups.
# Español: Comprueba la propiedad de recursos de SwiftPM frente a las búsquedas de bundles en el código.
# 中文：交叉核对 SwiftPM 资源归属和源码中的 Bundle 读取。

from __future__ import annotations

import csv
import json
import re
from pathlib import Path


RESOURCE_LOOKUP = re.compile(r"\b(Bundle\.module|Bundle\.main|Bundle\s*\(for:|UIImage\s*\(named:|UIImage\s*\(contentsOfFile:|NSDataAsset\s*\(name:)")


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    targets = json.loads((root / "report/spm/inventory/manifest_targets.json").read_text())
    output = root / "report/spm/audits"
    output.mkdir(parents=True, exist_ok=True)
    rows = []
    for target in targets:
        owner = target["name"]
        resources = target.get("resources", [])
        for resource in resources:
            path = resource.get("path", "") if isinstance(resource, dict) else str(resource)
            rows.append({
                "ownerTarget": owner,
                "kind": "manifest-resource",
                "path": path,
                "line": "",
                "expression": "",
                "status": "declared",
            })
        for relative in target.get("sources", []):
            path = root / relative
            if not path.is_file():
                continue
            for number, line in enumerate(path.read_text(errors="replace").splitlines(), start=1):
                match = RESOURCE_LOOKUP.search(line)
                if not match:
                    continue
                rows.append({
                    "ownerTarget": owner,
                    "kind": "source-lookup",
                    "path": relative,
                    "line": number,
                    "expression": match.group(1),
                    "status": "manual-bundle-review",
                })

    # English: Keep generated resource audits stable for git diff and CI portability.
    # Español: Mantén estables las auditorías de recursos generadas para git diff y la portabilidad de CI.
    # 中文：让资源审计报告在 git diff 和 CI 环境中保持稳定。
    with (output / "resources.csv").open("w", newline="") as handle:
        fields = ["ownerTarget", "kind", "path", "line", "expression", "status"]
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    print(f"resource_entries={len(rows)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
