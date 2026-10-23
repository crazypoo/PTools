#!/usr/bin/env python3
"""Inventory UIKit code and local-geometry risks for the iPhone Duo gate.

English: This is a conservative inventory, not a Swift parser or a proof of a bug.
Español: Este inventario es conservador; no es un parser de Swift ni prueba un bug.
中文：这是保守的清单工具，不是 Swift 语法解析器，也不能单凭命中证明存在 Bug。
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import subprocess
from datetime import datetime, timezone
from collections import defaultdict
from pathlib import Path


ROOTS = ("PooToolsSource", "Sources", "PooTools", "Example", "Tests")
AUDIT_RULE_VERSION = "5.69.0-duo-2026-10-23-r2"
REPORT_FILES = (
    "report/current/duo_uikit_inventory.csv",
    "report/current/duo_global_geometry_hits.json",
    "report/current/duo_coverage.md",
)

# English: These are the findings closed by this pass; device-only behavior stays pending.
# Español: Estos son los hallazgos cerrados en esta pasada; el comportamiento exclusivo del dispositivo queda pendiente.
# 中文：这些是本轮已关闭的审计项；只能在设备验证的行为继续保持 pending。
FOCUS_FINDINGS = {
    "DUO-A01": ("PooToolsSource/Core/PTMarcos_swift.swift", "display-only-allowed", "历史兼容全局值，仅允许展示/兼容读取"),
    "DUO-A02": ("PooToolsSource/Category/AutoScale+PTEX.swift", "fixed", "新增 View-local overload，旧入口保留兼容"),
    "DUO-A03": ("PooToolsSource/Inspector/ElementInspectorConfiguration.swift", "fixed", "面板宽度从宿主 bounds 解析"),
    "DUO-A04": ("PooToolsSource/WhereIsMyEye/PTEyeTrackingDataManager.swift", "fixed", "物理标定与 View 坐标映射分离"),
    "DUO-A05": ("PooToolsSource/Category/UIScreen+PTEX.swift", "display-only-allowed", "UIScreen.size 仅作为显示器元数据"),
    "DUO-A06": ("PooToolsSource/Category/CGFloat+PTEX.swift", "fixed", "旧安全区符号改为读取时解析"),
    "DUO-N01": ("PooToolsSource/Category/UIImageView+PTEX.swift", "fixed", "同一 Window 坐标系和可视 pane 判断"),
    "DUO-N02": ("PooToolsSource/PhotoPicker/PTMediaLibViewController.swift", "fixed", "fakeNav 使用本地 safe area 且幂等更新"),
    "DUO-N03": ("PooToolsSource/Base/PTBaseWebViewController.swift", "fixed", "WebView top constraint 使用实测局部导航边界"),
    "DUO-N04": ("PooToolsSource/MediaViewer/PTMediaBrowserCell.swift", "fixed", "零尺寸时延后解码而不是读取主屏"),
    "DUO-N05": ("PooToolsSource/LocalConsole/LocalConsole.swift", "fixed", "控制台方向和起始位置使用宿主 bounds"),
    "DUO-N06": ("PooToolsSource/Inspector/ViewHierarchyRoot.swift", "fixed", "Inspector 根节点跟随被检查 Window"),
    "DUO-N07": ("PooToolsSource/QRCodeScan/PTScanQRController.swift", "fixed", "扫码控件使用宿主 safe area"),
    "DUO-N08": ("PooToolsSource/DebugNetwork/PTNetworkWatcherViewController.swift", "fixed", "Debug overlay 使用当前控制器宿主"),
    "DUO-N09": ("PooToolsSource/Category/UIImage+PTEX.swift", "fixed", "像素化尺度脱离主屏幕宽度"),
}
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
    "kNavBarHeight_Total": re.compile(r"\bkNavBarHeight_Total\b"),
    "kTabbarHeight_Total": re.compile(r"\bkTabbar(?:SaveArea)?Height(?:_Total)?\b"),
    "safe-area-global": re.compile(r"\bk(?:Left|Right)SafeAreaWidth\b"),
    "AppWindows": re.compile(r"\bAppWindows\b"),
    "UIScreen.size": re.compile(r"\bUIScreen\.size\b"),
    "trait/device-idiom": re.compile(r"\b(?:UIDevice\.current\.userInterfaceIdiom|\.userInterfaceIdiom)\b"),
    "convert-to-nil": re.compile(r"\.convert\([^\n]*\bto:\s*nil\b"),
    "reloadData-layout": re.compile(r"\breloadData\s*\("),
    "magic-fixed-dimension": re.compile(
        r"(?:CGRect\(|CGSize\(|width\s*[:=]|height\s*[:=]).*\b(?:[1-9]\d{1,3}|0\.\d+)\b"
    ),
}


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_manifest(repo: Path, swift_files: list[Path]) -> tuple[list[dict[str, str]], str]:
    candidates = [repo / name for name in ("VERSION", "Package.swift", "PooTools.podspec", "PooTools/PTDemoCatalog.swift")]
    candidates.extend(swift_files)
    entries = []
    for path in sorted({path for path in candidates if path.is_file()}):
        relative = path.relative_to(repo).as_posix()
        entries.append({"path": relative, "sha256": sha256_file(path)})
    encoded = json.dumps(entries, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    return entries, hashlib.sha256(encoded).hexdigest()


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


def annotate_hits(repo: Path, hits: list[dict[str, object]], tests: dict[str, list[str]]) -> None:
    for hit in hits:
        relative = str(hit["path"])
        focus = next((decision for _, (path, decision, _) in FOCUS_FINDINGS.items() if path == relative), None)
        evidence = f"{relative}:{hit['line']}"
        hit["id"] = hashlib.sha1(f"{evidence}|{hit['kind']}|{hit['text']}".encode("utf-8")).hexdigest()[:12]
        hit["owner"] = module_for(repo, repo / relative)
        hit["target"] = hit["owner"]
        hit["evidence"] = evidence
        hit["layout_use"] = hit["kind"] not in {"magic-fixed-dimension", "UIScreen.main"} or bool(
            re.search(r"layout|constraint|frame|bounds|inset|center|width|height|top|bottom", str(hit["text"]), re.IGNORECASE)
        )
        hit["decision"] = focus or "needs-review"
        hit["test_id"] = ";".join(tests_for(str(hit["owner"]), tests))
        hit["test_owner"] = str(hit["owner"])
        hit["run_status"] = "pass_static" if focus in {"fixed", "display-only-allowed"} else "not_run"
        hit["reviewer"] = "PTools Duo audit"
        hit["reason"] = "focused finding reviewed" if focus else "candidate requires semantic review"


def write_reports(repo: Path, records: list[dict[str, object]], hits: list[dict[str, object]], demos: dict[str, list[str]], tests: dict[str, list[str]]) -> None:
    output = repo / "report" / "current"
    output.mkdir(parents=True, exist_ok=True)
    # English: Keep generated reports traceable to the source revision and audit run.
    # Español: Mantén los informes generados vinculados a la revisión fuente y a la ejecución de la auditoría.
    # 中文：让生成报告能够追溯到源码 revision 和本次审计执行时间。
    source_revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip()
    generated_at = datetime.now(timezone.utc).isoformat()
    swift_files = tracked_swift_files(repo)
    manifest_entries, manifest_hash = source_manifest(repo, swift_files)
    annotate_hits(repo, hits, tests)

    # English: Keep the inventory diffable on every platform by using LF records.
    # Español: Mantén el inventario comparable en todas las plataformas usando registros LF.
    # 中文：使用 LF 换行，让清单在所有平台上的 diff 保持稳定。
    with (output / "duo_uikit_inventory.csv").open("w", newline="", encoding="utf-8") as handle:
        fields = ["path", "module", "public_api", "ui_type", "ownership", "layout_mode", "risk", "coverage", "demo_id", "test_id", "status", "decision", "evidence", "test_owner", "run_status", "reviewer"]
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(records)

    (output / "duo_global_geometry_hits.json").write_text(
        json.dumps(
            {
                "generator": "Scripts/audit_duo_uikit_coverage.py",
                "generated_by": "Scripts/audit_duo_uikit_coverage.py",
                "source_revision": source_revision,
                "generated_at": generated_at,
                "rule_version": AUDIT_RULE_VERSION,
                "source_manifest_hash": manifest_hash,
                "source_manifest": manifest_entries,
                "hits": hits,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
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
        "<!--",
        "AUTO-GENERATED FILE.",
        "",
        "Generator: Scripts/audit_duo_uikit_coverage.py",
        f"Source revision: {source_revision}",
        f"Generated at: {generated_at}",
        f"Audit rule version: {AUDIT_RULE_VERSION}",
        f"Source manifest hash: {manifest_hash}",
        "-->",
        "",
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
        status = "needs-review" if module in missing else "mapped-by-module"
        lines.append(f"| `{module}` | {row['ui_files']} | {row['risks']} | {demos_text} | {tests_text} | {status} |")
    lines += [
        "",
        "## 覆盖规则 / Reglas / Rules",
        "",
        "`needs-review` 不等同于已确认 Bug；为资源、像素比例、调试诊断、真实硬件信息等用途建立 allowlist 后再转为 `mapped`。",
        "`needs-review` no significa bug confirmado; clasifica recursos, escala de píxeles, diagnóstico y hardware antes de marcar `mapped`.",
        "`mapped-by-module` is module-level evidence only; see decision, evidence, reviewer, and run_status in JSON.",
    ]
    (output / "duo_coverage.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    finding_lines = [
        "<!-- AUTO-GENERATED: Scripts/audit_duo_uikit_coverage.py -->",
        f"Source revision: {source_revision}",
        f"Generated at: {generated_at}",
        f"Audit rule version: {AUDIT_RULE_VERSION}",
        f"Source manifest hash: {manifest_hash}",
        "",
        "# iPhone Duo Findings Closure / Hallazgos / 审计项闭环",
        "",
        "| ID | 文件 | 决定 | 静态状态 | 运行/设备状态 | 说明 |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for finding_id, (path, decision, reason) in FOCUS_FINDINGS.items():
        static_status = "pass_static" if decision in {"fixed", "display-only-allowed"} else "pending"
        finding_lines.append(f"| `{finding_id}` | `{path}` | `{decision}` | `{static_status}` | `pending_device` | {reason} |")
    (output / "duo_findings_closed.md").write_text("\n".join(finding_lines) + "\n", encoding="utf-8")

    matrix_lines = [
        "<!-- AUTO-GENERATED: Scripts/audit_duo_uikit_coverage.py -->",
        f"Source revision: {source_revision}",
        f"Source manifest hash: {manifest_hash}",
        "",
        "# iPhone Duo Test Matrix / Matriz / 测试矩阵",
        "",
        "| Case | Static evidence | Build | Runtime/visual | Device |",
        "| --- | --- | --- | --- | --- |",
    ]
    for case in ("DUO-T01", "DUO-T02", "DUO-T03", "DUO-T04", "DUO-T05", "DUO-T06", "DUO-T07", "DUO-T08", "DUO-T09", "DUO-T10"):
        matrix_lines.append(f"| `{case}` | pending | pending | pending | pending_device |")
    (output / "duo_test_matrix.md").write_text("\n".join(matrix_lines) + "\n", encoding="utf-8")


def check_report_freshness(repo: Path, strict: bool = False) -> int:
    report = repo / "report/current/duo_global_geometry_hits.json"
    if not report.is_file():
        print("STALE: missing report/current/duo_global_geometry_hits.json")
        return 1
    try:
        payload = json.loads(report.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        print(f"STALE: invalid Duo report: {error}")
        return 1

    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip()
    _, manifest_hash = source_manifest(repo, tracked_swift_files(repo))
    errors = []
    if payload.get("source_revision") != revision:
        errors.append("source_revision does not match HEAD")
    if payload.get("rule_version") != AUDIT_RULE_VERSION:
        errors.append("rule_version is stale")
    if payload.get("source_manifest_hash") != manifest_hash:
        errors.append("source_manifest_hash does not match the current worktree")
    required_hit_fields = {"id", "owner", "target", "evidence", "decision", "test_id", "test_owner", "run_status", "reviewer"}
    for hit in payload.get("hits", []):
        missing = required_hit_fields.difference(hit)
        if missing:
            errors.append(f"hit {hit.get('path')}:{hit.get('line')} missing {sorted(missing)}")
    if strict:
        for finding_id, (path, decision, _) in FOCUS_FINDINGS.items():
            if decision not in {"fixed", "display-only-allowed"}:
                errors.append(f"{finding_id} is not statically closed: {path}")
        for filename in ("duo_findings_closed.md", "duo_test_matrix.md"):
            if not (repo / "report/current" / filename).is_file():
                errors.append(f"missing {filename}")
    if errors:
        print("STALE/FAIL: Duo report gate")
        for error in errors:
            print(f"- {error}")
        return 1
    print("PASS: Duo report freshness and metadata")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("repo", nargs="?", default=".")
    parser.add_argument("--strict", action="store_true", help="Fail when the focused Duo findings or report metadata are not closed.")
    parser.add_argument("--check", action="store_true", help="Check existing reports without regenerating them.")
    args = parser.parse_args()
    repo = Path(args.repo).resolve()
    if args.check:
        return check_report_freshness(repo, strict=args.strict)
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
            risk = "high" if any(hit["kind"] in {"UIScreen.main", "kSCREEN", "keyWindow", "screen.bounds", "kNavBarHeight_Total", "kTabbarHeight_Total", "safe-area-global", "AppWindows", "convert-to-nil"} for hit in file_hits) else "medium"
            coverage = "mapped-by-module" if module_demos or module_tests or module.startswith("Tests/") else "needs-review"
        elif is_swiftui:
            kind, risk, coverage = "swiftui-only", "low", "not-applicable"
        elif is_foundation_only:
            kind, risk, coverage = "not-ui", "none", "not-applicable"
        else:
            kind, risk, coverage = "not-ui", "low", "not-applicable"
        relative = path.relative_to(repo).as_posix()
        focus_decision = next((decision for _, (focus_path, decision, _) in FOCUS_FINDINGS.items() if focus_path == relative), "not-applicable")
        evidence = ";".join(f"{relative}:{hit['line']}" for hit in file_hits)
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
            "decision": focus_decision if file_hits or focus_decision != "not-applicable" else "not-reviewed",
            "evidence": evidence,
            "test_owner": module,
            "run_status": "pass_static" if focus_decision in {"fixed", "display-only-allowed"} else "not_run",
            "reviewer": "PTools Duo audit" if focus_decision != "not-applicable" else "",
        })
    write_reports(repo, records, hits, demos, tests)
    ui_records = [record for record in records if record["ui_type"] not in {"not-ui", "swiftui-only"}]
    missing = [record for record in ui_records if record["coverage"] == "needs-review"]
    print(f"UIKit inventory: {len(ui_records)} files")
    print(f"Global geometry candidates: {len(hits)}")
    print(f"Coverage candidates: {len(missing)}")
    if args.strict:
        return check_report_freshness(repo, strict=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
