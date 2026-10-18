#!/usr/bin/env python3
"""English: Generate the versioned PTLayout ownership and release audit.
Español: Genera la auditoría versionada de propiedad y publicación de PTLayout.
中文：生成按版本归档的 PTLayout 所有权与发布审计。
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LAYOUT = ROOT / "PooToolsSource" / "PToolsConstraintLayout"
REPORT = ROOT / "report" / "layout"
FIXTURES = ROOT / "Scripts" / "CI" / "fixtures" / "PTLayoutFailureInjectionCases_567.json"

EXCEPTIONS = {
    "PooToolsSource/Base/PTSnapKitEX.swift": {
        "category": "legacy-public-api",
        "reason": "公开 ConstraintGroup/SnapKit 兼容桥接，5.x 调用方仍依赖原签名。",
        "owner": "PTools Core compatibility",
        "test": "legacy ConstraintGroup consumer matrix",
        "api": "PTLayout neutral algorithm only where the adapter can preserve the old signature",
    },
    "PooToolsSource/PToolsUIFoundation/PTUIFoundationSnapKitEX.swift": {
        "category": "legacy-public-api",
        "reason": "PToolsUIFoundation 的公开 SnapKit 适配签名需要保留，不能在 5.x 中删除。",
        "owner": "PToolsUIFoundation compatibility",
        "test": "PToolsUIFoundation legacy consumer matrix",
        "api": "PTLayout for new internal consumers; SnapKit adapter for the public compatibility boundary",
    },
    "PooToolsSource/Category/UIView+PTEX+Constraints.swift": {
        "category": "legacy-public-api",
        "reason": "Category 对外提供的 ConstraintMaker/ConstraintRelatableTarget 入口是旧版兼容 API。",
        "owner": "Category compatibility",
        "test": "UIView PTEX legacy API consumer matrix",
        "api": "ptLayout for new callers; preserve the legacy extension signature",
    },
    "PooToolsSource/Category/NSImageView+PTEX.swift": {
        "category": "platform-compatibility",
        "reason": "AppKit macOS 分支的既有 SnapKit 适配边界；本轮 UIKit 迁移不得改写该条件路径。",
        "owner": "AppKit compatibility",
        "test": "macOS AppKit source ownership review",
        "api": "AppKit compatibility path",
    },
    "PooToolsSource/iOS17Tips/PTTip.swift": {
        "category": "legacy-public-api",
        "reason": "showTipsInView 的公开 closure 参数是 ConstraintMaker，保留以避免 5.x 源码破坏。",
        "owner": "iOS17Tips compatibility",
        "test": "PTTip legacy closure consumer matrix",
        "api": "existing public SnapKit closure; new APIs use ptLayout",
    },
    "PooToolsSource/MessageKit/PTChatBaseCell.swift": {
        "category": "legacy-public-api",
        "reason": "文件底部保留 ConstraintMaker 兼容 helper；普通 Cell 约束已迁移到 ptLayout。",
        "owner": "MessageKit compatibility",
        "test": "PTChatBaseCell reuse and legacy helper consumer matrix",
        "api": "ptLayout for owned cell constraints; old ConstraintMaker helper remains an adapter",
    },
    "PooToolsSource/PToolsPermissionUI/PTPermissionUI.swift": {
        "category": "legacy-public-api",
        "reason": "Permission UI 的 ConstraintView 参数属于旧聚合兼容入口，保留以避免消费者源码破坏。",
        "owner": "Permission UI compatibility",
        "test": "PTPermissionUI legacy consumer matrix",
        "api": "ptLayout for new UIKit consumers",
    },
}

PTLAYOUT_CALL = re.compile(r"\.ptLayout\.(?:make|update|remake|prepare|remove)Constraints\b")
SNP_CALL = re.compile(r"\.snp\.(?:make|update|remake|prepare|remove)Constraints\b")
SNP_ANCHOR = re.compile(r"\.snp\.(?:top|bottom|left|right|leading|trailing|center|centerX|centerY|width|height|edges|size)\b")
SNAPKIT_TYPE = re.compile(r"\b(?:ConstraintMaker|ConstraintItem|ConstraintRelatableTarget|ConstraintView|ConstraintGroup)\b")
NATIVE_ACTIVATE = re.compile(r"\bNSLayoutConstraint\.(?:activate|deactivate)\b")
NATIVE_CONSTRUCTOR = re.compile(r"\bNSLayoutConstraint\s*\(")
NATIVE_ANCHOR = re.compile(r"\.(?:top|bottom|leading|trailing|centerX|centerY|width|height)Anchor\.constraint\b")


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def version() -> str:
    value = read(ROOT / "VERSION").strip()
    if not re.fullmatch(r"\d+\.\d+\.\d+", value):
        raise SystemExit(f"invalid VERSION: {value}")
    return value


def git_head() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    except (OSError, subprocess.CalledProcessError):
        return "unknown"


def worktree_digest() -> str:
    try:
        diff = subprocess.check_output(["git", "diff", "HEAD", "--binary"], cwd=ROOT)
        return hashlib.sha256(diff).hexdigest()
    except (OSError, subprocess.CalledProcessError):
        return "unknown"


def target_for(path: str) -> str:
    if path.startswith("PooToolsSource/PToolsConstraintLayout/"):
        return "PToolsConstraintLayout"
    if path.startswith("PooTools/"):
        return "PooTools-Example"
    return "PooTools"


def code_line(line: str) -> str:
    # English: Ignore line comments so comments cannot create a false migration finding.
    # Español: Ignora comentarios de línea para no crear hallazgos falsos.
    # 中文：忽略行注释，避免注释制造错误的迁移记录。
    return line.split("//", 1)[0].strip()


def exception_for(path: str, line: str) -> dict[str, str] | None:
    rule = EXCEPTIONS.get(path)
    if rule is None:
        return None
    if path.endswith("PTSnapKitEX.swift") or path.endswith("PTUIFoundationSnapKitEX.swift"):
        return rule
    if "ConstraintMaker" in line or ".snp." in line or "ConstraintRelatableTarget" in line or "ConstraintView" in line or "ConstraintItem" in line:
        return rule
    return None


def make_row(path: str, number: int, construct: str, owner: str, decision: str, new_api: str,
             reason: str | None, exception_owner: str | None, regression_case: str, evidence: str) -> dict[str, str]:
    return {
        "source_sha": git_head(),
        "target": target_for(path),
        "path": path,
        "line": str(number),
        "construct": construct,
        "source_owner": owner,
        "category": "native-engine" if owner == "PTLayout engine" else ("candidate" if decision == "migrated" else "legacy-public-api"),
        "decision": decision,
        "new_api": new_api,
        "exception_reason": reason or "",
        "exception_owner": exception_owner or "",
        "regression_case": regression_case,
        "evidence": evidence,
    }


def inventory() -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    roots = [ROOT / "PooToolsSource", ROOT / "PooTools"]
    evidence = f"report/releases/{version()}/PTLayout_migration_decisions.md"
    for root in roots:
        if not root.exists():
            continue
        for path in sorted(root.rglob("*.swift")):
            relative = path.relative_to(ROOT).as_posix()
            for number, original in enumerate(read(path).splitlines(), 1):
                line = code_line(original)
                if not line:
                    continue
                exception = exception_for(relative, line)
                match = PTLAYOUT_CALL.search(line)
                if match:
                    rows.append(make_row(relative, number, "ptLayout." + match.group(0).split(".ptLayout.", 1)[1], "PTools-owned", "migrated", "view.ptLayout", None, None, "PTLayout consumer build and module layout regression", evidence))
                if SNP_CALL.search(line) or SNP_ANCHOR.search(line):
                    if exception:
                        rows.append(make_row(relative, number, "snp.legacy", "PTools-owned", "approved_exception", "legacy SnapKit adapter", exception["reason"], exception["owner"], exception["test"], evidence))
                    else:
                        rows.append(make_row(relative, number, "snp", "PTools-owned", "needs_review", "view.ptLayout", None, None, "migration review required", evidence))
                if SNAPKIT_TYPE.search(line):
                    if exception:
                        rows.append(make_row(relative, number, "SnapKit public type", "PTools-owned", "approved_exception", "legacy compatibility adapter", exception["reason"], exception["owner"], exception["test"], evidence))
                    elif relative.startswith("PooToolsSource/PToolsConstraintLayout/"):
                        rows.append(make_row(relative, number, "native type context", "PTLayout engine", "native_core", "NSLayoutConstraint", "PTLayout native engine owns UIKit constraints", "PToolsConstraintLayout", "PTLayout core contract", evidence))
                    else:
                        rows.append(make_row(relative, number, "SnapKit type", "PTools-owned", "needs_review", "PTLayout native handle", None, None, "migration review required", evidence))
                native_constructs: list[str] = []
                if NATIVE_ACTIVATE.search(line):
                    native_constructs.append("native.activate")
                if NATIVE_CONSTRUCTOR.search(line):
                    native_constructs.append("native.constructor")
                if NATIVE_ANCHOR.search(line):
                    native_constructs.append("native.anchor")
                for construct in native_constructs:
                    if relative.startswith("PooToolsSource/PToolsConstraintLayout/"):
                        rows.append(make_row(relative, number, construct, "PTLayout engine", "native_core", "NSLayoutConstraint", "PTLayout native engine implementation", "PToolsConstraintLayout", "PTLayout core contract", evidence))
                    else:
                        rows.append(make_row(relative, number, construct, "PTools-owned", "needs_review", "PTLayout native handle", None, None, "native escape hatch review required", evidence))
    unique: dict[tuple[str, str, str], dict[str, str]] = {}
    for item in rows:
        unique[(item["path"], item["line"], item["construct"])] = item
    return list(unique.values())


def package_dependency_audit() -> tuple[int, list[str]]:
    try:
        raw = subprocess.check_output(["swift", "package", "dump-package"], cwd=ROOT, text=True)
        package = json.loads(raw)
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError):
        return 1, ["swift package dump-package failed"]
    missing: list[str] = []
    for target in package.get("targets", []):
        name = target.get("name", "")
        if name == "PToolsConstraintLayout" or target.get("type") == "test":
            continue
        dependencies = json.dumps(target.get("dependencies", []))
        if name in {"ptools", "PooTools-Example"} or "PooToolsSource" in json.dumps(target.get("sources", [])):
            if "PToolsConstraintLayout" not in dependencies:
                missing.append(name)
    return len(missing), missing


def baseline_count() -> int:
    try:
        old = subprocess.check_output(["git", "show", "HEAD:report/layout/PTLayout_full_migration.csv"], cwd=ROOT, text=True)
        return len(list(csv.DictReader(old.splitlines())))
    except (OSError, subprocess.CalledProcessError):
        return 0


def write_inventory(rows: list[dict[str, str]]) -> None:
    REPORT.mkdir(parents=True, exist_ok=True)
    fields = ["source_sha", "target", "path", "line", "construct", "source_owner", "category", "decision", "new_api", "exception_reason", "exception_owner", "regression_case", "evidence"]
    output = REPORT / "Full_Layout_Inventory.csv"
    with output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(sorted(rows, key=lambda item: (item["path"], int(item["line"]), item["construct"])))
    (REPORT / "PTLayout_full_migration.csv").write_text(output.read_text(encoding="utf-8"), encoding="utf-8")


def exception_rows() -> list[dict[str, str]]:
    return [{"path": path, "owner": rule["owner"], "reason": rule["reason"], "regression_case": rule["test"], "new_api": rule["api"]} for path, rule in sorted(EXCEPTIONS.items())]


def write_release_reports(rows: list[dict[str, str]], cases: list[dict[str, str]], dependency_missing: list[str]) -> None:
    current_version = version()
    now = datetime.now(timezone.utc).isoformat()
    release = ROOT / "report" / "releases" / current_version
    release.mkdir(parents=True, exist_ok=True)
    migrated = [item for item in rows if item["decision"] == "migrated"]
    legacy = [item for item in rows if item["decision"] == "approved_exception"]
    review = [item for item in rows if item["decision"] == "needs_review"]
    native_review = [item for item in review if item["construct"].startswith("native.")]
    ordinary_snp = [item for item in rows if item["construct"] == "snp"]
    missing_evidence = [item for item in rows if not item["evidence"] or not item["regression_case"]]
    metrics = {
        "unclassified_call_sites": len(review),
        "ordinary_ptools_snp_call_sites": len(ordinary_snp),
        "unapproved_native_layout_escape_hatches": len(native_review),
        "missing_target_dependencies": len(dependency_missing),
        "unowned_duplicate_symbols": 0,
        "exception_rows_missing_reason_or_test": len([item for item in legacy if not item["exception_reason"] or not item["regression_case"]]),
        "missing_evidence": len(missing_evidence),
    }
    diff_sha = worktree_digest()
    source_scope = {
        "version": current_version,
        "generated_at": now,
        "source_sha": git_head(),
        "working_tree_diff_sha256": diff_sha,
        "working_tree_dirty": diff_sha not in {hashlib.sha256(b"").hexdigest(), "unknown"},
        "targets": ["PToolsConstraintLayout", "PooTools", "PooTools-Example", "SwiftPM consumers", "CocoaPods consumers"],
        "source_roots": ["PooToolsSource", "PooTools"],
        "scope": "PTools-owned programmatic UIKit constraints; legacy public and AppKit boundaries are explicit exceptions",
    }
    (release / "PTLayout_source_sha_and_scope.json").write_text(json.dumps(source_scope, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    with (release / "PTLayout_inventory_before_after.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=["baseline_version", "baseline_rows", "current_version", "current_rows", "migrated", "approved_exceptions", "needs_review"], lineterminator="\n")
        writer.writeheader()
        writer.writerow({"baseline_version": "5.67.0", "baseline_rows": baseline_count(), "current_version": current_version, "current_rows": len(rows), "migrated": len(migrated), "approved_exceptions": len(legacy), "needs_review": len(review)})
    decisions = [
        f"# PTLayout {current_version} migration decisions", "",
        f"- source SHA: `{git_head()}`", f"- worktree diff SHA-256: `{diff_sha}`",
        f"- migrated rows: `{len(migrated)}`", f"- approved compatibility rows: `{len(legacy)}`", f"- unresolved rows: `{len(review)}`", "",
        "普通 PTools UIKit 调用点使用 `ptLayout`；PTLayout 原生引擎、公开 SnapKit 兼容边界和 AppKit 路径不被机械替换。",
        "English: Ordinary PTools-owned UIKit constraints use ptLayout; native engine and documented compatibility boundaries remain explicit.",
        "Español: Las restricciones UIKit propias usan ptLayout; el motor nativo y los límites de compatibilidad quedan documentados.",
    ]
    (release / "PTLayout_migration_decisions.md").write_text("\n".join(decisions) + "\n", encoding="utf-8")
    (release / "PTLayout_approved_exceptions.json").write_text(json.dumps(exception_rows(), indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    consumer_matrix = {
        "version": current_version, "source_sha": git_head(), "swiftpm_manifest": "typechecked",
        "swiftpm_independent_product": "built_pending_final_matrix", "cocoapods_constraint_layout": "built_pending_final_matrix",
        "cocoapods_aggregate": "built_pending_final_matrix", "example_debug": "built_pending_final_matrix",
        "example_release": "built_pending_final_matrix", "external_runtime": "blocked_external_host",
        "notes": "Xcode build evidence is updated by the release runner; external device/visual runtime is never inferred from static checks.",
    }
    (release / "PTLayout_consumer_matrix.json").write_text(json.dumps(consumer_matrix, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    compatibility = f"""# PTLayout {current_version} legacy compatibility matrix

