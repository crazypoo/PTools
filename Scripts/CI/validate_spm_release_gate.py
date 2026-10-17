#!/usr/bin/env python3
# English: Require fresh, complete SwiftPM consumer evidence before release.
# Español: Exige evidencia fresca y completa de consumidores SwiftPM antes de publicar.
# 中文：发布前要求完整且新鲜的 SwiftPM 消费者证据。

from __future__ import annotations

import argparse
import csv
import json
import subprocess
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--allow-not-run", action="store_true", help="deprecated local escape hatch; never valid for release")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    failures: list[str] = []
    if args.allow_not_run:
        failures.append("--allow-not-run is not accepted by the 5.65.7 release gate")
    inventory = root / "report/spm/inventory"
    audits = root / "report/spm/audits"
    onepass = root / "report/spm/onepass"
    required = [
        inventory / "manifest_products.json", inventory / "manifest_targets.json", inventory / "source_ownership.json",
        audits / "symbol_declarations.json", audits / "symbol_references.json", audits / "cross_target_findings.csv",
        audits / "conditional_compile_matrix.csv", audits / "resources.csv", onepass / "environment.txt",
        onepass / "manifest.json", onepass / "package-description.json", onepass / "api_surface.json",
        onepass / "api_surface.csv", onepass / "product_import_map.json", onepass / "ownership_parity.csv",
        onepass / "dependency_violations.csv", onepass / "macro_resource_matrix.csv", onepass / "all_findings.csv",
        onepass / "babobuy_5656_issue_matrix.csv", onepass / "summary.md",
    ]
    for path in required:
        if not path.is_file():
            failures.append(f"missing report: {path.relative_to(root)}")

    version = (root / "VERSION").read_text().strip()
    if version != "5.65.7":
        failures.append(f"expected VERSION 5.65.7, got {version}")
    for name in ["README.md", "CHANGELOG.md", "ROADMAP.md"]:
        path = root / name
        if not path.is_file() or version not in path.read_text(errors="replace"):
            failures.append(f"{name} does not mention VERSION {version}")

    products = json.loads((inventory / "manifest_products.json").read_text()) if (inventory / "manifest_products.json").is_file() else []
    library_products = {item["name"] for item in products if "library" in item.get("type", {})}
    matrix_path = root / "report/spm/spm_product_matrix.csv"
    rows = list(csv.DictReader(matrix_path.open(newline=""))) if matrix_path.is_file() else []
    expected = {(product, config) for product in library_products for config in ("Debug", "Release")}
    actual = {(row.get("product"), row.get("configuration")) for row in rows}
    missing = expected - actual
    if missing:
        failures.append(f"consumer matrix missing rows: {len(missing)}")
    if len(rows) != len(expected):
        failures.append(f"consumer matrix row count {len(rows)} != {len(expected)}")
    current_sha = subprocess.run(["git", "rev-parse", "HEAD"], cwd=root, text=True, capture_output=True).stdout.strip()
    for row in rows:
        if row.get("status") != "pass":
            failures.append(f"consumer not passed: {row.get('product')} {row.get('configuration')} status={row.get('status')}")
        if row.get("version") != version:
            failures.append(f"consumer version mismatch: {row.get('product')} {row.get('configuration')}")
        if current_sha and row.get("sha") != current_sha:
            failures.append(f"consumer SHA mismatch: {row.get('product')} {row.get('configuration')}")
        if not (root / row.get("log_path", "missing")).is_file():
            failures.append(f"consumer log missing: {row.get('product')} {row.get('configuration')}")
        if not (root / row.get("xcresult_path", "missing")).exists():
            failures.append(f"consumer xcresult missing: {row.get('product')} {row.get('configuration')}")

    with (audits / "cross_target_findings.csv").open(newline="") as handle:
        findings = list(csv.DictReader(handle))
    if any(item.get("status") == "open" for item in findings):
        failures.append("open cross-target ownership findings remain")
    with (onepass / "all_findings.csv").open(newline="") as handle:
        diagnostics = list(csv.DictReader(handle))
    if any(item.get("status") == "open" and item.get("category") in {"missing-import", "linker"} for item in diagnostics):
        failures.append("open missing-import or linker diagnostics remain")

    if failures:
        for item in failures:
            print(f"FAIL: {item}")
        return 1
    print("PASS: SwiftPM 5.65.7 release gate")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
