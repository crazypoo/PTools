#!/usr/bin/env python3
"""Validate the JSON source catalog before generation."""

# English: Validation fails early so duplicate identifiers never reach runtime code.
# Español: La validación falla pronto para que los identificadores duplicados no lleguen al runtime.
# 中文：先校验再生成，避免重复标识符进入运行时代码。

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CATALOG_DIR = ROOT / "PooToolsSource/PToolsDevice/Resources/DeviceCatalog"
FAMILIES = {"iPhone", "iPad", "iPod", "appleTV", "appleWatch", "mac", "homePod", "appleVision"}
PLATFORMS = {"iOS", "iPadOS", "tvOS", "watchOS", "macOS", "visionOS"}
FORM_FACTORS = {"phone", "tablet", "mediaPlayer", "watch", "desktop", "speaker", "headset", "unknown"}


def fail(message: str) -> None:
    raise SystemExit(f"catalog validation failed: {message}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--catalog-dir", type=Path, default=DEFAULT_CATALOG_DIR)
    args = parser.parse_args()

    files = sorted(args.catalog_dir.glob("*.json"))
    if not files:
        fail(f"no JSON files in {args.catalog_dir}")
    seen_identifiers: dict[str, str] = {}
    seen_models: dict[str, str] = {}
    version = None

    for path in files:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            fail(f"{path}: {error}")
        if payload.get("schemaVersion") != 1:
            fail(f"{path}: unsupported schemaVersion")
        current_version = payload.get("catalogVersion")
        if not isinstance(current_version, str) or not current_version:
            fail(f"{path}: missing catalogVersion")
        version = version or current_version
        if version != current_version:
            fail(f"{path}: catalogVersion differs from other files")

        for device in payload.get("devices", []):
            required = ("id", "marketingName", "family", "platform", "identifiers", "formFactor")
            missing = [key for key in required if key not in device]
            if missing:
                fail(f"{path}: {device!r} missing {missing}")
            model_id = device["id"]
            if model_id in seen_models:
                fail(f"duplicate model id {model_id} in {path} and {seen_models[model_id]}")
            seen_models[model_id] = str(path)
            if not device["marketingName"].strip():
                fail(f"{path}: empty marketingName for {model_id}")
            if device["family"] not in FAMILIES:
                fail(f"{path}: invalid family {device['family']}")
            if device["platform"] not in PLATFORMS:
                fail(f"{path}: invalid platform {device['platform']}")
            if device["formFactor"] not in FORM_FACTORS:
                fail(f"{path}: invalid formFactor {device['formFactor']}")
            year = device.get("releaseYear")
            if year is not None and (not isinstance(year, int) or year < 2000 or year > 2100):
                fail(f"{path}: invalid releaseYear for {model_id}")
            if not device["identifiers"]:
                fail(f"{path}: empty identifiers for {model_id}")
            for identifier in device["identifiers"]:
                if identifier in seen_identifiers:
                    fail(f"duplicate identifier {identifier} in {path} and {seen_identifiers[identifier]}")
                seen_identifiers[identifier] = str(path)

    print(f"validated {len(seen_models)} models and {len(seen_identifiers)} identifiers (version {version})")


if __name__ == "__main__":
    main()
