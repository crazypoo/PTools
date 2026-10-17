#!/usr/bin/env python3
# English: Produce the auditable one-pass reports that do not require a build.
# Español: Produce los informes auditables de una pasada que no requieren una compilación.
# 中文：生成不依赖构建的可审计一键报告。

from __future__ import annotations

import csv
import json
from pathlib import Path


def write_csv(path: Path, fields: list[str], rows: list[dict]) -> None:
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader(); writer.writerows(rows)


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    out = root / "report/spm/onepass"
    out.mkdir(parents=True, exist_ok=True)
    index_path = root / "Tests/SPMConsumerFixtures/Generated/ProductIndex.json"
    index = json.loads(index_path.read_text()) if index_path.is_file() else []
    (out / "product_import_map.json").write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n")

    targets = json.loads((root / "report/spm/inventory/manifest_targets.json").read_text())
    ownership = json.loads((root / "report/spm/inventory/source_ownership.json").read_text()).get("owners", {})
    parity = []
    for target in targets:
        for source in target.get("sources", []):
            parity.append({"path": source, "manifest_target": target["name"], "ownership_targets": ";".join(ownership.get(source, [])), "status": "match" if target["name"] in ownership.get(source, []) else "mismatch"})
    write_csv(out / "ownership_parity.csv", ["path","manifest_target","ownership_targets","status"], parity)

    cross = root / "report/spm/audits/cross_target_findings.csv"
    cross_rows = list(csv.DictReader(cross.open(newline=""))) if cross.is_file() else []
    violations = [row for row in cross_rows if row.get("status") == "open"]
    write_csv(out / "dependency_violations.csv", list(cross_rows[0].keys()) if cross_rows else ["status"], violations)

    conditional = root / "report/spm/audits/conditional_compile_matrix.csv"
    resources = root / "report/spm/audits/resources.csv"
    macro_rows = []
    if conditional.is_file():
        for row in csv.DictReader(conditional.open(newline="")):
            macro_rows.append({"kind": "conditional", "ownerTarget": row.get("ownerTarget", ""), "path": row.get("path", ""), "line": row.get("line", ""), "status": row.get("review", "")})
    if resources.is_file():
        for row in csv.DictReader(resources.open(newline="")):
            macro_rows.append({"kind": "resource", "ownerTarget": row.get("ownerTarget", ""), "path": row.get("path", ""), "line": row.get("line", ""), "status": row.get("status", "")})
    write_csv(out / "macro_resource_matrix.csv", ["kind","ownerTarget","path","line","status"], macro_rows)

    issues = [
        ("SPM-P0-001", "BioID direct KeyChain ownership/import", "PooToolsBioID", "fixed-source-and-manifest"),
        ("SPM-P0-002", "ScrollBanner direct PageControl ownership/import", "PooToolsScrollBanner", "fixed-source-import"),
        ("SPM-R-003", "GlobalVideoExts replacement", "PooToolsMediaViewer", "fixed-in-5.65.6"),
        ("SPM-R-004", "PTRichText ownership", "PToolsUIFoundation", "static-review"),
        ("SPM-R-005", "PTSceneContext ownership", "ptools", "static-review"),
        ("SPM-R-006", "PTActionTask ownership", "ptools", "static-review"),
        ("SPM-R-007", "PTClampedPropertyWrapper ownership", "ptools", "static-review"),
        ("SPM-R-008", "DevMaskColor/HSL ownership", "ptools", "static-review"),
        ("SPM-R-009", "Banner/Vision ownership", "PooToolsBanner;PooToolsVision", "static-review"),
        ("SPM-R-010", "WhatsNewsKit ownership", "PooToolsWhatsNewsKit", "static-review"),
    ]
    write_csv(out / "babobuy_5656_issue_matrix.csv", ["issue_id","issue","dependent_target","status","source_sha","debug_evidence","release_evidence","device_evidence","runtime_smoke"], [{
        "issue_id": issue_id, "issue": issue, "dependent_target": target, "status": status,
        "source_sha": "working-tree", "debug_evidence": "pending-consumer-matrix", "release_evidence": "pending-consumer-matrix",
        "device_evidence": "not-available-in-PTools-repository", "runtime_smoke": "external-BaboBuy-host-required",
    } for issue_id, issue, target, status in issues])
    print(f"onepass_reports={out.relative_to(root)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
