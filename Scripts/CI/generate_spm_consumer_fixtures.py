#!/usr/bin/env python3
# English: Generate real per-product SwiftPM consumer sources; generation never means a build passed.
# Español: Genera fuentes reales de consumidor por producto SwiftPM; generar nunca significa que la compilación pasó.
# 中文：生成每个 SwiftPM product 的真实消费者源码；生成文件不代表构建通过。

from __future__ import annotations

import json
import re
from pathlib import Path


def safe_name(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", value)


def module_names(product: dict) -> list[str]:
    name = product["name"]
    if name == "PooToolsAll":
        return ["ptools", "PToolsCore", "PooToolsPageControl"]
    if name == "PooToolsNetwork":
        return ["PooToolsNetWork"]
    if name == "PooToolsVideoCache":
        return ["ptools"]
    return list(product.get("targets", []))


def product_kind(product: dict) -> str:
    return "library" if "library" in product.get("type", {}) else "executable"


def source_for(product: dict, modules: list[str]) -> str:
    imports = "\n".join(f"import {module}" for module in modules)
    return f'''// English: Minimal iOS host source for the isolated SwiftPM product {product["name"]}.
// Español: Fuente mínima del host iOS para el producto SwiftPM aislado {product["name"]}.
// 中文：用于隔离验证 SwiftPM product {product["name"]} 的最小 iOS 宿主源码。
import UIKit
{imports}

@main
final class ConsumerApp: UIResponder, UIApplicationDelegate {{
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {{
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()
        return true
    }}
}}
'''


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    products = json.loads((root / "report/spm/inventory/manifest_products.json").read_text())
    fixture_root = root / "Tests/SPMConsumerFixtures"
    generated_root = fixture_root / "Generated"
    generated_root.mkdir(parents=True, exist_ok=True)
    index: list[dict] = []
    for product in products:
        kind = product_kind(product)
        modules = module_names(product) if kind == "library" else []
        safe = safe_name(product["name"])
        product_dir = generated_root / safe
        product_dir.mkdir(parents=True, exist_ok=True)
        if kind == "library":
            (product_dir / "ImportSmoke.swift").write_text(source_for(product, modules))
            (product_dir / "APISmoke.swift").write_text(
                "// English: Import-only smoke coverage is intentional; product APIs differ.\n"
                "// Español: La cobertura de humo solo importa el módulo porque las APIs varían.\n"
                "// 中文：这里只做模块导入冒烟检查，因为各 product API 不同。\n"
                "import UIKit\n"
                + "\n".join(f"import {module}" for module in modules)
                + "\n"
            )
        index.append({
            "product": product["name"],
            "targets": product.get("targets", []),
            "modules": modules,
            "kind": kind,
            "targetName": f"SPMConsumer_{safe}" if kind == "library" else "",
            "status": "not_run" if kind == "library" else "not_applicable",
        })

    (generated_root / "ProductIndex.json").write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n")
    (fixture_root / "ProductImportMatrix.json").write_text(json.dumps({
        "generatedFrom": "swift package dump-package",
        "statusMeaning": "not_run is not a pass; each library product requires an independent iOS host build",
        "products": index,
    }, ensure_ascii=False, indent=2) + "\n")
    (fixture_root / "README.md").write_text(
        "# SwiftPM consumer fixtures\n\n"
        "Generated sources cover every library product and are consumed by `Tests/SPMConsumerHost`.\n"
        "The generated status is `not_run` until the independent Xcode target is built.\n\n"
        "生成源码覆盖每个 library product；只有 Xcode 独立 consumer target 构建成功后才能记录 pass。\n"
    )
    print(f"consumer_products={len(index)} library_products={sum(item['kind'] == 'library' for item in index)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