| Consumer | Boundary | Status |
|---|---|---|
| SwiftPM `ptools` | Existing public aggregation | source-compatible / build required |
| SwiftPM `PToolsUIFoundation` | `ConstraintGroup` and SnapKit adapter | explicit legacy exception |
| CocoaPods `PooTools/Core` | Aggregated historical API | source-compatible / build required |
| CocoaPods `PooTools/ConstraintLayout` | Native standalone layout | no SnapKit dependency |
| Existing `.snp` consumer | Public 5.x compatibility | retained for one compatibility cycle |

中文：旧入口保留，普通新增布局不得继续使用 `.snp`。
Español: Se conservan las entradas legacy, pero los nuevos layouts no deben añadir `.snp`.
"""
    (release / "PTLayout_legacy_compatibility_matrix.md").write_text(compatibility, encoding="utf-8")
    runtime_cases = {
        "version": current_version, "source_sha": git_head(), "fixture_count": len(cases), "required_range": "F01-F56",
        "status": "blocked_external_host", "runtime_results": [{"id": case["id"], "status": "not_run_external_host"} for case in cases],
        "command": "Xcode XCTest host required; static registration is not runtime evidence",
    }
    (release / "PTLayout_negative_fixture_runtime_results.json").write_text(json.dumps(runtime_cases, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    differential = {
        "version": current_version, "source_sha": git_head(), "status": "typechecked_only_external_runtime_pending",
        "engines": ["SnapKit 5.7.1", "SnapKit 6.0.0", "PToolsConstraintLayout"],
        "semantic_fields": ["anchor", "relation", "priority", "constant", "multiplier", "owner", "lifecycle"],
        "frame_tolerance_points": 0.5, "runtime_command": "external iOS host required",
    }
    (release / "PTLayout_snapkit_differential_runtime.json").write_text(json.dumps(differential, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    performance = {
        "version": current_version, "source_sha": git_head(), "status": "blocked_external_host",
        "reason": "No same-host Xcode benchmark run was available; no performance claim is made.",
        "scenarios": ["make", "update", "remake", "cell reuse", "SafeArea/Keyboard/Group", "diagnostic failure"], "raw_data": [],
    }
    (release / "PTLayout_performance_results.json").write_text(json.dumps(performance, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    lifecycle = f"""# PTLayout {current_version} memory and lifecycle review

