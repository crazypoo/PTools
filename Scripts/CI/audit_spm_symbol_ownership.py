#!/usr/bin/env python3
# English: Index Swift declarations and high-confidence cross-target references for SwiftPM review.
# Español: Indexa declaraciones Swift y referencias entre targets de alta confianza para la revisión de SwiftPM.
# 中文：索引 Swift 声明和高置信度跨 target 引用，供 SwiftPM 审计使用。

from __future__ import annotations

import csv
import argparse
import json
import re
from collections import defaultdict
from pathlib import Path
from typing import Any


ACCESS = r"(?:(public|open|package|internal|fileprivate|private)\s+)?"
DECLARATION = re.compile(
    rf"^\s*{ACCESS}(?:final\s+|indirect\s+|nonisolated\s+)*(class|struct|enum|protocol|actor|typealias)\s+([A-Za-z_][A-Za-z0-9_]*)"
)
EXTENSION = re.compile(r"^\s*(?:public\s+|internal\s+|private\s+|package\s+)?extension\s+([A-Za-z_][A-Za-z0-9_.<>]*)")
MEMBER = re.compile(
    rf"^\s*{ACCESS}(?:static\s+|class\s+|final\s+|mutating\s+|override\s+|nonisolated\s+)*"
    r"(func|var|let|init|subscript)\s+([A-Za-z_][A-Za-z0-9_]*)?"
)
IMPORT = re.compile(r"^\s*(?:@testable\s+)?import\s+([A-Za-z_][A-Za-z0-9_]*)", re.MULTILINE)

# English: These names are not the complete scanner; they are high-confidence probes for the known boundary families.
# Español: Estos nombres no sustituyen el escáner completo; son sondas de alta confianza para las fronteras conocidas.
# 中文：这些名称不是完整扫描器，只是针对已知边界族的高置信度探针。
KNOWN_SYMBOLS = {
    "addSubviews": "ptools",
    "removeAllSubviews": "ptools",
    "emojiToImage": "ptools",
    "appfont": "ptools",
    "DevMaskColor": "ptools",
    "base_alertVC": "ptools",
    "createImageWithColor": "ptools",
    "fixOrientation": "ptools",
    "gcdRunUnsafely": "ptools",
    "getCurrentVC": "ptools",
    "kSCREEN_HEIGHT": "ptools",
    "kSCREEN_WIDTH": "ptools",
    "randomColor": "ptools",
    "resize_vI": "ptools",
    "stringIsEmpty": "ptools",
    "transformImage": "ptools",
    "viewCorner": "ptools",
    "PTAdaptiveBarCoordinator": "ptools",
    "PTAdaptiveBarEdge": "ptools",
    "PTAdaptiveBarLayoutContext": "ptools",
    "PTAdaptiveNavigationContainer": "ptools",
    "PTAdaptiveReservedRegion": "ptools",
    "PTAdaptiveVisibleRegionResolver": "ptools",
    "PTActionLayoutButton": "ptools",
    "PTAlertTipsViewController": "ptools",
    "PTAnimationFunction": "ptools",
    "PTAppStoreFunction": "ptools",
    "PTBaseButton": "ptools",
    "PTBaseNavControl": "ptools",
    "PTBaseNormalCell": "ptools",
    "PTBaseViewController": "ptools",
    "PTClampedPropertyWrapper": "ptools",
    "PTCollectionView": "ptools",
    "PTCollectionViewConfig": "ptools",
    "PTCollectionViewType": "ptools",
    "PTControlMenuFactory": "ptools",
    "PTControlMenuSelectionItem": "ptools",
    "PTCoreUserDefaultsWrapper": "ptools",
    "PTFontRuntime": "ptools",
    "PTLayoutButton": "ptools",
    "PTMediaSaveService": "ptools",
    "PTNavBar": "ptools",
    "PTNSLogConsole": "ptools",
    "PTOpenSystemConfig": "ptools",
    "PTOpenSystemFunction": "ptools",
    "PTProgressSnapshot": "PToolsCore",
    "PTResponseMetadata": "PToolsCore",
    # English: Probe rich-text contracts that must be imported by independent UI targets.
    # Español: Comprueba los contratos de texto enriquecido que los targets UI independientes deben importar.
    # 中文：检查独立 UI target 必须显式导入的富文本契约。
    "PTRichText": "PToolsUIFoundation",
    "PTTextActionID": "PToolsUIFoundation",
    "PTTextActionRegistry": "PToolsUIFoundation",
    "PTRows": "ptools",
    "PTSceneContext": "ptools",
    "PTSection": "ptools",
    "PTScreenShotImageHandle": "ptools",
    "PTSwitch": "ptools",
    "PTTabBarAppearance": "ptools",
    "PTTabBarImageContent": "ptools",
    "PTTabBarItemView": "ptools",
    "PTTabBarLayoutAppearance": "ptools",
    "PTTabBarLayoutEngine": "ptools",
    "PTUnavailableManager": "ptools",
    "PTUtils": "ptools",
    "PTVideoCoverCache": "ptools",
    "PTVideoExportError": "ptools",
    "PTVideoThumbnailService": "ptools",
    # English: Probe the public URL media classifier used by independent media targets.
    # Español: Comprueba el clasificador público de medios URL usado por los targets multimedia independientes.
    # 中文：检查独立媒体 target 使用的公开 URL 媒体分类入口。
    "pt_isVideoResource": "ptools",
    "PTSymbolResolver": "PToolsSymbols",
    "PTSymbol": "PToolsSymbols",
    "PTFeedbackCenter": "PToolsCore",
    "PTLoadImageFunction": "ptools",
    "PTDarkModeOption": "ptools",
    "PTAppBaseConfig": "ptools",
}


