#!/usr/bin/env python3
# English: Generate the isolated SwiftPM consumer matrix without pretending that builds ran.
# Español: Genera la matriz de consumidores aislados de SwiftPM sin fingir que se ejecutaron compilaciones.
# 中文：生成 SwiftPM 隔离消费者矩阵，但不把未执行的构建伪装成通过。

from __future__ import annotations

import json
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    products = json.loads((root / "report/spm/inventory/manifest_products.json").read_text())
    fixture_root = root / "Tests/SPMConsumerFixtures"
    fixture_root.mkdir(parents=True, exist_ok=True)
    aliases = {
        "PooToolsAll": "aggregate product; import the concrete product used by the consumer",
        "PooToolsNetwork": "product name maps to the PooToolsNetWork module",
        "PooToolsVideoCache": "product name maps to the ptools module",
    }
    matrix = {
        "generatedFrom": "swift package dump-package",
        "statusMeaning": "not_run is not a pass; a host Xcode consumer is required for build evidence",
        "products": [
            {
                "product": product["name"],
                "targets": product["targets"],
                "type": product.get("type"),
                "status": "not_run",
                "evidence": "",
                "notes": aliases.get(product["name"], ""),
            }
            for product in products
        ],
    }
    (fixture_root / "ProductImportMatrix.json").write_text(json.dumps(matrix, ensure_ascii=False, indent=2) + "\n")
    (fixture_root / "README.md").write_text(
        "# SwiftPM consumer fixtures\n\n"
        "This directory records the product/import matrix generated from the package manifest.\n"
        "It intentionally does not claim a build: isolated product builds require an iOS Xcode host.\n\n"
        "Use `Scripts/CI/build_spm_consumer_matrix.sh --require-build` with `SPM_CONSUMER_FIXTURE_PROJECT` "
        "and `SPM_CONSUMER_SCHEME` configured to record real Debug/Release evidence.\n"
        "\n"
        "这个目录只保存由 manifest 生成的 product/import 矩阵；`not_run` 不是通过。\n"
    )
    print(f"consumer_products={len(products)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
