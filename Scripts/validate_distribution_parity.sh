#!/usr/bin/env bash

set -euo pipefail

# English: Verify the three migration compatibility products against the real package and Podspec contracts.
# Español: Verifica los tres productos de compatibilidad de migración contra los contratos reales del paquete y Podspec.
# 中文：根据真实 Package 与 Podspec 契约校验三个迁移兼容产品。

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
package_dump="$(mktemp "${TMPDIR:-/tmp}/ptools-package.XXXXXX.json")"
trap 'rm -f "$package_dump"' EXIT

if ! swift package dump-package > "$package_dump"; then
  printf 'FAIL [DISTRIBUTION_PARITY] swift package dump-package failed\n' >&2
  exit 1
fi

python3 - "$repo_root" "$package_dump" <<'PY'
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
package = json.loads(Path(sys.argv[2]).read_text())
podspec = (root / "PooTools.podspec").read_text()


def fail(message: str) -> None:
    print(f"FAIL [DISTRIBUTION_PARITY] {message}", file=sys.stderr)
    raise SystemExit(1)


products = {item["name"]: item for item in package.get("products", [])}
targets = {item["name"]: item for item in package.get("targets", [])}


def target_names(product_name: str) -> set[str]:
    product = products.get(product_name)
    if product is None:
        fail(f"SwiftPM product is missing: {product_name}")
    return set(product.get("targets", []))


expected_products = {
    "PooToolsWebKit": {"PooToolsWebKit"},
    "PooToolsVideoCache": {"ptools"},
    "PooToolsFilterCamera": {"PooToolsFilterCamera"},
}
for product_name, expected_targets in expected_products.items():
    actual = target_names(product_name)
    if not expected_targets.issubset(actual):
        fail(f"{product_name} targets {sorted(actual)} do not include {sorted(expected_targets)}")

expected_target_paths = {
    "PooToolsWebKit": "PooToolsSource/WebKit",
    "PooToolsHarbethKit": "PooToolsSource/C7Collector",
    "PooToolsFilterCamera": "PooToolsSource/FilterCamera",
    "PooToolsMediaViewer": "PooToolsSource/MediaViewer",
    "ptools": "PooToolsSource",
}
for target_name, expected_path in expected_target_paths.items():
    target = targets.get(target_name)
    if target is None:
        fail(f"SwiftPM target is missing: {target_name}")
    if target.get("path") != expected_path:
        fail(f"{target_name} path is {target.get('path')!r}, expected {expected_path!r}")


def pod_block(name: str) -> str:
    pattern = rf"s\.subspec ['\"]{re.escape(name)}['\"].*?(?=\n\s*s\.subspec |\Z)"
    match = re.search(pattern, podspec, re.DOTALL)
    if match is None:
        fail(f"CocoaPods subspec is missing: {name}")
    return match.group(0)


filter_block = pod_block("FilterCamera")
if "PooTools/HarbethKit" not in filter_block or "PooTools/MediaViewer" not in filter_block:
    fail("FilterCamera does not aggregate HarbethKit and MediaViewer")
if "PooToolsSource/FilterCamera" in filter_block or "source_files" in filter_block:
    fail("FilterCamera still declares the removed source directory")

webkit_block = pod_block("WebKit")
if "PooToolsSource/WebKit" not in webkit_block or "WebKit" not in webkit_block:
    fail("WebKit does not expose the legacy source ownership")

video_cache_block = pod_block("VideoCache")
if "KTVHTTPCache" in video_cache_block:
    fail("VideoCache still declares KTVHTTPCache")

flag_block = pod_block("Flag")
if "FlagKit" in flag_block:
    fail("Flag still declares FlagKit")

forbidden_files = [root / "Package.swift", root / "PooTools.podspec"]
forbidden_files.extend((root / "PooToolsSource").rglob("*.swift"))
for path in forbidden_files:
    text = path.read_text(errors="ignore")
    if "KTVHTTPCache" in text or re.search(r"\bimport\s+FlagKit\b", text):
        fail(f"removed third-party ownership remains in {path.relative_to(root)}")

required_sources = [
    root / "PooToolsSource/WebKit/PTHTMLHeightCalculator.swift",
    root / "PooToolsSource/C7Collector/PTFilterCameraViewController.swift",
    root / "PooToolsSource/Base/PTVideoCoverCache.swift",
]
for path in required_sources:
    if not path.is_file():
        fail(f"required native source is missing: {path.relative_to(root)}")

print("PASS: CocoaPods / SwiftPM distribution parity")
print("PASS: WebKit, VideoCache and FilterCamera compatibility products are owned by PTools")
print("PASS: FlagKit and KTVHTTPCache are host-owned or removed")
PY
