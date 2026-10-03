#!/usr/bin/env python3

"""Validate the reviewed FontCatalog source of truth.

English: Runtime absence is not treated as Apple deprecation.
Español: La ausencia en un runtime no se trata como deprecación de Apple.
中文：某个 Runtime 中缺失字体不等于 Apple 已废弃该字体。
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CATALOG = ROOT / "PooToolsSource/Font/Resources/FontCatalog/FontCatalog.json"


def main() -> int:
    payload = json.loads(CATALOG.read_text(encoding="utf-8"))
    fonts = payload.get("fonts", [])
    if not isinstance(fonts, list) or not fonts:
        print("FAIL [FONT_CATALOG] fonts must be a non-empty array")
        return 1
    swift_names = [item.get("swiftName") for item in fonts]
    postscript_names = [item.get("postScriptName") for item in fonts]
    if len(swift_names) != len(set(swift_names)):
        print("FAIL [FONT_CATALOG] duplicate swiftName")
        return 1
    if len(postscript_names) != len(set(postscript_names)):
        print("FAIL [FONT_CATALOG] duplicate postScriptName")
        return 1
    for item in fonts:
        if not re.fullmatch(r"[a-zA-Z_][a-zA-Z0-9_]*", str(item.get("swiftName", ""))):
            print("FAIL [FONT_CATALOG] swiftName is not a valid Swift identifier")
            return 1
        if not item.get("familyName"):
            print("FAIL [FONT_CATALOG] familyName must be non-empty")
            return 1
        for key in ("introducedIOS", "deprecatedIOS"):
            value = item.get(key)
            if value is not None and not re.fullmatch(r"\d+(?:\.\d+){0,2}", str(value)):
                print(f"FAIL [FONT_CATALOG] invalid {key}: {value}")
                return 1
        aliases = item.get("aliases", [])
        if not isinstance(aliases, list):
            print("FAIL [FONT_CATALOG] aliases must be an array")
            return 1
        if len(aliases) != len(set(aliases)):
            print("FAIL [FONT_CATALOG] aliases must be unique")
            return 1
        if item.get("postScriptName") in aliases or item.get("swiftName") in aliases:
            print("FAIL [FONT_CATALOG] canonical name cannot be its own alias")
            return 1
        introduced = tuple(int(part) for part in str(item["introducedIOS"]).split("."))
        deprecated = item.get("deprecatedIOS")
        if deprecated is not None and tuple(int(part) for part in str(deprecated).split(".")) < introduced:
            print("FAIL [FONT_CATALOG] deprecatedIOS cannot precede introducedIOS")
            return 1
    print(f"PASS [FONT_CATALOG] fonts={len(fonts)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
