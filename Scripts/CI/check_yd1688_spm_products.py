#!/usr/bin/env python3
"""Fail-fast, dependency-free YD1688 -> PTools SwiftPM *static* product gate.

This verifies declarations, aliases, imports and source-path ownership.
It does NOT claim that all products compile, link or pass device tests.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path


SUBSPEC_RE = re.compile(r"""\bs\.subspec\s+['"]([^'"]+)['"]""")
POD_RE = re.compile(r"""\bpod\s+['"]PooTools/([^'"]+)['"]""")
EXPECTED_ALIAS_TARGETS = {
    "Tabbar": ("PooToolsTabbar", "ptools"),
    "Flag": ("PooToolsFlag", "ptools"),
    "NotificationBanner": ("PooToolsNotificationBanner", "PooToolsBanner"),
    "VideoCache": ("PooToolsVideoCache", "ptools"),
}
EXPECTED_COUNT = 42


def fail(errors: list[str], description: str) -> None:
    errors.append(description)


def load_manifest(root: Path, manifest_json: Path | None) -> dict:
    if manifest_json is not None:
        return json.loads(manifest_json.read_text(encoding="utf-8"))
    command = ["swift", "package", "dump-package"]
    try:
        result = subprocess.run(
            command, cwd=root, text=True, capture_output=True, check=False
        )
    except OSError as error:
        raise RuntimeError(f"Cannot launch SwiftPM: {error}") from error
    if result.returncode != 0:
        raise RuntimeError(
            f"swift package dump-package failed ({result.returncode}):\n{result.stderr}"
        )
    return json.loads(result.stdout)


def check(
    root: Path, manifest: dict, mapping: dict, reference_podfile: Path | None,
    skip_source_paths: bool,
) -> list[str]:
    errors: list[str] = []
    entries = mapping.get("entries", [])
    if not isinstance(entries, list) or len(entries) != EXPECTED_COUNT:
        fail(errors, f"Expected {EXPECTED_COUNT} snapshot entries, got {len(entries) if isinstance(entries, list) else 'invalid'}")
        return errors

    podspec_path = root / "PooTools.podspec"
    if not podspec_path.is_file():
        fail(errors, f"Missing podspec: {podspec_path}")
        return errors
    declared_subspecs = set(SUBSPEC_RE.findall(podspec_path.read_text(encoding="utf-8")))
    products = manifest.get("products", [])
    targets = manifest.get("targets", [])
    product_names = Counter(p.get("name") for p in products)
    target_names = Counter(t.get("name") for t in targets)
    products_by_name = {p.get("name"): p for p in products}
    targets_by_name = {t.get("name"): t for t in targets}
    subspecs = [row.get("pod_subspec") for row in entries]
    mapped_products = [row.get("spm_product") for row in entries]

    if len(set(subspecs)) != EXPECTED_COUNT:
        fail(errors, "Subspec snapshot contains duplicates")
    if len(set(mapped_products)) != EXPECTED_COUNT:
        fail(errors, "SPM product mapping contains duplicates")
    for name, count in product_names.items():
        if count != 1:
            fail(errors, f"Duplicate manifest product: {name}")
    for name, count in target_names.items():
        if count != 1:
            fail(errors, f"Duplicate manifest target: {name}")

    for row in entries:
        pod = row.get("pod_subspec")
        product = row.get("spm_product")
        target = row.get("spm_target")
        module = row.get("import_module")
        if not all(isinstance(value, str) and value.strip() for value in (pod, product, target, module)):
            fail(errors, f"Invalid nonempty mapping fields: {row!r}")
            continue
        if pod not in declared_subspecs:
            fail(errors, f"PooTools/{pod}: subspec missing")
        published = products_by_name.get(product)
        if not published:
            fail(errors, f"PooTools/{pod}: SPM product {product} missing")
            continue
        if published.get("targets") != [target]:
            fail(errors, f"PooTools/{pod}: product targets {published.get('targets')} != [{target}]")
        owner = targets_by_name.get(target)
        if owner is None:
            fail(errors, f"PooTools/{pod}: target {target} missing")
            continue
        if module != target:
            fail(errors, f"PooTools/{pod}: import module {module} != actual target {target}")
        if not skip_source_paths:
            source_path = owner.get("path") or f"Sources/{target}"
            if not (root / source_path).exists():
                fail(errors, f"PooTools/{pod}: source target path missing: {source_path}")

    for pod, (product, target) in EXPECTED_ALIAS_TARGETS.items():
        row = next((r for r in entries if r["pod_subspec"] == pod), None)
        if row is None or row["spm_product"] != product or row["spm_target"] != target:
            fail(errors, f"Compatibility alias ownership changed: {pod}")
        if target != product and target_names.get(product, 0) != 0:
            fail(errors, f"Alias {product} incorrectly adds a duplicate source target")
    ptools_target = targets_by_name.get("ptools", {})
    if "POOTOOLS_TABBAR" not in json.dumps(ptools_target.get("settings", [])):
        fail(errors, "ptools target must enable POOTOOLS_TABBAR")
    # FlagKit is a separately managed dependency and must not be introduced
    # by the historical PooTools/Flag compatibility product.
    if any("FlagKit" in str(dep) for dep in manifest.get("dependencies", [])):
        fail(errors, "FlagKit must remain a host-owned dependency")

    # The fixture is an independent SwiftPM downstream client; keep both
    # the explicit product dependencies and unique import modules in sync.
    fixture_root = root / "Tests/Fixtures/YD1688SPMProbe"
    fixture_manifest = fixture_root / "Package.swift"
    fixture_source = fixture_root / "Sources/YD1688SPMProbe/Probe.swift"
    if not fixture_manifest.is_file() or not fixture_source.is_file():
        fail(errors, "YD1688 SwiftPM consumer fixture is missing")
    else:
        dependency_names = re.findall(
            r"""\.product\(name:\s*"([^"]+)",\s*package:\s*"ptools"\)""",
            fixture_manifest.read_text(encoding="utf-8"),
        )
        if Counter(dependency_names) != Counter(mapped_products):
            fail(errors, "Consumer fixture 42-product dependencies drift from mapping")
        import_names = set(re.findall(
            r"(?m)^import\s+([A-Za-z_][A-Za-z_0-9]*)\s*$",
            fixture_source.read_text(encoding="utf-8"),
        )) - {"Foundation"}
        expected_modules = {row.get("import_module") for row in entries}
        if import_names != expected_modules:
            fail(errors, f"Consumer fixture imports mismatch: {sorted(import_names ^ expected_modules)}")

    if reference_podfile is not None:
        if not reference_podfile.is_file():
            fail(errors, f"Consumer Podfile missing: {reference_podfile}")
        else:
            actual = POD_RE.findall(reference_podfile.read_text(encoding="utf-8"))
            if Counter(actual) != Counter(subspecs):
                fail(errors, f"Consumer Podfile snapshot drift: added_in_consumer={sorted(set(actual) - set(subspecs))}, removed_from_consumer={sorted(set(subspecs) - set(actual))}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--manifest-json", type=Path, help="Use a saved swift package dump-package output")
    parser.add_argument("--reference-podfile", type=Path, help="Compare against the YD1688 Podfile without modifying it")
    parser.add_argument("--skip-source-paths", action="store_true", help="For isolated offline fixture tests only")
    args = parser.parse_args()
    root = args.root.resolve()
    try:
        mapping = json.loads((root / "Scripts/CI/yd1688_spm_products.json").read_text(encoding="utf-8"))
        manifest = load_manifest(root, args.manifest_json)
        errors = check(root, manifest, mapping, args.reference_podfile, args.skip_source_paths)
    except (OSError, ValueError, RuntimeError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1
    if errors:
        for error in errors:
            print(f"FAIL: {error}", file=sys.stderr)
        return 1
    print(f"PASS: {len(mapping['entries'])}/{EXPECTED_COUNT} YD1688 PooTools subspecs map to single-target SPM products and imports")
    print("NOTE: static declaration gate only; iOS Debug/Release builds and device Q remain unverified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
