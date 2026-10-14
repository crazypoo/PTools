#!/usr/bin/env python3
# English: Build the authoritative SwiftPM target, product, source, and resource inventory.
# Español: Construye el inventario autoritativo de targets, productos, fuentes y recursos de SwiftPM.
# 中文：生成权威的 SwiftPM target、product、源码和资源清单。

from __future__ import annotations

import argparse
import csv
import json
import subprocess
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any


def run_json(command: list[str], cwd: Path) -> dict[str, Any]:
    result = subprocess.run(command, cwd=cwd, text=True, capture_output=True)
    if result.returncode != 0:
        raise RuntimeError(f"{' '.join(command)} failed:\n{result.stderr}")
    return json.loads(result.stdout)


def relative_path(path: Path, root: Path) -> str:
    try:
        return str(path.resolve().relative_to(root.resolve()))
    except ValueError:
        return str(path)


def expand_source_entry(root: Path, target_root: Path, entry: str) -> list[Path]:
    candidate = target_root / entry
    if candidate.is_file():
        return [candidate]
    if candidate.is_dir():
        return sorted(candidate.rglob("*.swift"))
    return []


def target_sources(root: Path, manifest_target: dict[str, Any], described: dict[str, Any]) -> list[str]:
    target_root = root / manifest_target.get("path", manifest_target["name"])
    described_sources = described.get("sources") or []
    if described_sources:
        # SwiftPM describe reports source paths relative to the target path.
        # SwiftPM describe informa rutas relativas al directorio del target.
        # SwiftPM describe 返回的是相对于 target 目录的源码路径。
        paths = [target_root / source if str(source).startswith("/") is False else Path(source)
                 for source in described_sources]
    else:
        entries = manifest_target.get("sources") or []
        paths = [path for entry in entries for path in expand_source_entry(root, target_root, entry)]
        if not entries and target_root.exists():
            paths = sorted(target_root.rglob("*.swift"))
    excluded = {str(target_root / entry).resolve() for entry in manifest_target.get("exclude", [])}
    result = []
    for path in paths:
        resolved = path.resolve()
        if resolved.suffix != ".swift" or resolved in excluded or not resolved.exists():
            continue
        result.append(relative_path(resolved, root))
    return sorted(set(result))


def detect_cycles(graph: dict[str, list[str]]) -> list[list[str]]:
    cycles: list[list[str]] = []
    stack: list[str] = []
    active: set[str] = set()
    visited: set[str] = set()

    def visit(node: str) -> None:
        if node in active:
            start = stack.index(node)
            cycles.append(stack[start:] + [node])
            return
        if node in visited:
            return
        active.add(node)
        stack.append(node)
        for dependency in graph.get(node, []):
            if dependency in graph:
                visit(dependency)
        stack.pop()
        active.remove(node)
        visited.add(node)

    for node in graph:
        visit(node)
    return cycles


