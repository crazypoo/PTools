#!/usr/bin/env python3

# English: Replace placeholder deprecated-entry usage fields with reproducible source scans.
# Español: Sustituye los campos placeholder de APIs obsoletas por escaneos reproducibles.
# 中文：用可重复的源码扫描替换弃用条目中的占位字段。

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "Scripts/deprecated_6_removal_manifest.json"


DECLARATION_RE = re.compile(r"\b(?:class|struct|enum|protocol|actor|typealias|var|let|func|init|subscript)\b")


def source_lines(roots: list[Path]):
    for root in roots:
        if not root.exists():
            continue
        for path in sorted(root.rglob("*.swift")):
            in_block_comment = False
            declaration_parentheses = 0
            for number, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
                content = line
                if in_block_comment:
                    if "*/" in content:
                        in_block_comment = False
                        content = content.split("*/", 1)[1]
                    else:
                        continue
                if "/*" in content:
                    content, _ = content.split("/*", 1)
                    in_block_comment = "*/" not in line.split("/*", 1)[1]
                content = content.split("//", 1)[0]
                if content.strip():
                    declaration_line = declaration_parentheses > 0 or bool(DECLARATION_RE.search(content))
                    yield path, number, content, declaration_line
                    if declaration_line:
                        declaration_parentheses += content.count("(") - content.count(")")
                        declaration_parentheses = max(declaration_parentheses, 0)


def occurrences(pattern: str, roots: list[Path], *, declarations: bool | None = None, ignore_if: str | None = None) -> list[str]:
    matches: list[str] = []
    for path, number, line, is_declaration in source_lines(roots):
        if pattern not in line or (ignore_if and ignore_if in line):
            continue
        if declarations is not None and is_declaration != declarations:
            continue
        matches.append(f"{path.relative_to(ROOT)}:{number}")
    return matches


def alias_evidence(replacement: str) -> list[str]:
    candidates = [ROOT / "Package.swift", ROOT / "PooTools.podspec", ROOT / "Scripts/module_registry.json"]
    evidence: list[str] = []
    for root in candidates:
        if not root.exists():
            continue
        text = root.read_text(errors="ignore")
        if replacement in text:
            evidence.append(str(root.relative_to(ROOT)))
    return evidence


def main() -> None:
    payload = json.loads(MANIFEST.read_text())
    for entry in payload.get("entries", []):
        symbol = entry["symbol"]
        replacement = entry["replacement"]
        declarations = occurrences(symbol, [ROOT / "PooToolsSource"], declarations=True)
        internal = occurrences(symbol, [ROOT / "PooToolsSource"], declarations=False, ignore_if=replacement)
        example = occurrences(symbol, [ROOT / "PooTools-Example"])
        tests = occurrences(symbol, [ROOT / "Tests"])
        replacement_sources = occurrences(replacement, [ROOT / "PooToolsSource"])
        kind = entry.get("kind", "swiftSymbol")
        entry["kind"] = kind
        alias_sources = alias_evidence(replacement) if kind in {"moduleAlias", "productAlias", "subspecAlias"} else []
        entry["internalUsage"] = {"count": len(internal), "locations": internal[:50]}
        entry["declarationCount"] = len(declarations)
        entry["declarationLocations"] = declarations[:50]
        entry["exampleUsage"] = {"count": len(example), "locations": example[:50]}
        entry["testsUsage"] = {"count": len(tests), "locations": tests[:50]}
        entry["canonicalReplacementExists"] = bool(replacement_sources) or bool(alias_sources)
        entry["canonicalEvidence"] = sorted(set(replacement_sources + alias_sources))
        entry["compatibilityForwarding"] = bool(alias_sources) if kind in {"moduleAlias", "productAlias", "subspecAlias"} else bool(replacement_sources)
        entry["migrationDoc"] = "CHANGELOG.md"
        entry["consumerEvidence"] = "Deterministic source/example/test scan at VERSION 5.59.0."
        entry["removeIn"] = "6.0.0"
    MANIFEST.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    print(f"PASS [DEPRECATED_MANIFEST_GENERATED] entries={len(payload.get('entries', []))}")


if __name__ == "__main__":
    main()
