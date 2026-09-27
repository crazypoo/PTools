#!/usr/bin/env python3
"""Check identifiers against the generated source catalog without guessing marketing names."""

# English: Unknown identifiers remain safe runtime values and are reported explicitly.
# Español: Los identificadores desconocidos siguen siendo valores seguros y se informan explícitamente.
# 中文：未知标识符保持安全运行时值，并被明确报告。

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CATALOG_DIR = ROOT / "PooToolsSource/PToolsDevice/Resources/DeviceCatalog"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("identifiers", nargs="+")
    parser.add_argument("--catalog-dir", type=Path, default=DEFAULT_CATALOG_DIR)
    args = parser.parse_args()
    known = set()
    for path in args.catalog_dir.glob("*.json"):
        payload = json.loads(path.read_text(encoding="utf-8"))
        for device in payload.get("devices", []):
            known.update(device.get("identifiers", []))
    unknown = [identifier for identifier in args.identifiers if identifier not in known]
    if unknown:
        print("unknown identifiers: " + ", ".join(unknown))
        raise SystemExit(1)
    print("all identifiers are known")


if __name__ == "__main__":
    main()