def write_json(path: Path, value: Any) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=Path(__file__).resolve().parents[2], type=Path)
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()
    root = args.root.resolve()
    output = root / "report/spm"
    inventory = output / "inventory"
    inventory.mkdir(parents=True, exist_ok=True)

    manifest = run_json(["swift", "package", "dump-package"], root)
    description = run_json(["swift", "package", "describe", "--type", "json"], root)
    described_targets = {target["name"]: target for target in description.get("targets", [])}
    manifest_targets = {target["name"]: target for target in manifest.get("targets", [])}

    normalized_targets: list[dict[str, Any]] = []
    source_owners: dict[str, list[str]] = defaultdict(list)
    anomalies: list[dict[str, Any]] = []
    graph: dict[str, list[str]] = {}
    for name in sorted(manifest_targets):
        target = manifest_targets[name]
        described_target = described_targets.get(name, {})
        sources = target_sources(root, target, described_target)
        target_path = root / target.get("path", name)
        if not target_path.exists() and target.get("type") not in {"system", "binary", "plugin"}:
            anomalies.append({"kind": "missing-target-path", "target": name, "path": str(target_path)})
        if not sources and target.get("type") in {"regular", "test", "executable", "macro"}:
            anomalies.append({"kind": "target-without-swift-source", "target": name, "path": target.get("path", name)})
        dependencies = list(described_target.get("target_dependencies", []))
        graph[name] = sorted(set(dependencies))
        normalized_targets.append({
            "name": name,
            "type": target.get("type"),
            "path": target.get("path", name),
            "sources": sources,
            "source_count": len(sources),
            "dependencies": sorted(set(dependencies)),
            "product_memberships": described_target.get("product_memberships", []),
            "resources": target.get("resources", []),
            "swift_settings": target.get("settings", []),
        })
        for source in sources:
            source_owners[source].append(name)

    for source, owners in sorted(source_owners.items()):
        if len(owners) > 1:
            anomalies.append({"kind": "multiple-source-owners", "source": source, "owners": owners})

    products = []
    for product in sorted(manifest.get("products", []), key=lambda item: item["name"]):
        products.append({
            "name": product["name"],
            "type": product.get("type"),
            "targets": product.get("targets", []),
        })

    write_json(inventory / "manifest_products.json", products)
    write_json(inventory / "manifest_targets.json", normalized_targets)
    write_json(inventory / "source_ownership.json", {
        "generated_from": "swift package dump-package + swift package describe --type json",
        "source_count": len(source_owners),
        "owners": {source: sorted(owners) for source, owners in sorted(source_owners.items())},
    })
    with (inventory / "source_ownership_anomalies.csv").open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["kind", "target", "source", "path", "owners"])
        writer.writeheader()
        for anomaly in anomalies:
            writer.writerow({
                "kind": anomaly.get("kind", ""),
                "target": anomaly.get("target", ""),
                "source": anomaly.get("source", ""),
                "path": anomaly.get("path", ""),
                "owners": ";".join(anomaly.get("owners", [])),
            })

    with (inventory / "target_dependency_graph.dot").open("w") as handle:
        handle.write("digraph PToolsSwiftPM {\n")
        for target, dependencies in sorted(graph.items()):
            if not dependencies:
                handle.write(f'  "{target}";\n')
            for dependency in dependencies:
                handle.write(f'  "{target}" -> "{dependency}";\n')
        handle.write("}\n")

    package_platforms = [platform.get("platformName", platform.get("platform", ""))
                         for platform in manifest.get("platforms", [])]
    with (inventory / "platform_support.csv").open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["product", "targets", "type", "package_platforms", "iOS_applicable"])
        writer.writeheader()
        for product in products:
            writer.writerow({
                "product": product["name"],
                "targets": ";".join(product["targets"]),
                "type": json.dumps(product["type"], ensure_ascii=False),
                "package_platforms": ";".join(package_platforms),
                "iOS_applicable": "yes" if any("ios" in value.lower() for value in package_platforms) else "unknown",
            })

    matrix_path = output / "spm_product_matrix.csv"
    previous_matrix: dict[str, dict[str, str]] = {}
    if matrix_path.exists():
        with matrix_path.open(newline="") as handle:
            for row in csv.DictReader(handle):
                if row.get("product"):
                    previous_matrix[row["product"]] = row
    with matrix_path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["product", "targets", "type", "status", "evidence"])
        writer.writeheader()
        for product in products:
            previous = previous_matrix.get(product["name"], {})
            writer.writerow({
                "product": product["name"],
                "targets": ";".join(product["targets"]),
                "type": json.dumps(product["type"], ensure_ascii=False),
                "status": previous.get("status", "not_run"),
                "evidence": previous.get("evidence", ""),
            })

    cycles = detect_cycles(graph)
    sha = subprocess.run(["git", "rev-parse", "HEAD"], cwd=root, text=True, capture_output=True).stdout.strip()
    baseline = output / "SPM_BASELINE.md"
    baseline.write_text(
        "# PTools SwiftPM 全仓审计基线\n\n"
        f"- 生成 SHA：`{sha}`\n"
        f"- target 数量：{len(normalized_targets)}\n"
        f"- product 数量：{len(products)}\n"
        f"- Swift 源文件归属数量：{len(source_owners)}\n"
        f"- 归属异常数量：{len(anomalies)}\n"
        f"- 依赖环数量：{len(cycles)}\n\n"
        "本报告由 `Scripts/CI/audit_spm_target_graph.py` 根据 SwiftPM manifest 和 describe 动态生成。\n"
        "`not_run` 只表示产品构建矩阵尚未在当前运行中执行，不代表通过。\n"
    )

    print(f"targets={len(normalized_targets)} products={len(products)} sources={len(source_owners)} anomalies={len(anomalies)} cycles={len(cycles)}")
    if args.strict and (anomalies or cycles):
        return 1
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, json.JSONDecodeError) as error:
        print(f"audit_spm_target_graph.py: {error}", file=sys.stderr)
        raise SystemExit(2)
