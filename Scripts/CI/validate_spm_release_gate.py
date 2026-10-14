#!/usr/bin/env python3
# English: Enforce the SwiftPM release gate only when real consumer evidence is present.
# Español: Aplica la puerta de publicación de SwiftPM solo cuando existe evidencia real del consumidor.
# 中文：仅当存在真实消费者构建证据时，才执行 SwiftPM 发布门禁。

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path


def fail(message: str, failures: list[str]) -> None:
    failures.append(message)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--allow-not-run", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    failures: list[str] = []
    inventory = root / "report/spm/inventory"
    audit = root / "report/spm/audits"
    required = [
        inventory / "manifest_products.json",
        inventory / "manifest_targets.json",
        inventory / "source_ownership.json",
        inventory / "source_ownership_anomalies.csv",
        audit / "symbol_declarations.json",
        audit / "symbol_references.json",
        audit / "cross_target_findings.csv",
        audit / "conditional_compile_matrix.csv",
        audit / "resources.csv",
    ]
    for path in required:
        if not path.is_file():
            fail(f"missing report: {path.relative_to(root)}", failures)

    if (inventory / "source_ownership_anomalies.csv").is_file():
        with (inventory / "source_ownership_anomalies.csv").open(newline="") as handle:
            anomalies = list(csv.DictReader(handle))
        meaningful = [row for row in anomalies if row.get("kind") not in {"target-without-swift-source"}]
        if meaningful:
            fail(f"source ownership anomalies: {len(meaningful)}", failures)

    matrix_path = root / "report/spm/spm_product_matrix.csv"
    if matrix_path.is_file():
        with matrix_path.open(newline="") as handle:
            matrix = list(csv.DictReader(handle))
        if not matrix:
            fail("empty product matrix", failures)
        not_run = [row for row in matrix if row.get("status") == "not_run"]
        if not_run and not args.allow_not_run:
            fail(f"product consumer builds not recorded: {len(not_run)}", failures)
        failed = [row for row in matrix if row.get("status") in {"failed", "blocked"}]
        if failed:
            fail(f"product consumer failures: {len(failed)}", failures)

    version = (root / "VERSION").read_text().strip()
    for name in ["README.md", "CHANGELOG.md", "ROADMAP.md"]:
        text = (root / name).read_text(errors="replace")
        if version not in text:
            fail(f"{name} does not mention VERSION {version}", failures)

    if failures:
        for item in failures:
            print(f"FAIL: {item}")
        return 1
    print("PASS: SwiftPM release gate")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
