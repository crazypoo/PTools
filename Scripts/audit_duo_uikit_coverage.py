#!/usr/bin/env python3
"""Inventory UIKit code and local-geometry risks for the iPhone Duo gate.

English: This is a conservative inventory, not a Swift parser or a proof of a bug.
Español: Este inventario es conservador; no es un parser de Swift ni prueba un bug.
中文：这是保守的清单工具，不是 Swift 语法解析器，也不能单凭命中证明存在 Bug。
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path


ROOTS = ("PooToolsSource", "Sources", "PooTools", "Example", "Tests")
UI_IMPORT = re.compile(r"^\s*import\s+UIKit(?:\.|$)", re.MULTILINE)
SWIFTUI_IMPORT = re.compile(r"^\s*import\s+SwiftUI(?:\.|$)", re.MULTILINE)
UI_SYMBOLS = re.compile(
    r"\b(?:UIView|UIViewController|UICollectionView|UITableView|UIScrollView|"
    r"UIWindowScene|UIPresentationController|UIBarButtonItem|UITabBarItem)\b"
)
EXTENSION_UI = re.compile(
    r"\bextension\s+(?:UIView|UIViewController|UICollectionView|UITableView|"
    r"UIScrollView|UIWindow|UIControl|UILabel|UIImageView|UIButton)\b"
)
PUBLIC_API = re.compile(r"\b(?:public|open)\b|@objc")

# English: Map source folders to the canonical demo owners used by the catalog.
# Español: Mapea carpetas de código a los propietarios canónicos del catálogo de demos.
# 中文：将源码目录映射到 Demo 目录使用的规范模块归属。
MODULE_DEMO_ALIASES = {
    "ActionsheetAndAlert": ("PToolsUIFoundation",),
    "Base": ("PToolsUIFoundation",),
    "Category": ("PToolsUIFoundation",),
    "CollectionView": ("PToolsUIFoundation",),
    "ImageEditor": ("PooToolsImageEditor",),
    "MediaViewer": ("PooToolsMediaViewer",),
    "MessageKit": ("PooToolsMessageKit",),
    "Overlay": ("PToolsOverlay",),
    "Popover": ("PToolsOverlay",),
    "PhotoPicker": ("PooToolsPhotoPicker",),
    "Picker": ("PooToolsPhotoPicker",),
    "SegmentControl": ("PooToolsSegmented", "PToolsUIFoundation"),
    "Segmented": ("PooToolsSegmented",),
    "SplitView": ("PooToolsSplitView",),
    "VideoEditor": ("PooToolsVideoEditor",),
    "Debug": ("PooToolsDEBUG",),
    "LocalConsole": ("PooToolsDEBUG",),
    "Guide": ("PooToolsDEBUG",),
}

# English: Preserve line numbers while removing comments from static matching.
# Español: Conserva los números de línea mientras elimina comentarios del análisis estático.
# 中文：静态扫描去除注释时保留行号，方便报告定位。
def without_comments(text: str) -> str:
    def blank_block(match: re.Match[str]) -> str:
        return "".join("\n" if char == "\n" else " " for char in match.group(0))

    text = re.sub(r"/\*.*?\*/", blank_block, text, flags=re.DOTALL)
    return re.sub(r"//[^\n]*", "", text)

GLOBAL_PATTERNS = {
    "UIScreen.main": re.compile(r"UIScreen\.main(?:Screen)?"),
    "kSCREEN": re.compile(r"\bkSCREEN(?:_|\b)"),
    "statusBarHeight": re.compile(r"\bstatusBarHeight\b"),
    "UIDevice.current.orientation": re.compile(r"UIDevice\.current\.orientation"),
    "isFaceIDCapable": re.compile(r"\bisFaceIDCapable\b"),
    "keyWindow": re.compile(r"\bkeyWindow\b"),
    "screen.bounds": re.compile(r"\bscreen\.bounds\b|\bwindow\.screen\.bounds\b"),
    "magic-fixed-dimension": re.compile(
        r"(?:CGRect\(|CGSize\(|width\s*[:=]|height\s*[:=]).*\b(?:[1-9]\d{1,3}|0\.\d+)\b"
    ),
}


def tracked_swift_files(repo: Path) -> list[Path]:
    try:
        result = subprocess.run(
            ["git", "-C", str(repo), "ls-files", "--", *[f"{root}/**/*.swift" for root in ROOTS]],
            check=True,
            text=True,
            capture_output=True,
        )
        paths = [repo / line for line in result.stdout.splitlines() if line.endswith(".swift")]
    except (OSError, subprocess.CalledProcessError):
        paths = [path for root in ROOTS for path in (repo / root).rglob("*.swift")]
    return sorted(set(path for path in paths if path.is_file()))


def module_for(repo: Path, path: Path) -> str:
    relative = path.relative_to(repo).as_posix()
    parts = relative.split("/")
    if parts[0] == "PooToolsSource" and len(parts) > 1:
        return parts[1]
    if parts[0] == "Sources" and len(parts) > 2:
        return f"Sources/{parts[1]}"
    if parts[0] == "Tests" and len(parts) > 1:
        return f"Tests/{parts[1]}"
    return parts[0]


def ui_type(text: str, path: Path) -> str:
    name = path.stem.lower()
    if "viewcontroller" in name or re.search(r"class\s+\w+\s*:\s*\w*ViewController", text):
        return "view-controller"
    if "collection" in name or "table" in name:
        return "list"
    if "bar" in name or "navigation" in name or "tab" in name:
        return "bar"
    if "present" in name or "alert" in name or "sheet" in name or "popover" in name:
        return "presentation"
    if EXTENSION_UI.search(text):
        return "ui-extension"
    if "UIView" in text or "UIControl" in text:
        return "view"
    return "ui-helper"


def ownership(path: Path, module: str) -> str:
    if path.parts and path.parts[0] == "Tests":
        return "test"
    if path.parts and path.parts[0] in {"PooTools", "Example"}:
        return "example"
    return module


def extract_hits(text: str, path: Path) -> list[dict[str, object]]:
    hits: list[dict[str, object]] = []
    for number, line in enumerate(text.splitlines(), start=1):
        for kind, pattern in GLOBAL_PATTERNS.items():
            if pattern.search(line):
                hits.append({"kind": kind, "path": path.as_posix(), "line": number, "text": line.strip()})
    return hits


def layout_mode(text: str, hits: list[dict[str, object]]) -> str:
    if any(hit["kind"] in {"UIScreen.main", "kSCREEN", "statusBarHeight", "keyWindow", "screen.bounds"} for hit in hits):
        return "global-geometry-risk"
    if re.search(r"PTAdaptive|safeArea|reservedRegions|layoutGuide|frameLayoutGuide|keyboardLayoutGuide", text):
        return "container-local"
    if re.search(r"\bbounds\b|\bframe\b|layoutSubviews|traitCollection", text):
        return "local-or-unclassified"
    return "not-layout"


def demo_ids(repo: Path) -> dict[str, list[str]]:
    catalog = repo / "PooTools" / "PTDemoCatalog.swift"
    if not catalog.is_file():
        return {}
    result: dict[str, list[str]] = defaultdict(list)
    pattern = re.compile(r'make\("([^"]+)",\s*"([^"]+)"')
    for demo_id, module in pattern.findall(catalog.read_text(encoding="utf-8")):
        result[module].append(demo_id)
    return dict(result)


def test_ids(repo: Path) -> dict[str, list[str]]:
    result: dict[str, list[str]] = defaultdict(list)
    for path in (repo / "Tests").rglob("*.swift"):
        text = path.read_text(encoding="utf-8", errors="replace")
        for name in re.findall(r"\bfunc\s+(test\w+)\s*\(", text):
            result[path.parent.name].append(name)
    return dict(result)


def demos_for(module: str, demos: dict[str, list[str]]) -> list[str]:
    owners = (module,) + MODULE_DEMO_ALIASES.get(module, ())
    values: list[str] = []
    for owner in owners:
        for demo_id in demos.get(owner, []):
            if demo_id not in values:
                values.append(demo_id)
    return values


def tests_for(module: str, tests: dict[str, list[str]]) -> list[str]:
    values = list(tests.get(module, []))
    if module in {"Base", "Category", "SegmentControl", "Segmented", "PhotoPicker", "MediaViewer", "VideoEditor"}:
        for test_id in tests.get("PToolsUIFoundationTests", []):
            if test_id not in values:
                values.append(test_id)
    return values


def write_reports(repo: Path, records: list[dict[str, object]], hits: list[dict[str, object]], demos: dict[str, list[str]], tests: dict[str, list[str]]) -> None:
    output = repo / "report" / "current"
    output.mkdir(parents=True, exist_ok=True)

    with (output / "duo_uikit_inventory.csv").open("w", newline="", encoding="utf-8") as handle:
        fields = ["path", "module", "public_api", "ui_type", "ownership", "layout_mode", "risk", "coverage", "demo_id", "test_id", "status"]
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(records)

    (output / "duo_global_geometry_hits.json").write_text(
        json.dumps({"generated_by": "Scripts/audit_duo_uikit_coverage.py", "hits": hits}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    module_rows: dict[str, dict[str, object]] = {}
    for record in records:
        if record["ownership"] in {"test", "example"}:
            continue
        module = str(record["module"])
        row = module_rows.setdefault(module, {"files": 0, "ui_files": 0, "risks": 0, "demos": demos_for(module, demos), "tests": tests_for(module, tests)})
        row["files"] += 1
        if record["ui_type"] != "not-ui":
            row["ui_files"] += 1
        if record["risk"] == "high":
            row["risks"] += 1
    missing = [module for module, row in module_rows.items() if row["ui_files"] and not row["demos"] and not row["tests"]]
    lines = [
        "# iPhone Duo UIKit 覆盖报告 / Cobertura UIKit / UIKit Coverage",
        "",
        "生成：`Scripts/audit_duo_uikit_coverage.py`。关键字命中只代表候选风险，必须结合调用语义确认。",
        "Generado por `Scripts/audit_duo_uikit_coverage.py`; los aciertos son candidatos y requieren revisión semántica.",
        "Generated by `Scripts/audit_duo_uikit_coverage.py`; matches are candidates and require semantic review.",
        "",
        f"- UIKit 文件 / archivos UIKit / UIKit files: {sum(int(row['ui_files']) for row in module_rows.values())}",
        f"- 全局几何候选 / candidatos globales / global candidates: {len(hits)}",
        f"- 未映射模块 / módulos sin cobertura / uncovered modules: {len(missing)}",
        "",
        "## 模块状态 / Estado / Status",
        "",
        "| 模块 | UIKit 文件 | 高风险 | Demo | 测试 | 状态 |",
        "| --- | ---: | ---: | --- | --- | --- |",
    ]
    for module in sorted(module_rows):
        row = module_rows[module]
        demos_text = ", ".join(row["demos"]) or "—"
        tests_text = ", ".join(row["tests"]) or "—"
        status = "needs-review" if module in missing else "mapped"
        lines.append(f"| `{module}` | {row['ui_files']} | {row['risks']} | {demos_text} | {tests_text} | {status} |")
    lines += [
        "",
        "## 覆盖规则 / Reglas / Rules",
        "",
        "`needs-review` 不等同于已确认 Bug；为资源、像素比例、调试诊断、真实硬件信息等用途建立 allowlist 后再转为 `mapped`。",
        "`needs-review` no significa bug confirmado; clasifica recursos, escala de píxeles, diagnóstico y hardware antes de marcar `mapped`.",
        "`needs-review` is not a confirmed bug; classify resource, pixel-scale, diagnostics, and hardware uses before marking `mapped`.",
    ]
    (output / "duo_coverage.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("repo", nargs="?", default=".")
    parser.add_argument("--strict", action="store_true", help="Fail when a UIKit module has neither a demo nor a test.")
    args = parser.parse_args()
    repo = Path(args.repo).resolve()
    demos = demo_ids(repo)
    tests = test_ids(repo)
    records: list[dict[str, object]] = []
    hits: list[dict[str, object]] = []
    for path in tracked_swift_files(repo):
        text = path.read_text(encoding="utf-8", errors="replace")
        scan_text = without_comments(text)
        is_ui = bool(UI_IMPORT.search(scan_text) or UI_SYMBOLS.search(scan_text) or EXTENSION_UI.search(scan_text))
        is_swiftui = bool(SWIFTUI_IMPORT.search(scan_text))
        is_foundation_only = "import Foundation" in scan_text and not is_ui and not is_swiftui
        file_hits = extract_hits(scan_text, path.relative_to(repo))
        hits.extend(file_hits)
        module = module_for(repo, path)
        module_demos = demos_for(module, demos)
        module_tests = tests_for(module, tests)
        if is_ui:
            kind = ui_type(text, path)
            risk = "high" if any(hit["kind"] in {"UIScreen.main", "kSCREEN", "keyWindow", "screen.bounds"} for hit in file_hits) else "medium"
            coverage = "mapped" if module_demos or module_tests or module.startswith("Tests/") else "needs-review"
        elif is_swiftui:
            kind, risk, coverage = "swiftui-only", "low", "not-applicable"
        elif is_foundation_only:
            kind, risk, coverage = "not-ui", "none", "not-applicable"
        else:
            kind, risk, coverage = "not-ui", "low", "not-applicable"
        relative = path.relative_to(repo).as_posix()
        records.append({
            "path": relative,
            "module": module,
            "public_api": "yes" if PUBLIC_API.search(text) else "no",
            "ui_type": kind,
            "ownership": ownership(path.relative_to(repo), module),
            "layout_mode": layout_mode(text, file_hits),
            "risk": risk,
            "coverage": coverage,
            "demo_id": ";".join(module_demos),
            "test_id": ";".join(module_tests),
            "status": "candidate" if file_hits else "inventory",
        })
    write_reports(repo, records, hits, demos, tests)
    ui_records = [record for record in records if record["ui_type"] not in {"not-ui", "swiftui-only"}]
    missing = [record for record in ui_records if record["coverage"] == "needs-review"]
    print(f"UIKit inventory: {len(ui_records)} files")
    print(f"Global geometry candidates: {len(hits)}")
    print(f"Coverage candidates: {len(missing)}")
    return 1 if args.strict and missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