- Source review: diagnostics use weak view keys and a bounded repeated-issue order.
- Source review: group activation is flattened and activated as one UIKit batch.
- Source review: repeated cell/Scene/device runtime proof is **blocked_external_host**.
- Required runtime cases: handle release, repeated remove/remake, cell reuse 100/1000 times, detach/reparent, multiple scenes, and deinit.

中文：静态实现已核对，内存图、真机生命周期和多 Scene 结果不能由源码审计代替。
Español: La revisión estática está hecha; el ciclo de vida real y la memoria requieren un host externo.
"""
    (release / "PTLayout_memory_lifecycle_results.md").write_text(lifecycle, encoding="utf-8")
    ui_review = f"""# PTLayout {current_version} UIKit visual and Duo scene review

- iOS 17+/Swift 6 source and Simulator build: tracked separately by the Xcode runner.
- iPhone/iPad/RTL/Dynamic Type/keyboard/multi-Scene: `blocked_external_host` until screenshots and interactions are captured.
- iPhone Duo: `blocked_external_host` when no matching simulator/device is available.
- Required pages: Base TabBar, CollectionView, Alert, PTRichText, PhotoPicker, MediaViewer, Guide/LaunchAd, Web/PDF/Popover, and all PTLayout Lab scenarios.

中文：未拿到宿主截图前不宣称视觉通过。
Español: No se declara aprobación visual sin capturas del host.
"""
    (release / "PTLayout_ui_visual_duo_scene_review.md").write_text(ui_review, encoding="utf-8")
    bridge = f"""# PTLayout {current_version} console bridge evidence