def root_and_inventory() -> tuple[Path, list[dict[str, Any]], dict[str, list[str]]]:
    root = Path(__file__).resolve().parents[2]
    targets = json.loads((root / "report/spm/inventory/manifest_targets.json").read_text())
    ownership = json.loads((root / "report/spm/inventory/source_ownership.json").read_text())["owners"]
    return root, targets, ownership


def owner_for(path: str, ownership: dict[str, list[str]]) -> str:
    owners = ownership.get(path, [])
    return owners[0] if owners else "unowned"


def line_number(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()
    root, targets, ownership = root_and_inventory()
    output = root / "report/spm/audits"
    output.mkdir(parents=True, exist_ok=True)
    target_map = {target["name"]: target for target in targets}
    declarations: list[dict[str, Any]] = []
    symbol_targets: dict[str, set[str]] = defaultdict(set)
    references: list[dict[str, Any]] = []
    findings: list[dict[str, Any]] = []

    for relative in sorted(ownership):
        if not relative.endswith(".swift"):
            continue
        path = root / relative
        if not path.is_file():
            continue
        text = path.read_text(errors="replace")
        owner = owner_for(relative, ownership)
        imports = sorted(set(IMPORT.findall(text)))
        for number, line in enumerate(text.splitlines(), start=1):
            declaration = DECLARATION.match(line)
            if declaration:
                access, kind, name = declaration.groups()
                access = access or "internal"
                item = {
                    "symbolID": f"{owner}:{name}:{number}",
                    "symbolName": name,
                    "declarationPath": relative,
                    "line": number,
                    "ownerTarget": owner,
                    "kind": kind,
                    "accessLevel": access,
                    "extensionReceiverType": "",
                    "availability": "@available" if "@available" in line else "",
                    "conditionalCompilationBranch": "",
                }
                declarations.append(item)
                symbol_targets[name].add(owner)
            extension = EXTENSION.match(line)
            if extension:
                receiver = extension.group(1)
                declarations.append({
                    "symbolID": f"{owner}:extension:{receiver}:{number}",
                    "symbolName": receiver,
                    "declarationPath": relative,
                    "line": number,
                    "ownerTarget": owner,
                    "kind": "extension",
                    "accessLevel": "public" if line.lstrip().startswith("public") else "internal",
                    "extensionReceiverType": receiver,
                    "availability": "@available" if "@available" in line else "",
                    "conditionalCompilationBranch": "",
                })
            member = MEMBER.match(line)
            if member and member.group(2):
                access, kind, name = member.groups()
                declarations.append({
                    "symbolID": f"{owner}:{name}:{number}",
                    "symbolName": name,
                    "declarationPath": relative,
                    "line": number,
                    "ownerTarget": owner,
                    "kind": kind,
                    "accessLevel": access or "internal",
                    "extensionReceiverType": "",
                    "availability": "@available" if "@available" in line else "",
                    "conditionalCompilationBranch": "",
                })

        for symbol, required_import in KNOWN_SYMBOLS.items():
            for match in re.finditer(rf"\b{re.escape(symbol)}\b", text):
                line = line_number(text, match.start())
                source_line = text.splitlines()[line - 1]
                if re.match(r"^\s*(?:public|open|package|internal|private)?\s*(?:extension|class|struct|enum|protocol|actor|typealias|func|var|let|init)\b", source_line):
                    continue
                if source_line.lstrip().startswith(("//", "*", "#")):
                    continue
                reference = {
                    "symbolName": symbol,
                    "referencePath": relative,
                    "line": line,
                    "ownerTarget": owner,
                    "requiredModule": required_import,
                    "currentImports": ";".join(imports),
                    "ownerCandidates": ";".join(sorted(symbol_targets.get(symbol, {required_import}))),
                }
                references.append(reference)
                target_dependencies = set(target_map.get(owner, {}).get("dependencies", []))
                if owner == required_import:
                    status = "closed"
                    severity = "info"
                    fix_strategy = "symbol-owned-by-current-target"
                elif required_import in imports or (required_import == "ptools" and "ptools" in imports):
                    if required_import in target_dependencies:
                        status = "needs-build-confirmation"
                        severity = "low"
                        fix_strategy = "direct-dependency-and-explicit-import"
                    else:
                        status = "open"
                        severity = "high"
                        fix_strategy = "explicit-import-without-manifest-dependency"
                elif required_import in target_dependencies:
                    status = "open"
                    severity = "high"
                    fix_strategy = "direct-dependency-missing-file-import"
                else:
                    status = "open"
                    severity = "high"
                    fix_strategy = "add-direct-import-or-use-native-api"
                findings.append({
                    "source": relative,
                    "line": line,
                    "ownerTarget": owner,
                    "requiredTarget": required_import,
                    "currentImport": ";".join(imports),
                    "symbolName": symbol,
                    "severity": severity,
                    "status": status,
                    "fixStrategy": fix_strategy,
                    "fixCommit": "working-tree-5.65.5" if status != "open" else "",
                    "buildEvidence": "pending-isolated-consumer" if status != "closed" else "static-dependency-check",
                })

    (output / "symbol_declarations.json").write_text(json.dumps(declarations, ensure_ascii=False, indent=2) + "\n")
    (output / "symbol_references.json").write_text(json.dumps(references, ensure_ascii=False, indent=2) + "\n")
    # English: Keep generated CSVs line-ending stable across macOS and CI runners.
    # Español: Mantén estables los finales de línea de los CSV generados entre macOS y CI.
    # 中文：确保生成的 CSV 在 macOS 和 CI Runner 上使用一致的换行符。
    with (output / "cross_target_findings.csv").open("w", newline="") as handle:
        columns = ["source", "line", "ownerTarget", "requiredTarget", "currentImport", "symbolName", "severity", "status", "fixStrategy", "fixCommit", "buildEvidence"]
        writer = csv.DictWriter(handle, fieldnames=columns, lineterminator="\n")
        writer.writeheader()
        writer.writerows(findings)
    with (output / "public_api_contracts.csv").open("w", newline="") as handle:
        columns = ["symbolID", "symbolName", "declarationPath", "line", "ownerTarget", "kind", "accessLevel", "extensionReceiverType", "availability", "conditionalCompilationBranch"]
        writer = csv.DictWriter(handle, fieldnames=columns, lineterminator="\n")
        writer.writeheader()
        writer.writerows(declarations)
    with (output / "category_public_api_ownership.csv").open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["path", "ownerTarget", "category_extension", "public_member_count"], lineterminator="\n")
        writer.writeheader()
        for relative in sorted(ownership):
            if "/Category/" not in f"/{relative}" or not relative.endswith(".swift"):
                continue
            count = sum(1 for item in declarations if item["declarationPath"] == relative and item["accessLevel"] in {"public", "open"})
            writer.writerow({"path": relative, "ownerTarget": owner_for(relative, ownership), "category_extension": "yes", "public_member_count": count})

    open_findings = sum(1 for finding in findings if finding["status"] == "open")
    print(f"declarations={len(declarations)} references={len(references)} findings={len(findings)} open={open_findings}")
    if args.strict and open_findings:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
