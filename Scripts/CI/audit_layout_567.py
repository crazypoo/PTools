#!/usr/bin/env python3
"""English: Reproducible PTLayout 5.67 source, API and fixture audit.
Español: Auditoría reproducible de fuente, API y fixtures de PTLayout 5.67.
中文：可复现的 PTLayout 5.67 源码、API 与夹具审计。
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
LAYOUT = ROOT / "PooToolsSource" / "PToolsConstraintLayout"
REPORT = ROOT / "report" / "layout"
FIXTURES = ROOT / "Scripts" / "CI" / "fixtures" / "PTLayoutFailureInjectionCases_567.json"


def text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def run_git_head() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    except (OSError, subprocess.CalledProcessError):
        return "unknown"


def inventory() -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    roots = [ROOT / "PooToolsSource", ROOT / "PooTools"]
    patterns = {
        "snapkit_snp": re.compile(r"\.snp\b"),
        "snapkit_types": re.compile(r"\b(?:ConstraintMaker|ConstraintItem|Constraint)\b"),
        "native_activate": re.compile(r"NSLayoutConstraint\.(?:activate|deactivate)\b"),
        "native_constructor": re.compile(r"NSLayoutConstraint\s*\("),
        "anchor_constraint": re.compile(r"\.(?:top|bottom|leading|trailing|centerX|centerY|width|height)Anchor\.constraint"),
    }
    for root in roots:
        if not root.exists():
            continue
        for path in sorted(root.rglob("*.swift")):
            relative = path.relative_to(ROOT).as_posix()
            owner = "native-canonical" if path.is_relative_to(LAYOUT) else "legacy-or-candidate"
            body = text(path)
            for kind, pattern in patterns.items():
                for number, line in enumerate(body.splitlines(), 1):
                    if pattern.search(line):
                        rows.append({
                            "path": relative,
                            "line": str(number),
                            "kind": kind,
                            "owner": owner,
                            "status": "canonical" if owner == "native-canonical" else "review",
                            "reason": "PTLayout native engine" if owner == "native-canonical" else "legacy compatibility or migration candidate",
                            "snippet": line.strip()[:240],
                        })
    return rows


def write_inventory(rows: list[dict[str, str]]) -> None:
    REPORT.mkdir(parents=True, exist_ok=True)
    path = REPORT / "Full_Layout_Inventory.csv"
    fields = ["path", "line", "kind", "owner", "status", "reason", "snippet"]
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    (REPORT / "PTLayout_full_migration.csv").write_text(path.read_text(encoding="utf-8"), encoding="utf-8")


def write_reports(rows: list[dict[str, str]], cases: list[dict[str, str]]) -> None:
    REPORT.mkdir(parents=True, exist_ok=True)
    now = datetime.now(timezone.utc).isoformat()
    canonical_files = sorted(str(path.relative_to(ROOT)) for path in LAYOUT.glob("*.swift"))
    diagnostics = {
        "schema_version": 1,
        "generated_at": now,
        "source_revision": run_git_head(),
        "codes": ["PTL001", "PTL002", "PTL003", "PTL004", "PTL005", "PTL006", "PTL007", "PTL008", "PTL009"],
        "sink": "PTLayoutDiagnostics.onFailure",
        "aggregate_bridge": "PooToolsSource/Core/PTLayoutConsoleBridge.swift",
        "standalone_fallback": "Swift.print when mode is not production",
        "deduplication": "owner + code + fileID + line occurrence count",
        "canonical_source_files": canonical_files,
    }
    (REPORT / "PTLayout_diagnostic_coverage.json").write_text(json.dumps(diagnostics, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    crash = {
        "schema_version": 1,
        "generated_at": now,
        "fixture_count": len(cases),
        "fixture_ids": [case["id"] for case in cases],
        "required_range": "F01-F56",
        "static_status": "registered; runtime host and visual validation are external to the cleaned source package",
        "fatal_error_in_canonical_source": "fatalError" in "".join(text(path) for path in LAYOUT.glob("*.swift")),
        "atomic_transaction_path": "PTLayoutEngine.prepare -> activate",
    }
    (REPORT / "PTLayout_crash_safety.json").write_text(json.dumps(crash, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    perf = {
        "schema_version": 1,
        "status": "not_measured",
        "reason": "No benchmark numbers are claimed until the same iOS Simulator/device runs all engines.",
        "engines": ["SnapKit 5.7.1", "SnapKit 6.0.0", "PToolsConstraintLayout"],
        "metrics": ["make", "update", "remake", "prepare", "activation", "installed_constraints", "peak_memory"],
        "instrumentation": "PTLayoutProfiler",
    }
    (REPORT / "PTLayout_performance_comparison.json").write_text(json.dumps(perf, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    dependency = """# PTLayout 5.67 dependency graph\n\n```text\nPToolsConstraintLayout -> UIKit / Foundation\nPToolsConstraintLayout -/-> SnapKit\nPToolsConstraintLayout -/-> ptools / PToolsUIFoundation / PooToolsLayout\nptools -> PToolsConstraintLayout (controlled aggregate edge)\nPTLayoutConsoleBridge -> PTNSLogConsole (aggregate-only conditional bridge)\n```\n\nThe standalone product is intentionally independent. The aggregate target keeps the legacy SnapKit boundary for existing 5.x consumers.\n\n中文：独立产品不依赖 SnapKit；聚合入口只保留受控的兼容边界。\nEspañol: El producto independiente no depende de SnapKit; el agregado conserva solo el límite de compatibilidad controlado.\n"""
    (REPORT / "PTLayout_dependency_graph.md").write_text(dependency, encoding="utf-8")

    source_diff = """# SnapKit 5.7.1 / 6.0.0 / PTLayout source-difference record\n\n- SnapKit 5.7.1 and 6.0.0 are upstream compatibility baselines, not vendored into this product.\n- PTLayout uses native `NSLayoutConstraint` and `#fileID` defaults.\n- PTLayout does not claim that SnapKit 6.0.0 introduced a new native engine or performance guarantee.\n- Legacy `.snp` remains supported at its existing compatibility boundary.\n\n中文：这里记录事实差异，不把未测量的性能结论写成事实。\nEspañol: Este documento registra diferencias verificables y no convierte rendimiento no medido en una afirmación.\n"""
    (REPORT / "PTLayout_SnapKit_6_Source_Diff.md").write_text(source_diff, encoding="utf-8")

    gate = {
        "version": text(ROOT / "VERSION").strip() if (ROOT / "VERSION").exists() else "missing",
        "generated_at": now,
        "source_revision": run_git_head(),
        "inventory_rows": len(rows),
        "failure_fixtures": len(cases),
        "standalone_runtime": "requires an external iOS host and visual validation",
        "release_decision": "runtime_fixture_and_visual_validation_pending",
    }
    gate_document = (
        f"# PTLayout {gate['version']} release gate\n\n" +
        "```json\n" + json.dumps(gate, indent=2, ensure_ascii=False) + "\n```\n\n" +
        "中文：静态审计不替代 Xcode Simulator、CocoaPods Consumer 和真机视觉验证。\n" +
        "Español: La auditoría estática no sustituye Xcode Simulator, CocoaPods Consumer ni la validación visual en dispositivo.\n"
    )
    (REPORT / "PTLayout_release_gate.md").write_text(gate_document, encoding="utf-8")
    release_report = ROOT / "report" / "releases" / gate["version"]
    release_report.mkdir(parents=True, exist_ok=True)
    (release_report / "PTLayout_release_gate.md").write_text(gate_document, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", default="full")
    args = parser.parse_args()
    del args
    if not LAYOUT.exists():
        raise SystemExit("missing PToolsConstraintLayout source directory")
    cases = json.loads(text(FIXTURES))
    expected = [f"F{index:02d}" for index in range(1, 57)]
    actual = [case.get("id") for case in cases]
    if actual != expected:
        raise SystemExit("failure fixture IDs must be exactly F01-F56 in order")
    body = "".join(text(path) for path in LAYOUT.glob("*.swift"))
    forbidden = [token for token in ("import SnapKit", "import ptools", "import PooTools") if token in body]
    if forbidden:
        raise SystemExit("forbidden standalone dependency: " + ", ".join(forbidden))
    rows = inventory()
    write_inventory(rows)
    write_reports(rows, cases)
    print(f"PTLayout audit: canonical_files={len(list(LAYOUT.glob('*.swift')))} inventory_rows={len(rows)} fixtures={len(cases)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
