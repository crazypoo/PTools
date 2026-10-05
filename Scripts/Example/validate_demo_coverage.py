#!/usr/bin/env python3
"""English: Validate Demo Catalog 2.0 coverage without third-party YAML packages.
Español: Valida la cobertura del catálogo Demo 2.0 sin paquetes YAML externos.
中文：不依赖第三方 YAML 包校验 Demo Catalog 2.0 覆盖率。
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
CATALOG_SOURCE = ROOT / "PooTools/PTDemoCatalog.swift"
ALLOWED_COVERAGE = {
    "runnable",
    "scenario",
    "action",
    "documentation",
    "host_required",
    "extension_required",
    "physical_device_required",
    "entitlement_required",
    "compatibility_alias",
}


def git(*args: str) -> str:
    try:
        return subprocess.run(
            ["git", "-C", str(ROOT), *args],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return ""


def yaml_scalar(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def module_ids() -> set[str]:
    text = (ROOT / "docs/_meta/modules.yml").read_text(encoding="utf-8")
    ids = set(re.findall(r"^  id:\s*\"([^\"]+)\"\s*$", text, re.MULTILINE))
    # English: Compatibility aliases are catalog identities too, but they resolve to one canonical module.
    # Español: Los alias de compatibilidad también son identidades del catálogo y resuelven a un módulo canónico.
    # 中文：兼容别名也是目录身份，但最终解析到唯一 canonical module。
    registry = json.loads((ROOT / "Scripts/module_registry.json").read_text(encoding="utf-8"))
    for module in registry.get("modules", []):
        if isinstance(module, dict):
            ids.update(alias for alias in module.get("aliases", []) if isinstance(alias, str))
    return ids


def demo_entries() -> list[dict[str, object]]:
    text = (ROOT / "Data/demo-registry.yml").read_text(encoding="utf-8")
    if not re.search(r"^schema_version:\s*1\s*$", text, re.MULTILINE):
        raise ValueError("schema_version must be 1")
    entries: list[dict[str, object]] = []
    current: dict[str, object] | None = None
    for line in text.splitlines():
        if line == "-":
            if current is not None:
                entries.append(current)
            current = {"demos": []}
            continue
        if current is None:
            continue
        scalar = re.match(r'^  (module_id|coverage|canonical_module_id):\s*(.+)$', line)
        if scalar:
            key, raw = scalar.groups()
            current[key] = None if raw == "null" else json.loads(raw)
            continue
        demo = re.match(r'^    -\s+(.+)$', line)
        if demo:
            current.setdefault("demos", []).append(json.loads(demo.group(1)))
    if current is not None:
        entries.append(current)
    return entries


def descriptor_ids() -> set[str]:
    if not CATALOG_SOURCE.is_file():
        return set()
    return set(re.findall(r'^\s*make\("([^"]+)"', CATALOG_SOURCE.read_text(encoding="utf-8"), re.MULTILINE))


def factory_contract_failures() -> list[str]:
    """English: Validate the single factory/fallback contract used by the catalog.
    Español: Valida el contrato único de fábrica/fallback usado por el catálogo.
    中文：校验目录使用的唯一工厂与兼容 fallback 契约。
    """
    if not CATALOG_SOURCE.is_file():
        return ["missing catalog source: PooTools/PTDemoCatalog.swift"]
    source = CATALOG_SOURCE.read_text(encoding="utf-8")
    required_snippets = {
        "main-actor factory registry": "@MainActor\nfinal class PTDemoFactoryRegistry",
        "factory lookup": "func makeViewController(for descriptor: PTDemoDescriptor)",
        "compatibility host fallback": "return PTFuncDetailViewController(descriptor: descriptor)",
    }
    return [
        f"missing Demo Factory contract ({label})"
        for label, snippet in required_snippets.items()
        if snippet not in source
    ]


def validate() -> tuple[list[dict[str, object]], list[str]]:
    modules = module_ids()
    entries = demo_entries()
    failures: list[str] = []
    seen_modules: set[str] = set()
    seen_demos: set[str] = set()
    for entry in entries:
        module = entry.get("module_id")
        coverage = entry.get("coverage")
        canonical = entry.get("canonical_module_id")
        demos = entry.get("demos", [])
        if not isinstance(module, str) or not module:
            failures.append("entry has no module_id")
            continue
        if module in seen_modules:
            failures.append(f"duplicate module entry: {module}")
        seen_modules.add(module)
        if module not in modules:
            failures.append(f"unknown module id: {module}")
        if coverage not in ALLOWED_COVERAGE:
            failures.append(f"invalid coverage for {module}: {coverage}")
        if coverage == "compatibility_alias":
            if not isinstance(canonical, str) or canonical not in modules or canonical == module:
                failures.append(f"invalid canonical target for alias {module}: {canonical}")
        if not isinstance(demos, list):
            failures.append(f"demos must be a list for {module}")
            demos = []
        for demo in demos:
            if not isinstance(demo, str) or not demo:
                failures.append(f"invalid demo id under {module}: {demo}")
            elif demo in seen_demos:
                failures.append(f"duplicate demo id: {demo}")
            else:
                seen_demos.add(demo)
    missing = sorted(modules - seen_modules)
    failures.extend(f"missing coverage entry: {module}" for module in missing)
    descriptors = descriptor_ids()
    missing_factories = sorted(demo for demo in seen_demos if demo not in descriptors)
    failures.extend(f"demo registry entry has no Example descriptor: {demo}" for demo in missing_factories)
    unregistered_descriptors = sorted(descriptors - seen_demos)
    failures.extend(f"Example descriptor is missing from demo registry: {demo}" for demo in unregistered_descriptors)
    failures.extend(factory_contract_failures())
    return entries, failures


def write_report(entries: list[dict[str, object]], failures: list[str]) -> None:
    counts: dict[str, int] = {}
    for entry in entries:
        coverage = str(entry.get("coverage", "invalid"))
        counts[coverage] = counts.get(coverage, 0) + 1
    payload = {
        "generator": "Scripts/Example/validate_demo_coverage.py",
        "source_revision": git("rev-parse", "HEAD") or "working-tree",
        "generated_at": git("log", "-1", "--format=%cI") or dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat(),
        "version": VERSION,
        "schemaVersion": 1,
        "moduleCount": len(entries),
        "factoryCoverage": {
            "policy": "main_actor_registry_or_compatibility_host",
            "descriptorCount": len(descriptor_ids()),
            "unresolved": [],
        },
        "counts": dict(sorted(counts.items())),
        "missing": [failure.removeprefix("missing coverage entry: ") for failure in failures if failure.startswith("missing coverage entry:")],
        "failures": failures,
    }
    report_dir = ROOT / "report/example"
    report_dir.mkdir(parents=True, exist_ok=True)
    (report_dir / "DEMO_COVERAGE.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    lines = [
        "<!-- AUTO-GENERATED FILE. DO NOT EDIT.",
        "Generator: Scripts/Example/validate_demo_coverage.py",
        f"Source revision: {payload['source_revision']}",
        f"Generated at: {payload['generated_at']} -->",
        "# PTools Demo Coverage",
        "",
        f"- Version: `{VERSION}`",
        f"- Modules: `{len(entries)}`",
        "- Factory: `@MainActor registry + compatibility detail host fallback`",
        "",
        "| Coverage | Count |",
        "| --- | ---: |",
    ]
    lines.extend(f"| `{key}` | {value} |" for key, value in sorted(counts.items()))
    lines.extend(["", f"- Failures: `{len(failures)}`"])
    if failures:
        lines.extend(["", "## Failures", "", *[f"- {failure}" for failure in failures]])
    (report_dir / "DEMO_COVERAGE.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="validate without changing source registries")
    args = parser.parse_args()
    try:
        entries, failures = validate()
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"FAIL [DEMO_REGISTRY_PARSE] {error}", file=sys.stderr)
        return 1
    write_report(entries, failures)
    if failures:
        print("FAIL [DEMO_COVERAGE]")
        print("\n".join(f"- {failure}" for failure in failures))
        return 1
    print(f"PASS: Demo Coverage ({len(entries)} modules, 0 missing); Factory Gate (registry + compatibility fallback)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
