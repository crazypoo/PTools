#!/usr/bin/env python3
"""English: Classify repository automation assets and create reviewed cleanup manifests.
Español: Clasifica los activos de automatización y crea manifiestos de limpieza revisables.
中文：分类仓库自动化资产并生成可审阅的清理清单。

This tool is intentionally conservative: it reports merge and delete candidates,
but only records operations already applied by an explicit migration.
"""

from __future__ import annotations

import argparse
import datetime as datetime_module
import hashlib
import json
import os
import re
import subprocess
from collections import defaultdict
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[2]
EXCLUDED = {".git", "Pods", ".build", "build", "DerivedData"}
SCRIPT_SUFFIXES = {".sh", ".py", ".rb", ".swift"}
DATA_SUFFIXES = {".json", ".jsonl", ".yml", ".yaml"}
TEST_SUFFIXES = {".swift", ".m", ".mm"}
VERSIONED_NAME = re.compile(r"(?:^|[_-])(?:5(?:[._]\d+)+)(?:[_-]|\.|$)")
_FILE_CACHE: dict[tuple[str, ...] | None, list[Path]] = {}
_TEXT_CACHE: dict[str, str] | None = None


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def files(suffixes: set[str] | None = None) -> list[Path]:
    cache_key = tuple(sorted(suffixes)) if suffixes is not None else None
    if cache_key in _FILE_CACHE:
        return _FILE_CACHE[cache_key]
    result = []
    for directory, directory_names, file_names in os.walk(ROOT):
        directory_names[:] = [name for name in directory_names if name not in EXCLUDED]
        for name in file_names:
            path = Path(directory) / name
            if suffixes is None or path.suffix.lower() in suffixes:
                result.append(path)
    _FILE_CACHE[cache_key] = sorted(result)
    return _FILE_CACHE[cache_key]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def source_revision() -> str:
    try:
        return subprocess.run(
            ["git", "-C", str(ROOT), "rev-parse", "HEAD"],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return "working-tree"


def generated_at() -> str:
    return datetime_module.datetime.now(datetime_module.timezone.utc).replace(microsecond=0).isoformat()


def normalized_hash(path: Path) -> str:
    content = re.sub(r"\s+", " ", read_text(path)).strip().encode("utf-8")
    return hashlib.sha256(content).hexdigest()


def consumers(target: str, ignored: set[str] | None = None) -> list[str]:
    global _TEXT_CACHE
    ignored = ignored or set()
    if _TEXT_CACHE is None:
        _TEXT_CACHE = {
            relative(path): read_text(path)
            for path in files()
            if not relative(path).startswith("report/")
        }
    matches = []
    for rel, text in _TEXT_CACHE.items():
        if rel in ignored:
            continue
        if target in text:
            matches.append(rel)
    return matches


def script_inventory() -> list[dict[str, Any]]:
    records = []
    by_hash: dict[str, list[str]] = defaultdict(list)
    paths = [path for path in files(SCRIPT_SUFFIXES) if "Scripts" in path.parts or path.parent == ROOT]
    for path in paths:
        rel = relative(path)
        digest = normalized_hash(path)
        by_hash[digest].append(rel)
        references = consumers(rel, {rel})
        legacy = bool(VERSIONED_NAME.search(path.stem))
        status = "LEGACY_REVIEW" if legacy else "ACTIVE"
        action = "KEEP_REVIEW" if not references and path.parent == ROOT else "KEEP"
        records.append(
            {
                "path": rel,
                "language": path.suffix.lstrip("."),
                "purpose": "repository automation",
                "category": path.parent.name,
                "owner": "PTools maintainers",
                "entrypoint": rel in {"Scripts/ptools.py", "Scripts/quality.sh"},
                "calledByCI": any(item.startswith(".github/workflows/") for item in references),
                "calledByDocs": any(item.startswith("docs/") for item in references),
                "calledByOtherScripts": any(item.startswith("Scripts/") for item in references),
                "consumers": references,
                "duplicateScore": 1.0 if len(by_hash[digest]) > 1 else 0.0,
                "replacement": "",
                "status": status,
                "action": action,
            }
        )
    return records


def data_kind(rel: str) -> str:
    if rel.startswith("report/"):
        return "REPORT"
    if rel.startswith("Data/Schemas/") or rel.endswith(".schema.json"):
        return "SCHEMA"
    if "/fixtures/" in rel or rel.startswith("Tests/Fixtures/"):
        return "FIXTURE"
    if "/golden/" in rel or "/snapshots/" in rel:
        return "GOLDEN"
    if rel.startswith(".github/") or rel in {"_config.yml", "Scripts/CI/quality_gates.yml"}:
        return "CI"
    if rel.startswith("Scripts/"):
        return "DEV_TOOL"
    if rel.startswith("Data/") or rel.startswith("docs/_meta/") or rel in {"Package.resolved", "Podfile.lock"}:
        return "SOURCE_OF_TRUTH"
    return "SOURCE_OF_TRUTH"


def data_inventory() -> list[dict[str, Any]]:
    records = []
    hashes: dict[str, list[str]] = defaultdict(list)
    paths = files(DATA_SUFFIXES)
    for path in paths:
        rel = relative(path)
        digest = normalized_hash(path)
        hashes[digest].append(rel)
    for path in paths:
        rel = relative(path)
        kind = data_kind(rel)
        duplicate = len(hashes[normalized_hash(path)]) > 1
        records.append(
            {
                "path": rel,
                "format": path.suffix.lower().lstrip("."),
                "schema": "Data/Schemas/" if kind == "SCHEMA" else "",
                "category": kind.lower(),
                "owner": "PTools maintainers",
                "sourceOfTruth": kind == "SOURCE_OF_TRUTH",
                "generatedBy": "Scripts/Docs/audit_docs.py" if kind == "REPORT" else "",
                "consumedBy": consumers(rel, {rel}),
                "duplicateScore": 1.0 if duplicate else 0.0,
                "recordCount": None,
                "stableIDs": [],
                "replacement": "",
                "action": "DUPLICATE_REVIEW" if duplicate else "KEEP",
            }
        )
    return records


def package_test_targets() -> list[dict[str, Any]]:
    package = read_text(ROOT / "Package.swift")
    targets = []
    for match in re.finditer(r"\.testTarget\(\s*name:\s*\"([^\"]+)\"(.*?)(?=\n\s*\.testTarget\(|\n\s*\.target\(|\n\s*\]\s*\))", package, re.S):
        chunk = match.group(0)
        path_match = re.search(r'path:\s*"([^"]+)"', chunk)
        target_path = path_match.group(1) if path_match else f"Tests/{match.group(1)}"
        targets.append({"target": match.group(1), "path": target_path})
    return targets


def test_inventory() -> list[dict[str, Any]]:
    records = []
    hashes: dict[str, list[str]] = defaultdict(list)
    for path in files(TEST_SUFFIXES):
        if "Tests" in path.parts:
            hashes[normalized_hash(path)].append(relative(path))
    for item in package_test_targets():
        directory = ROOT / item["path"]
        test_files = [path for path in files(TEST_SUFFIXES) if path.is_relative_to(directory)] if directory.is_dir() else []
        duplicate_files = [relative(path) for path in test_files if len(hashes[normalized_hash(path)]) > 1]
        name = item["target"]
        domain = re.sub(r"Tests$", "", name).replace("PTools", "").replace("PooTools", "") or "Core"
        records.append(
            {
                "target": name,
                "path": item["path"],
                "domain": domain.lower(),
                "testType": ["contract"],
                "modulesCovered": [],
                "dependencies": [],
                "platform": "host-or-simulator",
                "hostRequired": False,
                "deviceRequired": False,
                "estimatedDuration": "unmeasured",
                "fixtureUsage": [],
                "mockUsage": [],
                "duplicateScore": 1.0 if duplicate_files else 0.0,
                "ciJobs": ["tests"],
                "status": "ACTIVE",
                "action": "DUPLICATE_REVIEW" if duplicate_files else "KEEP",
                "files": [relative(path) for path in test_files],
            }
        )
    return sorted(records, key=lambda item: item["target"])


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_markdown(path: Path, title: str, rows: list[dict[str, Any]], columns: list[str]) -> None:
    lines = [
        "<!-- AUTO-GENERATED FILE. DO NOT EDIT.",
        "Generator: Scripts/Governance/audit_repository.py",
        f"Source revision: {source_revision()} -->",
        f"# {title}",
        "",
        f"- Version: `{(ROOT / 'VERSION').read_text().strip()}`",
        f"- Records: `{len(rows)}`",
        "",
        "| " + " | ".join(columns) + " |",
        "| " + " | ".join("---" for _ in columns) + " |",
    ]
    for row in rows:
        values = []
        for column in columns:
            value = row.get(column, "")
            if isinstance(value, list):
                value = ", ".join(str(item) for item in value[:8])
                if len(row.get(column, [])) > 8:
                    value += " …"
            values.append(str(value).replace("|", "\\|"))
        lines.append("| " + " | ".join(values) + " |")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def duplicate_rows() -> list[dict[str, Any]]:
    rows = []
    for category, suffixes in (("scripts", SCRIPT_SUFFIXES), ("data", DATA_SUFFIXES), ("tests", TEST_SUFFIXES)):
        groups: dict[str, list[str]] = defaultdict(list)
        for path in files(suffixes):
            if category == "scripts" and "Scripts" not in path.parts and path.parent != ROOT:
                continue
            if category == "tests" and "Tests" not in path.parts:
                continue
            groups[normalized_hash(path)].append(relative(path))
        for digest, paths in groups.items():
            if len(paths) > 1:
                rows.append({"category": category, "hash": digest, "paths": paths, "action": "REVIEW_ONLY"})
    return rows


def write_cleanup_manifests(scripts: list[dict[str, Any]], assets: list[dict[str, Any]], tests: list[dict[str, Any]], duplicates: list[dict[str, Any]]) -> None:
    repository_rows = [
        {"area": "Docs", "old": "historical plan files", "canonical": "docs/archive/ or Git history", "action": "KEEP", "consumers": "No current plan files remain in the active tree"},
        {"area": "Scripts", "old": "Scripts/report_public_api_5_9.rb", "canonical": "Scripts/report_public_api.rb", "action": "MERGED_AND_REPOINTED", "consumers": "validate_59_contracts.sh; validate_quality_scans.sh; API baseline documentation"},
        {"area": "Scripts", "old": "Scripts/report_*_5_9.rb", "canonical": "Scripts/report_*.rb", "action": "MERGED_AND_REPOINTED", "consumers": "quality and lifecycle validators"},
        {"area": "Scripts", "old": "paapidetect.sh + paapi.txt", "canonical": "Scripts/Privacy/validate_privacy_accessed_api.sh + paapi.txt", "action": "MOVED_AND_REPOINTED", "consumers": "none; router entry added"},
        {"area": "Scripts", "old": "Scripts/report_public_api_5_8.rb; Scripts/generate_58_reports.sh", "canonical": "Git history and Scripts/ptools.py reports regenerate-5.8", "action": "DELETED_AFTER_CONSUMER_SCAN", "consumers": "none"},
        {"area": "Scripts", "old": "Scripts/CI/check_5_36_1_finalization.sh", "canonical": "Git history", "action": "DELETED_AFTER_CONSUMER_SCAN", "consumers": "none; generated index only"},
    ]
    repository_rows.extend(
        {"area": "Data", "old": ", ".join(row["paths"]), "canonical": "same source pending owner review", "action": "DUPLICATE_REVIEW", "consumers": "not automatically deleted"}
        for row in duplicates
        if row["category"] == "data"
    )
    repository_rows.extend(
        {"area": "Tests", "old": row["target"], "canonical": row["target"], "action": row["action"], "consumers": "target remains canonical; no safe merge proven"}
        for row in tests
        if row["action"] != "KEEP"
    )
    write_markdown(ROOT / "report/repository/REPOSITORY_CLEANUP_MANIFEST.md", "Repository Cleanup Manifest", repository_rows, ["area", "old", "canonical", "action", "consumers"])

    merge_rows = [
        {"old": "Scripts/report_public_api_5_9.rb", "canonical": "Scripts/report_public_api.rb", "action": "MERGE", "consumers": "repointed", "safe_delete_after": "consumer scan passed"},
        {"old": "Scripts/report_accessibility_5_9.rb", "canonical": "Scripts/report_accessibility.rb", "action": "MERGE", "consumers": "repointed", "safe_delete_after": "consumer scan passed"},
        {"old": "Scripts/report_concurrency_5_9.rb", "canonical": "Scripts/report_concurrency.rb", "action": "MERGE", "consumers": "repointed", "safe_delete_after": "consumer scan passed"},
        {"old": "Scripts/report_cache_inventory_5_9.rb", "canonical": "Scripts/report_cache_inventory.rb", "action": "MERGE", "consumers": "repointed", "safe_delete_after": "consumer scan passed"},
        {"old": "Scripts/report_singletons_5_9.rb", "canonical": "Scripts/report_singletons.rb", "action": "MERGE", "consumers": "repointed", "safe_delete_after": "consumer scan passed"},
    ]
    merge_rows.extend(
        {"old": ", ".join(row["paths"]), "canonical": "none", "action": "REVIEW_ONLY", "consumers": "unknown", "safe_delete_after": "manual semantic review"}
        for row in duplicates
        if row["category"] != "scripts"
    )
    write_markdown(ROOT / "report/repository/AUTOMATION_ASSET_MERGE_MANIFEST.md", "Automation Asset Merge Manifest", merge_rows, ["old", "canonical", "action", "consumers", "safe_delete_after"])

    test_rows = [
        {"target": row["target"], "domain": row["domain"], "action": row["action"], "reason": "Keep target boundary until dependency and duration evidence proves a merge"}
        for row in tests
    ]
    write_markdown(ROOT / "report/repository/TEST_CLEANUP_MANIFEST.md", "Test Cleanup Manifest", test_rows, ["target", "domain", "action", "reason"])


def write_all() -> None:
    scripts = script_inventory()
    assets = data_inventory()
    tests = test_inventory()
    duplicates = duplicate_rows()
    report_root = ROOT / "report/repository"
    write_json(report_root / "SCRIPT_INVENTORY.json", {"generator": "Scripts/Governance/audit_repository.py", "scripts": scripts})
    write_markdown(report_root / "SCRIPT_INVENTORY.md", "Script Inventory", scripts, ["path", "language", "category", "status", "action", "consumers"])
    write_json(report_root / "DATA_ASSET_INVENTORY.json", {"generator": "Scripts/Governance/audit_repository.py", "assets": assets})
    write_markdown(report_root / "DATA_ASSET_INVENTORY.md", "Data Asset Inventory", assets, ["path", "format", "category", "sourceOfTruth", "action", "consumedBy"])
    write_json(report_root / "TEST_INVENTORY.json", {"generator": "Scripts/Governance/audit_repository.py", "tests": tests})
    write_markdown(report_root / "TEST_INVENTORY.md", "Test Inventory", tests, ["target", "path", "domain", "status", "action", "files"])
    write_json(report_root / "DUPLICATE_CANDIDATES.json", {"generator": "Scripts/Governance/audit_repository.py", "duplicates": duplicates})
    write_markdown(report_root / "DUPLICATE_CANDIDATES.md", "Repository Duplicate Candidates", duplicates, ["category", "hash", "paths", "action"])
    write_cleanup_manifests(scripts, assets, tests, duplicates)


def check() -> int:
    required = [
        ROOT / "Scripts/registry.yml",
        ROOT / "Data/registry.yml",
        ROOT / "Tests/registry.yml",
        ROOT / "report/repository/REPOSITORY_CLEANUP_MANIFEST.md",
        ROOT / "report/repository/AUTOMATION_ASSET_MERGE_MANIFEST.md",
        ROOT / "report/repository/TEST_CLEANUP_MANIFEST.md",
    ]
    missing = [str(path.relative_to(ROOT)) for path in required if not path.is_file()]
    if missing:
        print("FAIL: repository governance assets missing: " + ", ".join(missing))
        return 1
    script_registry = read_text(ROOT / "Scripts/registry.yml")
    data_registry = read_text(ROOT / "Data/registry.yml")
    test_registry = read_text(ROOT / "Tests/registry.yml")
    registry_failures = []
    for path in ("Scripts/Docs/audit_docs.py", "Scripts/Governance/audit_repository.py", "Scripts/ptools.py"):
        if path not in script_registry:
            registry_failures.append(f"script registry missing {path}")
    for path in ("docs/_meta/modules.yml", "Package.resolved", "Podfile.lock"):
        if path not in data_registry:
            registry_failures.append(f"data registry missing {path}")
    for target in package_test_targets():
        if target["target"] not in test_registry or target["path"] not in test_registry:
            registry_failures.append(f"test registry missing {target['target']}")
    if registry_failures:
        print("FAIL: repository registries are incomplete")
        print("\n".join(f"- {failure}" for failure in registry_failures))
        return 1
    print("PASS: repository classification and cleanup manifests")
    return 0


def main() -> int:
    argument_parser = argparse.ArgumentParser(description="PTools repository classification and cleanup audit")
    argument_parser.add_argument("--write-all", "--write", dest="write_all", action="store_true")
    argument_parser.add_argument("--check", action="store_true")
    args = argument_parser.parse_args()
    if not args.write_all and not args.check:
        argument_parser.error("choose --write-all or --check")
    if args.write_all:
        write_all()
    return check() if args.check or args.write_all else 0


if __name__ == "__main__":
    raise SystemExit(main())
