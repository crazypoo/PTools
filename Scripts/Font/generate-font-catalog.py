#!/usr/bin/env python3

"""Generate the reviewed font catalog and its Swift compatibility sources.

English: The catalog is the source of truth; generated Swift must not be edited by hand.
Español: El catálogo es la fuente de verdad; el Swift generado no debe editarse manualmente.
中文：目录是唯一事实来源；生成的 Swift 禁止手工编辑。
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CATALOG = ROOT / "PooToolsSource/Font/Resources/FontCatalog/FontCatalog.json"
DEFAULT_OUTPUT = ROOT / "PooToolsSource/Font/Generated"


def lower_first(value: str) -> str:
    return value[:1].lower() + value[1:]


def read_legacy(path: Path) -> list[dict[str, object]]:
    pattern = re.compile(
        r"public static let (?P<swift>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*"
        r"FontName\.fontName\(fontName:\s*\"(?P<post>[^\"]+)\""
    )
    fonts: list[dict[str, object]] = []
    seen_postscript: set[str] = set()
    for match in pattern.finditer(path.read_text(encoding="utf-8")):
        postscript = match.group("post")
        if postscript in seen_postscript:
            continue
        seen_postscript.add(postscript)
        family = postscript.rsplit("-", 1)[0]
        fonts.append(
            {
                "swiftName": lower_first(match.group("swift")),
                "postScriptName": postscript,
                "familyName": family,
                "introducedIOS": "17.0",
                "deprecatedIOS": None,
                "aliases": [],
            }
        )
    return sorted(fonts, key=lambda item: str(item["postScriptName"]))


def load_catalog(path: Path) -> dict[str, object]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    validate_catalog(payload)
    return payload


def validate_catalog(payload: dict[str, object]) -> None:
    fonts = payload.get("fonts")
    if not isinstance(fonts, list) or not fonts:
        raise ValueError("Font catalog must contain a non-empty fonts array")
    swift_names: set[str] = set()
    postscript_names: set[str] = set()
    for font in fonts:
        if not isinstance(font, dict):
            raise ValueError("Each font entry must be an object")
        required = {"swiftName", "postScriptName", "familyName", "introducedIOS", "deprecatedIOS", "aliases"}
        missing = required - set(font)
        if missing:
            raise ValueError(f"Font entry is missing {sorted(missing)}")
        swift_name = str(font["swiftName"])
        postscript = str(font["postScriptName"])
        family = str(font["familyName"])
        if not swift_name or not postscript or not family:
            raise ValueError("swiftName, postScriptName and familyName must be non-empty")
        if swift_name in swift_names:
            raise ValueError(f"Duplicate swiftName: {swift_name}")
        if postscript in postscript_names:
            raise ValueError(f"Duplicate postScriptName: {postscript}")
        swift_names.add(swift_name)
        postscript_names.add(postscript)
        introduced = str(font["introducedIOS"])
        deprecated = font["deprecatedIOS"]
        if not re.fullmatch(r"\d+(?:\.\d+){0,2}", introduced):
            raise ValueError(f"Invalid introducedIOS: {introduced}")
        if deprecated is not None and not re.fullmatch(r"\d+(?:\.\d+){0,2}", str(deprecated)):
            raise ValueError(f"Invalid deprecatedIOS: {deprecated}")
        if not isinstance(font["aliases"], list):
            raise ValueError(f"aliases must be an array for {postscript}")


def swift_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def write_generated(payload: dict[str, object], output_dir: Path) -> None:
    fonts = payload["fonts"]
    assert isinstance(fonts, list)
    output_dir.mkdir(parents=True, exist_ok=True)

    catalog_lines = [
        "// AUTO-GENERATED FILE — DO NOT EDIT.",
        "// Generator: Scripts/Font/generate-font-catalog.py",
        f"// Catalog version: {payload.get('catalogVersion', 'unknown')}",
        "// English: Generated immutable metadata for the PTFont catalog.",
        "// Español: Metadatos inmutables generados para el catálogo PTFont.",
        "// 中文：PTFont 目录的不可变元数据生成文件。",
        "",
        "import Foundation",
        "",
        "public extension PTFont {",
    ]
    for font in fonts:
        assert isinstance(font, dict)
        name = str(font["swiftName"])
        catalog_lines.extend(
            [
                f"    static let {name} = PTFont(",
                f"        postScriptName: {swift_string(str(font['postScriptName']))},",
                f"        familyName: {swift_string(str(font['familyName']))},",
                f"        introducedIOS: {swift_string(str(font['introducedIOS']))}",
                "    )",
                "",
            ]
        )
    catalog_lines.extend(["}", "", "internal enum PTFontCatalogGenerated {", "    static let allFonts: [PTFont] = ["])
    catalog_lines.extend(f"        .{font['swiftName']}," for font in fonts)
    catalog_lines.extend(["    ]", "}", ""])
    (output_dir / "PTFontCatalog.generated.swift").write_text("\n".join(catalog_lines), encoding="utf-8")

    compatibility_lines = [
        "// AUTO-GENERATED FILE — DO NOT EDIT.",
        "// Generator: Scripts/Font/generate-font-catalog.py",
        "// English: 5.x FontName compatibility forwards to the reviewed PTFont catalog.",
        "// Español: La compatibilidad FontName de 5.x reenvía al catálogo PTFont revisado.",
        "// 中文：5.x FontName 兼容入口统一转发到已审核的 PTFont 目录。",
        "",
        "import Foundation",
        "",
        "public extension FontName {",
    ]
    for font in fonts:
        assert isinstance(font, dict)
        old_name = str(font["swiftName"])[0].upper() + str(font["swiftName"])[1:]
        compatibility_lines.extend(
            [
                "    @available(*, deprecated, message: \"Use PTFont catalog values instead.\")",
                f"    static let {old_name} = PTFont.{font['swiftName']}.postScriptName",
                "",
            ]
        )
    compatibility_lines.extend(
        [
            "    @available(*, deprecated, message: \"Use PTFontCatalog.allFonts instead.\")",
            "    static func fontNames() -> [String] {",
            "        PTFontCatalog.allFonts.map(\\.postScriptName)",
            "    }",
            "}",
            "",
        ]
    )
    (output_dir / "PTFontCompatibility.generated.swift").write_text("\n".join(compatibility_lines), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--from-legacy", type=Path)
    parser.add_argument("--catalog", type=Path, default=DEFAULT_CATALOG)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--generate", action="store_true")
    args = parser.parse_args()

    if args.from_legacy:
        fonts = read_legacy(args.from_legacy)
        payload = {
            "schemaVersion": 1,
            "catalogVersion": "5.60.0",
            "source": "PooToolsSource/Font/FontName.swift legacy compatibility inventory",
            "fonts": fonts,
        }
        validate_catalog(payload)
        args.catalog.parent.mkdir(parents=True, exist_ok=True)
        args.catalog.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if args.generate:
        write_generated(load_catalog(args.catalog), args.output)


if __name__ == "__main__":
    main()