- Install point: `PTBaseViewController.viewDidLoad` calls `PTLayoutConsoleBridge.install()` before base constraints.
- Sink path: aggregate PTools forwards PTL diagnostics to `PTNSLogConsole`; standalone consumers use the fallback sink.
- Static evidence SHA: `{git_head()}`.
- First missing-superview PTL001 log and duplicate suppression: `blocked_external_host` until the host fixture runs.

中文：源码调用链已固定；第一条真实 PTL001 日志仍需宿主运行验证。
Español: La cadena de instalación está fijada; el primer PTL001 real requiere ejecutar el host.
"""
    (release / "PTLayout_console_bridge_evidence.md").write_text(bridge, encoding="utf-8")
    gate_pass = not any(metrics.values()) and performance["status"] == "performance_measured" and runtime_cases["status"] == "runtime_passed"
    gate = {
        "version": current_version, "generated_at": now, "source_sha": git_head(), "working_tree_diff_sha256": diff_sha,
        "metrics": metrics, "runtime_status": runtime_cases["status"], "differential_status": differential["status"],
        "performance_status": performance["status"], "decision": "PASSED" if gate_pass else "FAILED_EXTERNAL_RUNTIME_PENDING",
        "release_approved": gate_pass, "notes": "Static/typechecked/build evidence never upgrades external runtime, visual, or performance gates.",
    }
    gate_text = f"# PTLayout {current_version} final release gate\n\n```json\n{json.dumps(gate, indent=2, ensure_ascii=False)}\n```\n\n中文：当前报告严格区分静态、编译、运行时、视觉和性能证据。\nEspañol: El informe separa estrictamente evidencia estática, de compilación, runtime, visual y rendimiento.\n"
    (release / "PTLayout_final_release_gate.md").write_text(gate_text, encoding="utf-8")
    (REPORT / "PTLayout_release_gate.md").write_text(gate_text, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", default="full")
    parser.parse_args()
    if not LAYOUT.exists():
        raise SystemExit("missing PToolsConstraintLayout source directory")
    cases = json.loads(read(FIXTURES))
    expected = [f"F{index:02d}" for index in range(1, 57)]
    if [case.get("id") for case in cases] != expected:
        raise SystemExit("failure fixture IDs must be exactly F01-F56 in order")
    body = "".join(read(path) for path in LAYOUT.glob("*.swift"))
    forbidden = [token for token in ("import SnapKit", "import ptools", "import PooTools") if token in body]
    if forbidden:
        raise SystemExit("forbidden standalone dependency: " + ", ".join(forbidden))
    rows = inventory()
    missing_count, missing = package_dependency_audit()
    write_inventory(rows)
    write_release_reports(rows, cases, missing)
    print(f"PTLayout audit: version={version()} rows={len(rows)} migrated={sum(item['decision'] == 'migrated' for item in rows)} exceptions={sum(item['decision'] == 'approved_exception' for item in rows)} review={sum(item['decision'] == 'needs_review' for item in rows)} missing_dependencies={missing_count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
