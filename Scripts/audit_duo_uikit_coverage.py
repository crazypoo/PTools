#!/usr/bin/env python3
"""Inventory UIKit code and local-geometry risks for the iPhone Duo gate.

English: This is a conservative inventory, not a Swift parser or a proof of a bug.
Español: Este inventario es conservador; no es un parser de Swift ni prueba un bug.
中文：这是保守的清单工具，不是 Swift 语法解析器，也不能单凭命中证明存在 Bug。
"""

from __future__ import annotations

import argparse
import csv
import fnmatch
import hashlib
import json
import os
import re
import subprocess
from datetime import datetime, timezone
from collections import defaultdict
from functools import lru_cache
from pathlib import Path


ROOTS = ("PooToolsSource", "Sources", "PooTools", "Example", "Tests")
AUDIT_RULE_VERSION = "5.69.0-duo-2026-10-24-r4"
REPORT_FILES = (
    "report/current/duo_uikit_inventory.csv",
    "report/current/duo_global_geometry_hits.json",
    "report/current/duo_finding_evidence.json",
    "report/current/duo_coverage.md",
)
REVIEW_REGISTRY_PATH = "Scripts/duo_geometry_review_registry.json"

# English: A finding is closed only when its source checks pass; the desired result is not a decision by itself.
# Español: Un hallazgo solo se cierra cuando pasan sus comprobaciones; el resultado deseado no es la decisión por sí solo.
# 中文：只有源码检查通过，审计项才会关闭；期望结果本身不能直接作为结论。
FOCUS_FINDINGS = {
    "DUO-A01": {"path": "PooToolsSource/Core/PTMarcos_swift.swift", "static_policy": "display-only-allowed", "required": ("PTLegacyScreenGeometry", "kSCREEN_BOUNDS", "kSCREEN_SIZE", "kSCREEN_SCALE"), "forbidden": (), "reason": "历史兼容全局值，仅允许展示、像素或兼容读取"},
    "DUO-A02": {"path": "PooToolsSource/Category/AutoScale+PTEX.swift", "static_policy": "fixed", "required": ("autoWidth(in view", "autoHeight(in view", "safeRect", "autoWidth(inch)", "autoHeight(inch)"), "forbidden": (), "reason": "新版缩放支持 View-local overload，旧入口保留兼容"},
    "DUO-A03": {"path": "PooToolsSource/Inspector/ElementInspectorConfiguration.swift", "static_policy": "fixed", "required": ("panelPreferredCompressedSize(in bounds", "hostWidth"), "forbidden": (), "reason": "面板宽度从宿主 bounds 解析"},
    "DUO-A04": {"path": "PooToolsSource/WhereIsMyEye/PTEyeTrackingDataManager.swift", "static_policy": "fixed", "required": ("PTEyeTrackingCalibrationState", "needsRecalibration", "updateCalibration", "invalidateCalibration"), "forbidden": (), "reason": "物理标定与 View 坐标映射分离，并对不可信状态降级"},
    "DUO-A05": {"path": "PooToolsSource/Category/UIScreen+PTEX.swift", "static_policy": "display-only-allowed", "required": ("display metadata only", "size(for window"), "forbidden": (), "reason": "UIScreen.size 仅作为显示器元数据"},
    "DUO-A06": {"path": "PooToolsSource/Category/CGFloat+PTEX.swift", "static_policy": "fixed", "required": ("leftSafeAreaWidth(in view", "rightSafeAreaWidth(in view", "AppWindows?.safeAreaInsets"), "forbidden": (), "reason": "旧安全区符号保留兼容，新布局提供局部 View 入口"},
    "DUO-N01": {"path": "PooToolsSource/Category/UIImageView+PTEX.swift", "static_policy": "fixed", "required": ("bounds", "window?.screen.scale"), "forbidden": ("UIScreen.main", "kSCREEN_WIDTH"), "reason": "同一 Window 坐标系和可视 pane 判断"},
    "DUO-N02": {"path": "PooToolsSource/PhotoPicker/PTMediaLibViewController.swift", "static_policy": "fixed", "required": ("ptSheetPullBarFrame", "pullBarFrame", "contentInset", "verticalScrollIndicatorInsets"), "forbidden": ("pullBarHeight ?? 0) / 2",), "reason": "fakeNav 使用真实 pullbar frame、本地 safe area 和幂等 inset 更新"},
    "DUO-N03": {"path": "PooToolsSource/Base/PTBaseWebViewController.swift", "static_policy": "fixed", "required": ("viewSafeAreaInsetsDidChange", "navigation"), "forbidden": ("UIScreen.main", "kSCREEN_WIDTH"), "reason": "WebView top constraint 使用实测局部导航边界"},
    "DUO-N04": {"path": "PooToolsSource/MediaViewer/PTMediaBrowserCell.swift", "static_policy": "fixed", "required": ("bounds", "visibleRect"), "forbidden": ("UIScreen.main", "kSCREEN_WIDTH"), "reason": "零尺寸时延后解码而不是读取主屏"},
    "DUO-N05": {"path": "PooToolsSource/LocalConsole/LocalConsole.swift", "static_policy": "fixed", "required": ("windowsBySceneID", "windowScene"), "forbidden": ("UIScreen.main", "kSCREEN_WIDTH"), "reason": "控制台方向和起始位置使用宿主 bounds"},
    "DUO-N06": {"path": "PooToolsSource/Inspector/ViewHierarchyRoot.swift", "static_policy": "fixed", "required": ("inspected window", "windows"), "forbidden": ("UIScreen.main", "kSCREEN_WIDTH"), "reason": "Inspector 根节点跟随被检查 Window"},
    "DUO-N07": {"path": "PooToolsSource/QRCodeScan/PTScanQRController.swift", "static_policy": "fixed", "required": ("safeAreaLayoutGuide", "view.bounds"), "forbidden": ("UIScreen.main", "kSCREEN_WIDTH"), "reason": "扫码控件使用宿主 safe area"},
    "DUO-N08": {"path": "PooToolsSource/DebugNetwork/PTNetworkWatcherViewController.swift", "static_policy": "fixed", "required": ("hostView", "safeAreaInsets"), "forbidden": ("UIScreen.main", "kSCREEN_WIDTH"), "reason": "Debug overlay 使用当前控制器宿主"},
    "DUO-N09": {"path": "PooToolsSource/Category/UIImage+PTEX.swift", "static_policy": "fixed", "required": ("scale",), "forbidden": ("kSCREEN_WIDTH",), "reason": "像素化尺度脱离主屏幕宽度"},
}

# English: Intentional legacy/display hits require a path, kind, reviewer, and reason.
# Español: Los aciertos heredados o de metadatos requieren ruta, tipo, revisor y motivo.
# 中文：历史兼容或显示元数据命中必须登记路径、类型、审核人和原因。
LEGACY_GEOMETRY_ALLOWLIST = {
    "PooToolsSource/Core/PTMarcos_swift.swift": (None, "Public compatibility snapshots; not a layout source.", "PTools Duo audit"),
    "PooToolsSource/Category/CGFloat+PTEX.swift": ({"kSCREEN", "UIScreen.main", "safe-area-global"}, "Legacy scalar APIs and display-scale compatibility.", "PTools Duo audit"),
    "PooToolsSource/Category/UIScreen+PTEX.swift": ({"UIScreen.main", "UIScreen.size"}, "Display metadata only; window-local size API is available.", "PTools Duo audit"),
    "PooToolsSource/Category/UICollectionView+PTEX.swift": ({"kSCREEN"}, "Legacy default width when no owner view is supplied.", "PTools Duo audit"),
    "PooToolsSource/Category/UIImage+PTEX.swift": ({"UIScreen.main"}, "Pixel-domain image processing, not UIKit placement.", "PTools Duo audit"),
    "PooToolsSource/C7Collector/PTHarBethFilter.swift": ({"kSCREEN"}, "Render texture default; caller can provide a local texture size.", "PTools Duo audit"),
    "PooToolsSource/C7Collector/PTFilterCameraViewController.swift": ({"kSCREEN"}, "Camera image-processing output size.", "PTools Duo audit"),
    "PooToolsSource/Loading/PTHudView.swift": ({"kSCREEN"}, "Legacy maximum configuration bound.", "PTools Duo audit"),
    "PooToolsSource/DarkMode/PTDarkFollowSystemFooter.swift": ({"kSCREEN"}, "Static legacy text layout default; runtime containers override it.", "PTools Duo audit"),
    "PooToolsSource/DarkMode/PTDarkSmartFooter.swift": ({"kSCREEN"}, "Static legacy text layout default; runtime containers override it.", "PTools Duo audit"),
    "PooToolsSource/DebugCrash/PTCrashDetailViewController.swift": ({"kSCREEN"}, "Legacy text measurement fallback.", "PTools Duo audit"),
    "PooToolsSource/DebugCrash/PTCrashLogViewController.swift": ({"kSCREEN"}, "Legacy text measurement fallback.", "PTools Duo audit"),
    "PooToolsSource/DebugFile/PTFileBrowserViewController.swift": ({"kSCREEN"}, "Popover fallback frame; current window is preferred when available.", "PTools Duo audit"),
    "PooToolsSource/DebugLibs/PTLoadedLibsViewController.swift": ({"kSCREEN"}, "Legacy debug title sizing fallback.", "PTools Duo audit"),
    "PooToolsSource/DebugPerformance/PTDebugPerformanceViewController.swift": ({"kSCREEN"}, "Debug-only layout fallback.", "PTools Duo audit"),
    "PooToolsSource/DebugPerformance/PTDebugPerformanceToolKit.swift": ({"kSCREEN", "statusBarHeight"}, "Debug floating control fallback.", "PTools Duo audit"),
    "PooToolsSource/DebugRuler/PTViewRulerPlugin.swift": ({"kSCREEN"}, "Debug overlay fallback before host layout.", "PTools Duo audit"),
    "PooToolsSource/DebugColor/PTColorPickPlugin.swift": ({"kSCREEN"}, "Pixel color conversion scale.", "PTools Duo audit"),
    "PooToolsSource/PermissionCore/PTPermissionHeader.swift": ({"kSCREEN"}, "Legacy compatibility API; new callers pass container width.", "PTools Duo audit"),
    "PooToolsSource/PermissionCore/PTPermissionViewController.swift": ({"kSCREEN"}, "Legacy compatibility path retained outside local header measurement.", "PTools Duo audit"),
    "PooToolsSource/Protocol/PTProtocol.swift": ({"kSCREEN"}, "Legacy device scaling policy.", "PTools Duo audit"),
    "PooToolsSource/Stepper/PTStepperView.swift": ({"kSCREEN"}, "Legacy content width fallback when no local width exists.", "PTools Duo audit"),
    "PooToolsSource/LocalConsole/LocalConsole.swift": ({"UIScreen.main"}, "Debug display diagnostics only; never used for feature layout.", "PTools Duo audit"),
}

# English: These are the geometry patterns that can block a release; pixels, assets, and generic reloads stay informational.
# Español: Estos patrones geométricos pueden bloquear una versión; píxeles, recursos y recargas genéricas son informativos.
# 中文：只有这些几何模式可以阻断发布；像素、资源和普通 reload 仅作信息记录。
HIGH_RISK_KINDS = {
    "UIScreen.main",
    "kSCREEN",
    "statusBarHeight",
    "keyWindow",
    "screen.bounds",
    "kNavBarHeight_Total",
    "kTabbarHeight_Total",
    "safe-area-global",
    "AppWindows",
    "convert-to-nil",
}

# English: Map source owners to the named tests that actually exercise their geometry; never copy an entire test target.
# Español: Mapea propietarios de código a pruebas con nombre que ejercen su geometría; nunca copia un target completo.
# 中文：把源码 owner 映射到真正验证其几何行为的具名测试，禁止把整个测试 target 灌入每个文件。
MODULE_TEST_CASES = {
    "Base": (
        "testVerticalNavAndTabsNeverOverlap",
        "testVerticalRailNavTabAccessoryOverflowNoCollision",
        "testAsymmetricSafeAreaIsNotDoubleApplied",
        "testVisiblePanesExcludeEveryActiveReservedRegion",
        "testNoInteractiveFrameOverlapsReservedRegion",
        "testLayoutSignatureChangesOnlyWithGeometry",
        "testNoInfiniteLayoutInvalidationOnResize",
        "testSplitViewCollapseExpandRetainsSelection",
        "testRTLVerticalEdgeFollowsSystem",
        "testMultiSceneDoesNotReuseStaleGeometry",
    ),
    "Category": (
        "testSequenceAndArrayHelpersPreserveOrder",
        "testDictionaryHelpersUseExplicitOrderingAndTypedPaths",
        "testOptionalRangeAndURLHelpers",
    ),
    "PhotoPicker": (
        "testPhotoGridItemFramesStayWithinUsablePanes",
        "testMultiSceneDoesNotReuseStaleGeometry",
    ),
    "MediaViewer": (
        "testPagingFourMediaAfterResizePreservesItemIdentity",
        "testMultiSceneDoesNotReuseStaleGeometry",
    ),
    "VideoEditor": (
        "testEditorCropCoordinatesAfterResize",
    ),
    "WhereIsMyEye": (
        "testEmptyViewportDoesNotEmitOrigin",
        "testInvalidationRejectsOriginUntilCalibrationIsValid",
        "testDisplayOrSceneChangeRequiresRecalibration",
        "testRotationOnlyUpdatesLocalViewportAndKeepsPhysicalCalibration",
        "testTrackingSessionResetClearsSamplesAndMarksPreciseCalibrationStale",
    ),
}
UI_IMPORT = re.compile(r"^\s*import\s+UIKit(?:\.|$)", re.MULTILINE)
SWIFTUI_IMPORT = re.compile(r"^\s*import\s+SwiftUI(?:\.|$)", re.MULTILINE)
UI_SYMBOLS = re.compile(
    r"\b(?:UIView|UIViewController|UICollectionView|UITableView|UIScrollView|"
    r"UIWindowScene|UIPresentationController|UIBarButtonItem|UITabBarItem)\b"
)
EXTENSION_UI = re.compile(
    r"\bextension\s+(?:UIView|UIViewController|UICollectionView|UITableView|"
    r"UIScrollView|UIWindow|UIControl|UILabel|UIImageView|UIButton)\b"
)
PUBLIC_API = re.compile(r"\b(?:public|open)\b|@objc")

# English: Map source folders to the canonical demo owners used by the catalog.
# Español: Mapea carpetas de código a los propietarios canónicos del catálogo de demos.
# 中文：将源码目录映射到 Demo 目录使用的规范模块归属。
MODULE_DEMO_ALIASES = {
    "ActionsheetAndAlert": ("PToolsUIFoundation",),
    "Base": ("PToolsUIFoundation",),
    "Category": ("PToolsUIFoundation",),
    "CollectionView": ("PToolsUIFoundation",),
    "ImageEditor": ("PooToolsImageEditor",),
    "MediaViewer": ("PooToolsMediaViewer",),
    "MessageKit": ("PooToolsMessageKit",),
    "Overlay": ("PToolsOverlay",),
    "Popover": ("PToolsOverlay",),
    "PhotoPicker": ("PooToolsPhotoPicker",),
    "Picker": ("PooToolsPhotoPicker",),
    "SegmentControl": ("PooToolsSegmented", "PToolsUIFoundation"),
    "Segmented": ("PooToolsSegmented",),
    "SplitView": ("PooToolsSplitView",),
    "VideoEditor": ("PooToolsVideoEditor",),
    "Debug": ("PooToolsDEBUG",),
    "LocalConsole": ("PooToolsDEBUG",),
    "Guide": ("PooToolsDEBUG",),
}

# English: Preserve line numbers while removing comments from static matching.
# Español: Conserva los números de línea mientras elimina comentarios del análisis estático.
# 中文：静态扫描去除注释时保留行号，方便报告定位。
def without_comments(text: str) -> str:
    def blank_block(match: re.Match[str]) -> str:
        return "".join("\n" if char == "\n" else " " for char in match.group(0))

    text = re.sub(r"/\*.*?\*/", blank_block, text, flags=re.DOTALL)
    return re.sub(r"//[^\n]*", "", text)

GLOBAL_PATTERNS = {
    "UIScreen.main": re.compile(r"UIScreen\.main(?:Screen)?"),
    "kSCREEN": re.compile(r"\bkSCREEN(?:_|\b)"),
    "statusBarHeight": re.compile(r"\bstatusBarHeight\b"),
    "UIDevice.current.orientation": re.compile(r"UIDevice\.current\.orientation"),
    "isFaceIDCapable": re.compile(r"\bisFaceIDCapable\b"),
    "keyWindow": re.compile(r"\bkeyWindow\b"),
    "screen.bounds": re.compile(r"\bscreen\.bounds\b|\bwindow\.screen\.bounds\b"),
    "kNavBarHeight_Total": re.compile(r"\bkNavBarHeight_Total\b"),
    "kTabbarHeight_Total": re.compile(r"\bkTabbar(?:SaveArea)?Height(?:_Total)?\b"),
    "safe-area-global": re.compile(r"\bk(?:Left|Right)SafeAreaWidth\b"),
    "AppWindows": re.compile(r"\bAppWindows\b"),
    "UIScreen.size": re.compile(r"\bUIScreen\.size\b"),
    "trait/device-idiom": re.compile(r"\b(?:UIDevice\.current\.userInterfaceIdiom|\.userInterfaceIdiom)\b"),
    "convert-to-nil": re.compile(r"\.convert\([^\n]*\bto:\s*nil\b"),
    "reloadData-layout": re.compile(r"\breloadData\s*\("),
    "magic-fixed-dimension": re.compile(
        r"(?:CGRect\(|CGSize\(|width\s*[:=]|height\s*[:=]).*\b(?:[1-9]\d{1,3}|0\.\d+)\b"
    ),
}


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_manifest(repo: Path, swift_files: list[Path]) -> tuple[list[dict[str, str]], str]:
    candidates = [repo / name for name in ("VERSION", "Package.swift", "PooTools.podspec", "PooTools/PTDemoCatalog.swift")]
    candidates.extend(swift_files)
    entries = []
    for path in sorted({path for path in candidates if path.is_file()}):
        relative = path.relative_to(repo).as_posix()
        entries.append({"path": relative, "sha256": sha256_file(path)})
    encoded = json.dumps(entries, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    return entries, hashlib.sha256(encoded).hexdigest()


def tracked_swift_files(repo: Path) -> list[Path]:
    try:
        result = subprocess.run(
            ["git", "-C", str(repo), "ls-files", "--", *[f"{root}/**/*.swift" for root in ROOTS]],
            check=True,
            text=True,
            capture_output=True,
        )
        paths = [repo / line for line in result.stdout.splitlines() if line.endswith(".swift")]
    except (OSError, subprocess.CalledProcessError):
        paths = [path for root in ROOTS for path in (repo / root).rglob("*.swift")]
    return sorted(set(path for path in paths if path.is_file()))


def module_for(repo: Path, path: Path) -> str:
    relative = path.relative_to(repo).as_posix()
    parts = relative.split("/")
    if parts[0] == "PooToolsSource" and len(parts) > 1:
        return parts[1]
    if parts[0] == "Sources" and len(parts) > 2:
        return f"Sources/{parts[1]}"
    if parts[0] == "Tests" and len(parts) > 1:
        return f"Tests/{parts[1]}"
    return parts[0]


def ui_type(text: str, path: Path) -> str:
    name = path.stem.lower()
    if "viewcontroller" in name or re.search(r"class\s+\w+\s*:\s*\w*ViewController", text):
        return "view-controller"
    if "collection" in name or "table" in name:
        return "list"
    if "bar" in name or "navigation" in name or "tab" in name:
        return "bar"
    if "present" in name or "alert" in name or "sheet" in name or "popover" in name:
        return "presentation"
    if EXTENSION_UI.search(text):
        return "ui-extension"
    if "UIView" in text or "UIControl" in text:
        return "view"
    return "ui-helper"


def ownership(path: Path, module: str) -> str:
    if path.parts and path.parts[0] == "Tests":
        return "test"
    if path.parts and path.parts[0] in {"PooTools", "Example"}:
        return "example"
    return module


def extract_hits(text: str, path: Path) -> list[dict[str, object]]:
    hits: list[dict[str, object]] = []
    for number, line in enumerate(text.splitlines(), start=1):
        for kind, pattern in GLOBAL_PATTERNS.items():
            if pattern.search(line):
                hits.append({"kind": kind, "path": path.as_posix(), "line": number, "text": line.strip()})
    return hits


def layout_mode(text: str, hits: list[dict[str, object]]) -> str:
    if any(hit["kind"] in {"UIScreen.main", "kSCREEN", "statusBarHeight", "keyWindow", "screen.bounds"} for hit in hits):
        return "global-geometry-risk"
    if re.search(r"PTAdaptive|safeArea|reservedRegions|layoutGuide|frameLayoutGuide|keyboardLayoutGuide", text):
        return "container-local"
    if re.search(r"\bbounds\b|\bframe\b|layoutSubviews|traitCollection", text):
        return "local-or-unclassified"
    return "not-layout"


def demo_ids(repo: Path) -> dict[str, list[str]]:
    catalog = repo / "PooTools" / "PTDemoCatalog.swift"
    if not catalog.is_file():
        return {}
    result: dict[str, list[str]] = defaultdict(list)
    pattern = re.compile(r'make\("([^"]+)",\s*"([^"]+)"')
    for demo_id, module in pattern.findall(catalog.read_text(encoding="utf-8")):
        result[module].append(demo_id)
    return dict(result)


def test_ids(repo: Path) -> dict[str, list[str]]:
    result: dict[str, list[str]] = defaultdict(list)
    for path in (repo / "Tests").rglob("*.swift"):
        text = path.read_text(encoding="utf-8", errors="replace")
        for name in re.findall(r"\bfunc\s+(test\w+)\s*\(", text):
            result[path.parent.name].append(name)
    return dict(result)


def demos_for(module: str, demos: dict[str, list[str]]) -> list[str]:
    owners = (module,) + MODULE_DEMO_ALIASES.get(module, ())
    values: list[str] = []
    for owner in owners:
        for demo_id in demos.get(owner, []):
            if demo_id not in values:
                values.append(demo_id)
    return values


def swift_invocations(source: str, marker: str) -> list[str]:
    """Return balanced Swift calls without pretending to parse Swift."""
    calls: list[str] = []
    start = 0
    while True:
        marker_start = source.find(marker, start)
        if marker_start < 0:
            break
        open_index = marker_start + len(marker) - 1
        depth = 0
        in_string = False
        escaped = False
        end_index = None
        for index in range(open_index, len(source)):
            character = source[index]
            if in_string:
                if escaped:
                    escaped = False
                elif character == "\\":
                    escaped = True
                elif character == '"':
                    in_string = False
                continue
            if character == '"':
                in_string = True
            elif character == "(":
                depth += 1
            elif character == ")":
                depth -= 1
                if depth == 0:
                    end_index = index + 1
                    break
        if end_index is None:
            break
        calls.append(source[marker_start:end_index])
        start = end_index
    return calls


@lru_cache(maxsize=None)
def package_target_specs(repo: Path) -> list[dict[str, object]]:
    package_file = repo / "Package.swift"
    if not package_file.is_file():
        return []
    specs: list[dict[str, object]] = []
    for call in swift_invocations(package_file.read_text(encoding="utf-8", errors="replace"), ".target("):
        name_match = re.search(r"\bname:\s*\"([^\"]+)\"", call)
        if name_match is None:
            continue
        path_match = re.search(r"\bpath:\s*\"([^\"]+)\"", call)
        sources_match = re.search(r"\bsources:\s*\[(.*?)\]", call, flags=re.DOTALL)
        specs.append({
            "name": name_match.group(1),
            "path": path_match.group(1) if path_match else "",
            "sources": re.findall(r'"([^"]+)"', sources_match.group(1)) if sources_match else [],
        })
    return specs


def package_target_for(repo: Path, relative: str) -> str:
    candidates: list[tuple[int, str]] = []
    for spec in package_target_specs(repo):
        name = str(spec["name"])
        root = str(spec["path"])
        sources = [str(source) for source in spec["sources"]]
        if not root:
            root = f"Sources/{name}"
        prefixes = [root.rstrip("/")]
        prefixes.extend(f"{root.rstrip('/')}/{source.strip('/')}" for source in sources)
        for prefix in prefixes:
            if relative == prefix or relative.startswith(prefix + "/"):
                candidates.append((len(prefix), name))
    if not candidates:
        return "target-review-needed"
    best_length = max(length for length, _ in candidates)
    best_targets = sorted({name for length, name in candidates if length == best_length})
    # English: Ambiguous source ownership must remain visible instead of being silently assigned to one target.
    # Español: La propiedad ambigua debe permanecer visible en vez de asignarse silenciosamente a un target.
    # 中文：源码归属有歧义时必须显式保留，不能静默归到某一个 target。
    if len(best_targets) != 1:
        return "target-review-needed"
    return best_targets[0]


@lru_cache(maxsize=None)
def podspec_subspec_specs(repo: Path) -> list[dict[str, object]]:
    podspec = repo / "PooTools.podspec"
    if not podspec.is_file():
        return []
    source = podspec.read_text(encoding="utf-8", errors="replace")
    matches = list(re.finditer(r"^\s*s\.subspec\s+['\"]([^'\"]+)['\"]\s+do\s+\|subspec\|", source, flags=re.MULTILINE))
    specs: list[dict[str, object]] = []
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(source)
        body = source[match.end():end]
        patterns = re.findall(r"\bsource_files\s*=\s*([^\n]+)", body)
        source_patterns: list[str] = []
        for line in patterns:
            source_patterns.extend(re.findall(r"['\"]([^'\"]+)['\"]", line))
        specs.append({"name": match.group(1), "patterns": source_patterns})
    return specs


def source_pattern_matches(relative: str, pattern: str) -> bool:
    # English: CocoaPods brace globs are reduced only for reporting, never for source selection.
    # Español: Los patrones con llaves de CocoaPods se simplifican solo para informar, nunca para seleccionar fuentes.
    # 中文：CocoaPods 花括号 glob 只用于报告匹配，不参与源码选择。
    expanded = re.sub(r"\{[^}]+\}", "*", pattern)
    return fnmatch.fnmatch(relative, expanded) or fnmatch.fnmatch(relative, expanded.replace("/**/", "/"))


def podspec_subspec_for(repo: Path, relative: str) -> str:
    matches: list[tuple[int, str]] = []
    for spec in podspec_subspec_specs(repo):
        for pattern in spec["patterns"]:
            if source_pattern_matches(relative, str(pattern)):
                matches.append((len(str(pattern)), str(spec["name"])))
    return max(matches, key=lambda value: value[0])[1] if matches else "subspec-review-needed"


def consumer_fixture_for(repo: Path, target: str) -> str:
    matrix = repo / "Tests/SPMConsumerFixtures/ProductImportMatrix.json"
    if not matrix.is_file():
        return "consumer-review-needed"
    try:
        products = json.loads(matrix.read_text(encoding="utf-8")).get("products", [])
    except (OSError, json.JSONDecodeError):
        return "consumer-review-needed"
    for product in products:
        if target == product.get("product") or target in product.get("targets", []) or target in product.get("modules", []):
            fixture = product.get("targetName")
            if fixture:
                return str(fixture)
    return "consumer-review-needed"


def source_context(repo: Path, relative: str) -> dict[str, str]:
    target = package_target_for(repo, relative)
    return {
        "target": target,
        "subspec": podspec_subspec_for(repo, relative),
        "consumer_fixture": consumer_fixture_for(repo, target),
    }


def load_review_registry(repo: Path) -> dict[tuple[str, str, int], dict[str, object]]:
    # English: The registry is an exact, line-scoped review record; it cannot waive a new line automatically.
    # Español: El registro es una revisión exacta por línea; no puede eximir automáticamente una línea nueva.
    # 中文：登记表是精确到行的审核记录，不能自动豁免新增代码行。
    path = repo / REVIEW_REGISTRY_PATH
    if not path.is_file():
        return {}
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    try:
        current_revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip()
    except (OSError, subprocess.CalledProcessError):
        return {}
    if payload.get("source_scope") != current_revision or payload.get("rule_version") != AUDIT_RULE_VERSION:
        return {}
    expected_manifest = payload.get("source_manifest_hash")
    if expected_manifest:
        _, current_manifest = source_manifest(repo, tracked_swift_files(repo))
        if expected_manifest != current_manifest:
            return {}
    entries: dict[tuple[str, str, int], dict[str, object]] = {}
    default_reviewer = str(payload.get("reviewer", "PTools Duo audit"))
    for raw_entry in payload.get("entries", []):
        compact_entries: list[dict[str, object]] = []
        if isinstance(raw_entry, list) and len(raw_entry) == 4 and isinstance(raw_entry[1], list):
            for kind in raw_entry[1]:
                compact_entries.append({
                    "path": raw_entry[0],
                    "kind": kind,
                    "lines": ["*"],
                    "decision": raw_entry[2],
                    "owner": raw_entry[3],
                    "reviewer": default_reviewer,
                    "scope": "{path}:{line}",
                    "test_identifiers": [],
                })
        elif isinstance(raw_entry, list) and len(raw_entry) >= 5:
            compact_entries.append({
                "path": raw_entry[0],
                "kind": raw_entry[1],
                "lines": raw_entry[2],
                "decision": raw_entry[3],
                "owner": raw_entry[4],
                "reviewer": default_reviewer,
                "scope": "{path}:{line}",
                "test_identifiers": [],
            })
        elif isinstance(raw_entry, dict):
            compact_entries.append(raw_entry)
        else:
            continue
        for entry in compact_entries:
            relative = entry.get("path")
            kind = entry.get("kind")
            if not isinstance(relative, str) or not isinstance(kind, str):
                continue
            lines = entry.get("lines", [])
            if not isinstance(lines, list):
                continue
            for line in lines:
                if line == "*":
                    entries[(relative, kind, 0)] = dict(entry)
                elif isinstance(line, int) and line > 0:
                    entries[(relative, kind, line)] = dict(entry)
    return entries


def review_reason(kind: str) -> str:
    # English: Keep repeated registry rationale centralized while the generated report remains explicit per finding.
    # Español: Centraliza la justificación repetida y mantiene el informe generado explícito por hallazgo.
    # 中文：集中维护重复的审核理由，同时让生成报告逐条保留完整说明。
    reasons = {
        "UIScreen.main": "Display or pixel metadata only; no view placement is derived from this value. / Solo metadatos de pantalla o píxel; no posiciona vistas. / 仅用于屏幕或像素元数据，不用于视图定位。",
        "AppWindows": "Legacy scene fallback is retained for a global service; new UI paths must use PTSceneContext or an owner view. / Se conserva como fallback de escena para un servicio global; las nuevas rutas UI deben usar PTSceneContext o una vista propietaria. / 全局服务保留场景兜底；新 UI 路径必须使用 PTSceneContext 或宿主视图。",
        "keyWindow": "Window selection belongs to diagnostics or an explicit compatibility adapter, not ordinary content layout. / La selección de ventana pertenece al diagnóstico o a un adaptador de compatibilidad explícito, no al layout normal. / 窗口选择仅用于诊断或明确兼容适配，不用于普通内容布局。",
        "screen.bounds": "The screen bounds are diagnostic/display metadata for the inspected window, not an app layout coordinate space. / Los límites son metadatos de diagnóstico/pantalla de la ventana inspeccionada, no un espacio de layout. / 屏幕边界仅为被检查窗口的诊断或显示元数据，不是应用布局坐标系。",
        "convert-to-nil": "Conversion to the screen coordinate space is intentional for this image utility; callers do not use it as container layout. / La conversión al espacio de pantalla es intencional para esta utilidad de imagen; no se usa para layout de contenedor. / 此图片工具明确转换到屏幕坐标系，不用于容器布局。",
        "statusBarHeight": "Legacy compatibility scalar is consumed by a dedicated custom surface; the active scene/local safe area remains the source for new layout. / Escalar heredado para una superficie personalizada; el safe area local de la escena activa es la fuente para el layout nuevo. / 这是专用自定义表面的兼容标量；新布局以当前场景的局部 safe area 为准。",
        "kNavBarHeight_Total": "Legacy custom navigation surface metric; system/navigation-container paths resolve local safe-area geometry. / Métrica heredada de una superficie de navegación personalizada; las rutas del sistema/contenedor resuelven geometría local. / 自定义导航表面的历史尺寸；系统和容器路径使用局部 safe area 几何。",
        "kTabbarHeight_Total": "Legacy custom tab-bar surface metric; adaptive tab-bar paths resolve local safe-area geometry. / Métrica heredada de una superficie tab-bar personalizada; las rutas adaptativas resuelven geometría local. / 自定义 TabBar 表面的历史尺寸；自适应路径使用局部 safe area 几何。",
    }
    return reasons.get(kind, "Reviewed compatibility geometry; new code must use local container geometry. / Geometría de compatibilidad revisada; el código nuevo debe usar geometría local. / 已审核为兼容性几何；新代码必须使用局部容器几何。")


def review_registry_hash(repo: Path) -> str:
    path = repo / REVIEW_REGISTRY_PATH
    return sha256_file(path) if path.is_file() else ""


def symbol_for_hit(repo: Path, relative: str, line: int) -> str:
    path = repo / relative
    if not path.is_file():
        return ""
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    start = min(max(line - 1, 0), len(lines))
    declaration = re.compile(r"^\s*(?:(?:open|public|internal|private|fileprivate|final|static|class|override|nonisolated)\s+)*(?:func|var|let|init|subscript|class|struct|enum|extension)\b")
    for index in range(start - 1, max(-1, start - 121), -1):
        candidate = lines[index].strip()
        if declaration.search(candidate):
            return candidate
    return ""


def tests_for(module: str, tests: dict[str, list[str]]) -> list[str]:
    values = list(tests.get(module, []))
    available_tests = {test_id for test_ids in tests.values() for test_id in test_ids}
    for test_id in MODULE_TEST_CASES.get(module, ()):
        if test_id in available_tests and test_id not in values:
            values.append(test_id)
    return values


def hit_risk(hit: dict[str, object]) -> str:
    # English: Only layout-like global geometry can block release; pixel and reload candidates remain review data.
    # Español: Solo la geometría global usada para layout puede bloquear la versión; píxeles y reload siguen siendo datos de revisión.
    # 中文：只有用于布局的全局几何命中可以阻断发布；像素和 reload 命中只作为审查数据。
    kind = str(hit["kind"])
    if kind not in HIGH_RISK_KINDS:
        return "low"
    return "high" if bool(hit.get("layout_use", is_layout_like(hit))) else "medium"


def baseline_hit_ids(repo: Path) -> set[str]:
    try:
        raw = subprocess.check_output(
            ["git", "show", "HEAD:report/current/duo_global_geometry_hits.json"],
            cwd=repo,
            text=True,
            stderr=subprocess.DEVNULL,
        )
        payload = json.loads(raw)
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError):
        return set()
    return {str(hit["id"]) for hit in payload.get("hits", []) if hit.get("id")}


def release_blockers(repo: Path, hits: list[dict[str, object]], policy: str) -> list[dict[str, object]]:
    # English: Make strictness explicit so historical unresolved inventory does not become a false pass or a surprise block.
    # Español: Hace explícita la política para que el inventario histórico no produzca un falso PASS ni un bloqueo inesperado.
    # 中文：显式表达严格策略，避免历史未分类清单误报通过或突然阻断。
    unresolved = [
        hit for hit in hits
        if hit.get("hit_risk") == "high" and hit.get("decision", "needs-review") in {"needs-review", "not-reviewed"}
    ]
    if policy == "strict":
        return unresolved
    if policy == "new-high-risk":
        baseline = baseline_hit_ids(repo)
        return [hit for hit in unresolved if str(hit.get("id")) not in baseline]
    if policy == "focus-only":
        focus_paths = {str(config["path"]) for config in FOCUS_FINDINGS.values()}
        return [hit for hit in unresolved if str(hit.get("path")) in focus_paths]
    raise ValueError(f"unsupported DUO_RELEASE_POLICY: {policy}")


def is_layout_like(hit: dict[str, object]) -> bool:
    if hit["kind"] not in {"magic-fixed-dimension", "UIScreen.main"}:
        return True
    return bool(re.search(r"layout|constraint|frame|bounds|inset|center|width|height|top|bottom", str(hit["text"]), re.IGNORECASE))


def allowlist_entry(relative: str, kind: str) -> tuple[str, str] | None:
    entry = LEGACY_GEOMETRY_ALLOWLIST.get(relative)
    if entry is None:
        return None
    allowed_kinds, reason, reviewer = entry
    if allowed_kinds is not None and kind not in allowed_kinds:
        return None
    return reason, reviewer


def evaluate_focus_findings(repo: Path, hits: list[dict[str, object]]) -> dict[str, dict[str, object]]:
    # English: Evaluate source markers and forbidden uses rather than trusting a static status string.
    # Español: Evalúa marcadores y usos prohibidos en el código, no una cadena de estado estática.
    # 中文：根据源码标记和禁止用法计算状态，不能信任静态字符串。
    results: dict[str, dict[str, object]] = {}
    hits_by_path: dict[str, list[dict[str, object]]] = defaultdict(list)
    for hit in hits:
        hits_by_path[str(hit["path"])].append(hit)

    for finding_id, config in FOCUS_FINDINGS.items():
        path = str(config["path"])
        source_path = repo / path
        source = source_path.read_text(encoding="utf-8", errors="replace") if source_path.is_file() else ""
        missing = [token for token in config["required"] if token not in source]
        forbidden = [token for token in config["forbidden"] if token in source]
        external_risks: list[str] = []
        if finding_id == "DUO-A01":
            for hit in hits:
                if hit["kind"] != "kSCREEN" or str(hit["path"]).startswith("Tests/"):
                    continue
                if allowlist_entry(str(hit["path"]), str(hit["kind"])) is None and is_layout_like(hit):
                    external_risks.append(f"{hit['path']}:{hit['line']}")
        if missing or forbidden or external_risks:
            status = "needs-review"
        else:
            status = str(config["static_policy"])
        results[finding_id] = {
            "path": path,
            "decision": status,
            "reason": str(config["reason"]),
            "missing": missing,
            "forbidden": forbidden,
            "external_risks": external_risks,
        }
    return results


def classify_hit(
    relative: str,
    kind: str,
    focus_status: dict[str, dict[str, object]],
    line: int | None = None,
    review_registry: dict[tuple[str, str, int], dict[str, object]] | None = None,
    allow_wildcard: bool = True,
) -> tuple[str, str, str]:
    focus_id = next((finding_id for finding_id, config in FOCUS_FINDINGS.items() if config["path"] == relative), None)
    if focus_id is not None:
        status = str(focus_status[focus_id]["decision"])
        if status != "needs-review":
            return status, "pass_static", str(focus_status[focus_id]["reason"])
        return "needs-review", "not_run", "focused source checks are incomplete"
    if line is not None and review_registry is not None:
        reviewed = review_registry.get((relative, kind, line))
        if reviewed is None and allow_wildcard:
            reviewed = review_registry.get((relative, kind, 0))
        if reviewed is not None:
            decision = str(reviewed.get("decision", "needs-review"))
            if decision in {"reviewed-layout", "reviewed-compatibility", "false-positive"}:
                return decision, "not_run", str(reviewed.get("reason", review_reason(kind)))
    allowlisted = allowlist_entry(relative, kind)
    if allowlisted is not None:
        reason, _ = allowlisted
        return "legacy-allowlisted", "waived", reason
    return "needs-review", "not_run", "candidate requires semantic review"


def annotate_hits(
    repo: Path,
    hits: list[dict[str, object]],
    tests: dict[str, list[str]],
    focus_status: dict[str, dict[str, object]],
    records: list[dict[str, object]],
    review_registry: dict[tuple[str, str, int], dict[str, object]],
) -> None:
    records_by_path = {str(record["path"]): record for record in records}
    for hit in hits:
        relative = str(hit["path"])
        evidence = f"{relative}:{hit['line']}"
        hit["id"] = hashlib.sha1(f"{evidence}|{hit['kind']}|{hit['text']}".encode("utf-8")).hexdigest()[:12]
        hit["owner"] = module_for(repo, repo / relative)
        context = source_context(repo, relative)
        hit["target"] = context["target"]
        hit["subspec"] = context["subspec"]
        hit["consumer_fixture"] = context["consumer_fixture"]
        hit["file_risk"] = str(records_by_path.get(relative, {}).get("risk", "unknown"))
        hit["evidence"] = evidence
        hit["layout_use"] = is_layout_like(hit)
        hit["hit_risk"] = hit_risk(hit)
        line = int(hit["line"])
        registry_entry = review_registry.get((relative, str(hit["kind"]), line))
        if registry_entry is None and hit_risk(hit) == "high":
            registry_entry = review_registry.get((relative, str(hit["kind"]), 0))
        decision, run_status, reason = classify_hit(
            relative,
            str(hit["kind"]),
            focus_status,
            line,
            review_registry,
            allow_wildcard=hit_risk(hit) == "high",
        )
        hit["decision"] = decision
        explicit_tests = registry_entry.get("test_identifiers", []) if registry_entry else []
        if not isinstance(explicit_tests, list):
            explicit_tests = []
        hit["test_id"] = ";".join(str(test_id) for test_id in explicit_tests)
        hit["test_case"] = hit["test_id"]
        hit["test_owner"] = str(registry_entry.get("test_owner", context["target"])) if registry_entry else ""
        hit["run_status"] = run_status
        hit["artifact"] = "report/current/duo_global_geometry_hits.json"
        if registry_entry:
            scope = str(registry_entry.get("scope", "{path}:{line}"))
            hit["review_scope"] = scope.replace("{path}", relative).replace("{line}", str(line))
        else:
            hit["review_scope"] = evidence
        hit["symbol"] = str(registry_entry.get("symbol", "")) if registry_entry else symbol_for_hit(repo, relative, line)
        hit["reviewer"] = str(registry_entry.get("reviewer", "PTools Duo audit")) if registry_entry else next((entry[2] for path, entry in LEGACY_GEOMETRY_ALLOWLIST.items() if path == relative and (entry[0] is None or str(hit["kind"]) in entry[0])), "PTools Duo audit")
        hit["owner"] = str(registry_entry.get("owner", hit["owner"])) if registry_entry else hit["owner"]
        hit["reason"] = str(registry_entry.get("reason", review_reason(str(hit["kind"])))) if registry_entry else reason
        hit["static_status"] = "pass_static" if decision in {"fixed", "display-only-allowed", "legacy-allowlisted", "reviewed-layout", "reviewed-compatibility", "false-positive"} else "needs_review"
        hit["build_status"] = "pending"
        hit["runtime_status"] = "pending"
        hit["visual_status"] = "pending"
        hit["device_status"] = "pending_device"
        hit["actual_status"] = hit["static_status"]


def write_reports(repo: Path, records: list[dict[str, object]], hits: list[dict[str, object]], demos: dict[str, list[str]], tests: dict[str, list[str]], focus_status: dict[str, dict[str, object]]) -> None:
    output = repo / "report" / "current"
    output.mkdir(parents=True, exist_ok=True)
    # English: Keep generated reports traceable to the source revision and audit run.
    # Español: Mantén los informes generados vinculados a la revisión fuente y a la ejecución de la auditoría.
    # 中文：让生成报告能够追溯到源码 revision 和本次审计执行时间。
    source_revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip()
    generated_at = datetime.now(timezone.utc).isoformat()
    swift_files = tracked_swift_files(repo)
    manifest_entries, manifest_hash = source_manifest(repo, swift_files)
    review_registry = load_review_registry(repo)
    annotate_hits(repo, hits, tests, focus_status, records, review_registry)
    status_counts: dict[str, int] = defaultdict(int)
    decision_counts: dict[str, int] = defaultdict(int)
    static_status_counts: dict[str, int] = defaultdict(int)
    for hit in hits:
        status_counts[str(hit["run_status"])] += 1
        decision_counts[str(hit["decision"])] += 1
        static_status_counts[str(hit["static_status"])] += 1
    policy = os.environ.get("DUO_RELEASE_POLICY", "new-high-risk")
    blockers = release_blockers(repo, hits, policy)
    registry_hash = review_registry_hash(repo)

    # English: Keep the inventory diffable on every platform by using LF records.
    # Español: Mantén el inventario comparable en todas las plataformas usando registros LF.
    # 中文：使用 LF 换行，让清单在所有平台上的 diff 保持稳定。
    with (output / "duo_uikit_inventory.csv").open("w", newline="", encoding="utf-8") as handle:
        fields = ["path", "module", "target", "subspec", "consumer_fixture", "public_api", "ui_type", "ownership", "layout_mode", "risk", "coverage", "demo_id", "test_id", "status", "decision", "evidence", "test_owner", "run_status", "reviewer"]
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(records)

    (output / "duo_global_geometry_hits.json").write_text(
        json.dumps(
            {
                "generator": "Scripts/audit_duo_uikit_coverage.py",
                "generated_by": "Scripts/audit_duo_uikit_coverage.py",
                "source_revision": source_revision,
                "generated_at": generated_at,
                "rule_version": AUDIT_RULE_VERSION,
                "source_manifest_hash": manifest_hash,
                "source_manifest": manifest_entries,
                "report_kind": "ci-generated",
                "snapshot_of": source_revision,
                "tool_version": AUDIT_RULE_VERSION,
                "review_registry": REVIEW_REGISTRY_PATH,
                "review_registry_hash": registry_hash,
                "release_policy": policy,
                "release_blocker_count": len(blockers),
                "status_counts": dict(sorted(status_counts.items())),
                "decision_counts": dict(sorted(decision_counts.items())),
                "static_status_counts": dict(sorted(static_status_counts.items())),
                "focus_findings": focus_status,
                "hits": hits,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )

    (output / "duo_audit_metadata.json").write_text(
        json.dumps({
            "report_kind": "ci-generated",
            "snapshot_of": source_revision,
            "source_revision": source_revision,
            "generated_at": generated_at,
            "rule_version": AUDIT_RULE_VERSION,
            "tool_version": AUDIT_RULE_VERSION,
            "source_manifest_hash": manifest_hash,
            "review_registry": REVIEW_REGISTRY_PATH,
            "review_registry_hash": registry_hash,
            "release_policy": policy,
            "release_blocker_count": len(blockers),
            "status_counts": dict(sorted(status_counts.items())),
            "decision_counts": dict(sorted(decision_counts.items())),
            "static_status_counts": dict(sorted(static_status_counts.items())),
            "focus_findings": focus_status,
        }, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    evidence_fields = (
        "finding_id", "source_path", "line", "symbol", "kind", "target", "subspec",
        "consumer_fixture", "test_identifier", "test_owner", "decision", "run_status", "static_status",
        "build_status", "runtime_status", "visual_status", "device_status", "actual_status",
        "artifact", "reviewer", "review_scope", "reason",
    )
    evidence_rows: list[dict[str, object]] = []
    for hit in hits:
        evidence_rows.append({
            "finding_id": hit["id"],
            "source_path": hit["path"],
            "line": hit["line"],
            "symbol": hit["symbol"],
            "kind": hit["kind"],
            "target": hit["target"],
            "subspec": hit["subspec"],
            "consumer_fixture": hit["consumer_fixture"],
            "test_identifier": hit["test_id"],
            "test_owner": hit["test_owner"],
            "decision": hit["decision"],
            "run_status": hit["run_status"],
            "static_status": hit["static_status"],
            "build_status": hit["build_status"],
            "runtime_status": hit["runtime_status"],
            "visual_status": hit["visual_status"],
            "device_status": hit["device_status"],
            "actual_status": hit["actual_status"],
            "artifact": hit["artifact"],
            "reviewer": hit["reviewer"],
            "review_scope": hit["review_scope"],
            "reason": hit["reason"],
        })
    (output / "duo_finding_evidence.json").write_text(
        json.dumps({
            "report_kind": "ci-generated-evidence-map",
            "source_revision": source_revision,
            "generated_at": generated_at,
            "rule_version": AUDIT_RULE_VERSION,
            "source_manifest_hash": manifest_hash,
            "review_registry": REVIEW_REGISTRY_PATH,
            "entries": evidence_rows,
        }, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    module_rows: dict[str, dict[str, object]] = {}
    for record in records:
        if record["ownership"] in {"test", "example"}:
            continue
        module = str(record["module"])
        row = module_rows.setdefault(module, {"files": 0, "ui_files": 0, "risks": 0, "demos": demos_for(module, demos), "tests": tests_for(module, tests)})
        row["files"] += 1
        if record["ui_type"] != "not-ui":
            row["ui_files"] += 1
        if record["risk"] == "high":
            row["risks"] += 1
    missing = [module for module, row in module_rows.items() if row["ui_files"] and not row["demos"] and not row["tests"]]
    lines = [
        "<!--",
        "AUTO-GENERATED FILE.",
        "",
        "Generator: Scripts/audit_duo_uikit_coverage.py",
        f"Source revision: {source_revision}",
        f"Generated at: {generated_at}",
        f"Audit rule version: {AUDIT_RULE_VERSION}",
        f"Source manifest hash: {manifest_hash}",
        "-->",
        "",
        "# iPhone Duo UIKit 覆盖报告 / Cobertura UIKit / UIKit Coverage",
        "",
        "生成：`Scripts/audit_duo_uikit_coverage.py`。关键字命中只代表候选风险，必须结合调用语义确认。",
        "Generado por `Scripts/audit_duo_uikit_coverage.py`; los aciertos son candidatos y requieren revisión semántica.",
        "Generated by `Scripts/audit_duo_uikit_coverage.py`; matches are candidates and require semantic review.",
        "",
        f"- UIKit 文件 / archivos UIKit / UIKit files: {sum(int(row['ui_files']) for row in module_rows.values())}",
        f"- 全局几何候选 / candidatos globales / global candidates: {len(hits)}",
        f"- 未映射模块 / módulos sin cobertura / uncovered modules: {len(missing)}",
        f"- 严格未分类高风险 / alto riesgo sin clasificar / strict unresolved high risk: {len(release_blockers(repo, hits, 'strict'))}",
        "- `test_id` 只记录精确登记的具名测试；没有直接证据时保持为空。",
        "- `test_id` solo contiene pruebas nombradas registradas exactamente; sin evidencia directa permanece vacío.",
        "- `test_id` contains only explicitly registered named tests; it remains empty without direct evidence.",
        "",
        "## 模块状态 / Estado / Status",
        "",
        "| 模块 | UIKit 文件 | 高风险 | Demo | 测试 | 状态 |",
        "| --- | ---: | ---: | --- | --- | --- |",
    ]
    for module in sorted(module_rows):
        row = module_rows[module]
        demos_text = ", ".join(row["demos"]) or "—"
        tests_text = ", ".join(row["tests"]) or "—"
        status = "needs-review" if module in missing else "mapped-by-module"
        lines.append(f"| `{module}` | {row['ui_files']} | {row['risks']} | {demos_text} | {tests_text} | {status} |")
    lines += [
        "",
        "## 覆盖规则 / Reglas / Rules",
        "",
        "`needs-review` 不等同于已确认 Bug；为资源、像素比例、调试诊断、真实硬件信息等用途建立 allowlist 后再转为 `mapped`。",
        "`needs-review` no significa bug confirmado; clasifica recursos, escala de píxeles, diagnóstico y hardware antes de marcar `mapped`.",
        "`mapped-by-module` is module-level evidence only; see decision, evidence, reviewer, and run_status in JSON.",
    ]
    (output / "duo_coverage.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    finding_lines = [
        "<!-- AUTO-GENERATED: Scripts/audit_duo_uikit_coverage.py -->",
        f"Source revision: {source_revision}",
        f"Generated at: {generated_at}",
        f"Audit rule version: {AUDIT_RULE_VERSION}",
        f"Source manifest hash: {manifest_hash}",
        "",
        "# iPhone Duo Findings Closure / Hallazgos / 审计项闭环",
        "",
        "| ID | 文件 | 决定 | 静态状态 | 运行/设备状态 | 说明 |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for finding_id, result in focus_status.items():
        decision = str(result["decision"])
        static_status = "pass_static" if decision in {"fixed", "display-only-allowed"} else "needs-review"
        detail = str(result["reason"])
        if result["missing"]:
            detail += f"; missing: {', '.join(result['missing'])}"
        if result["external_risks"]:
            detail += f"; unclassified: {', '.join(result['external_risks'])}"
        finding_lines.append(f"| `{finding_id}` | `{result['path']}` | `{decision}` | `{static_status}` | `pending_device` | {detail} |")
    (output / "duo_findings_closed.md").write_text("\n".join(finding_lines) + "\n", encoding="utf-8")

    allowlist_lines = [
        "# iPhone Duo geometry allowlist / Lista de excepciones / 几何白名单",
        "",
        f"Source revision: {source_revision}",
        f"Audit rule version: {AUDIT_RULE_VERSION}",
        "",
        "Only the listed path and kinds are waived. Any new path remains `needs-review`.",
        "Solo se eximen la ruta y los tipos listados. Una ruta nueva queda en `needs-review`.",
        "仅豁免下列路径和类型；新增路径始终进入 `needs-review`。",
        "",
        "| Path | Kinds | Reviewer | Reason |",
        "| --- | --- | --- | --- |",
    ]
    for path, (kinds, reason, reviewer) in sorted(LEGACY_GEOMETRY_ALLOWLIST.items()):
        allowlist_lines.append(f"| `{path}` | `{', '.join(sorted(kinds)) if kinds else 'all'}` | {reviewer} | {reason} |")
    allowlist_lines += [
        "",
        "## Exact reviewed lines / Líneas revisadas / 精确审核行",
        "",
        "These entries are pinned to the current source revision; generated evidence retains the exact line. A moved or new hit requires a new registry review.",
        "Estas entradas están fijadas a la revisión fuente actual; la evidencia generada conserva la línea exacta. Un acierto nuevo o movido requiere revisión nueva.",
        "这些记录绑定当前源码 revision；生成的证据保留精确行号。移动或新增的命中必须重新审核。",
        "",
        "| Path | Lines | Kind | Decision | Owner | Reviewer | Scope | Reason |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    reviewed_rows: dict[tuple[str, str], dict[str, object]] = {}
    for hit in hits:
        if str(hit.get("decision")) not in {"reviewed-layout", "reviewed-compatibility", "false-positive"}:
            continue
        key = (str(hit["path"]), str(hit["kind"]))
        row = reviewed_rows.setdefault(key, {
            "path": hit["path"],
            "kind": hit["kind"],
            "lines": [],
            "decision": hit["decision"],
            "owner": hit["owner"],
            "reviewer": hit["reviewer"],
            "reason": hit["reason"],
        })
        row["lines"].append(int(hit["line"]))
    for entry in sorted(reviewed_rows.values(), key=lambda item: (str(item.get("path")), str(item.get("kind")))):
        lines_text = ",".join(str(line) for line in sorted(set(entry["lines"])))
        scope = "{path}:{line}"
        allowlist_lines.append(
            f"| `{entry.get('path', '')}` | `{lines_text}` | `{entry.get('kind', '')}` | `{entry.get('decision', '')}` | "
            f"{entry.get('owner', '')} | {entry.get('reviewer', '')} | `{scope}` | {entry.get('reason', '')} |"
        )
    (output / "duo_geometry_allowlist.md").write_text("\n".join(allowlist_lines) + "\n", encoding="utf-8")

    template_lines = [
        "<!-- AUTO-GENERATED TEMPLATE: Scripts/audit_duo_uikit_coverage.py -->",
        f"Source revision: {source_revision}",
        f"Source manifest hash: {manifest_hash}",
        f"Audit rule version: {AUDIT_RULE_VERSION}",
        "",
        "# iPhone Duo Test Matrix Template / Plantilla / 测试矩阵模板",
        "",
        "This is a generated starting point. Runtime, visual, and device evidence belongs in `duo_test_matrix.md`.",
        "Esta es una plantilla generada; la evidencia pertenece a `duo_test_matrix.md`.",
        "这是生成的初始模板；运行、视觉和设备证据应记录在 `duo_test_matrix.md`。",
        "",
        "| Case | Static evidence | Build | Runtime/visual | Device |",
        "| --- | --- | --- | --- | --- |",
    ]
    for case in ("DUO-T01", "DUO-T02", "DUO-T03", "DUO-T04", "DUO-T05", "DUO-T06", "DUO-T07", "DUO-T08", "DUO-T09", "DUO-T10"):
        template_lines.append(f"| `{case}` | pending | pending | pending | pending_device |")
    (output / "duo_test_matrix_template.md").write_text("\n".join(template_lines) + "\n", encoding="utf-8")

    matrix_lines = [
        "<!-- MANUAL EVIDENCE: scanner preserves this file. -->",
        "<!-- INITIAL TEMPLATE GENERATED BY: Scripts/audit_duo_uikit_coverage.py -->",
        f"Source revision: {source_revision}",
        f"Source manifest hash: {manifest_hash}",
        "",
        "# iPhone Duo Test Matrix / Matriz / 测试矩阵",
        "",
        "| Case | Static evidence | Build | Runtime/visual | Device |",
        "| --- | --- | --- | --- | --- |",
    ]
    for case in ("DUO-T01", "DUO-T02", "DUO-T03", "DUO-T04", "DUO-T05", "DUO-T06", "DUO-T07", "DUO-T08", "DUO-T09", "DUO-T10"):
        matrix_lines.append(f"| `{case}` | pending | pending | pending | pending_device |")
    matrix_path = output / "duo_test_matrix.md"
    if not matrix_path.is_file() or "MANUAL EVIDENCE" not in matrix_path.read_text(encoding="utf-8", errors="replace"):
        matrix_path.write_text("\n".join(matrix_lines) + "\n", encoding="utf-8")


def check_report_freshness(repo: Path, strict: bool = False, committed_snapshot: bool = False) -> int:
    report = repo / "report/current/duo_global_geometry_hits.json"
    if not report.is_file():
        print("STALE: missing report/current/duo_global_geometry_hits.json")
        return 1
    try:
        payload = json.loads(report.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        print(f"STALE: invalid Duo report: {error}")
        return 1

    revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip()
    _, manifest_hash = source_manifest(repo, tracked_swift_files(repo))
    errors = []
    stale = []
    if payload.get("source_revision") != revision:
        stale.append("source_revision does not match HEAD")
    if payload.get("rule_version") != AUDIT_RULE_VERSION:
        stale.append("rule_version is stale")
    if payload.get("source_manifest_hash") != manifest_hash:
        stale.append("source_manifest_hash does not match the current worktree")
    if stale and committed_snapshot:
        print("STALE SNAPSHOT (warning): committed reports describe a different checkout")
        for item in stale:
            print(f"- {item}")
    else:
        errors.extend(stale)
    required_hit_fields = {
        "id", "owner", "target", "subspec", "consumer_fixture", "evidence", "decision",
        "test_id", "test_case", "test_owner", "run_status", "reviewer", "reason", "layout_use",
        "hit_risk", "artifact", "review_scope", "symbol", "static_status", "build_status",
        "runtime_status", "visual_status", "device_status", "actual_status",
    }
    for hit in payload.get("hits", []):
        missing = required_hit_fields.difference(hit)
        if missing:
            errors.append(f"hit {hit.get('path')}:{hit.get('line')} missing {sorted(missing)}")
    evidence_path = repo / "report/current/duo_finding_evidence.json"
    evidence_payload: dict[str, object] = {}
    if not evidence_path.is_file():
        errors.append("missing duo_finding_evidence.json")
    else:
        try:
            evidence_payload = json.loads(evidence_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            errors.append(f"invalid duo_finding_evidence.json: {error}")
    hit_ids = {str(hit.get("id")) for hit in payload.get("hits", [])}
    evidence_entries = evidence_payload.get("entries", []) if isinstance(evidence_payload, dict) else []
    evidence_ids = {str(entry.get("finding_id")) for entry in evidence_entries if isinstance(entry, dict)}
    if hit_ids != evidence_ids:
        errors.append("duo_finding_evidence.json does not map exactly one entry to every finding")
    required_evidence_fields = {
        "finding_id", "source_path", "line", "symbol", "kind", "target", "subspec", "consumer_fixture",
        "test_identifier", "test_owner", "decision", "run_status", "static_status", "build_status", "runtime_status",
        "visual_status", "device_status", "actual_status", "artifact", "reviewer", "review_scope", "reason",
    }
    for entry in evidence_entries:
        if not isinstance(entry, dict):
            errors.append("duo_finding_evidence.json contains a non-object entry")
            continue
        missing = required_evidence_fields.difference(entry)
        if missing:
            errors.append(f"evidence {entry.get('finding_id')} missing {sorted(missing)}")
    if strict:
        policy = str(os.environ.get("DUO_RELEASE_POLICY", payload.get("release_policy", "new-high-risk")))
        try:
            blockers = release_blockers(repo, payload.get("hits", []), policy)
        except ValueError as error:
            errors.append(str(error))
            blockers = []
        if payload.get("release_blocker_count") != len(blockers):
            errors.append("release_blocker_count does not match the current release policy")
        for hit in blockers[:20]:
            errors.append(f"release blocker {hit.get('path')}:{hit.get('line')} {hit.get('kind')} policy={policy}")
        if len(blockers) > 20:
            errors.append(f"release blocker list truncated: {len(blockers)} total")
        focus_status = payload.get("focus_findings", {})
        for finding_id, config in FOCUS_FINDINGS.items():
            decision = focus_status.get(finding_id, {}).get("decision")
            if decision not in {"fixed", "display-only-allowed"}:
                errors.append(f"{finding_id} is not statically closed: {config['path']}")
        for filename in ("duo_findings_closed.md", "duo_test_matrix.md", "duo_test_matrix_template.md", "duo_geometry_allowlist.md", "duo_audit_metadata.json", "duo_finding_evidence.json"):
            if not (repo / "report/current" / filename).is_file():
                errors.append(f"missing {filename}")
    if errors:
        print("STALE/FAIL: Duo report gate")
        for error in errors:
            print(f"- {error}")
        return 1
    print("PASS: Duo report freshness and metadata")
    return 0


def run_self_tests() -> int:
    # English: Keep scanner tests independent from the repository and its generated reports.
    # Español: Mantén las pruebas del escáner independientes del repositorio y sus informes generados.
    # 中文：让扫描器自测独立于仓库源码和已生成报告。
    closed = {finding_id: {"decision": config["static_policy"], "reason": "test", "path": config["path"]} for finding_id, config in FOCUS_FINDINGS.items()}
    assert classify_hit("PooToolsSource/Category/AutoScale+PTEX.swift", "kSCREEN", closed)[0] == "fixed"
    assert classify_hit("PooToolsSource/Category/UICollectionView+PTEX.swift", "kSCREEN", closed)[0] == "legacy-allowlisted"
    assert classify_hit("PooToolsSource/NewUIKitView.swift", "UIScreen.main", closed)[0] == "needs-review"
    incomplete = dict(closed)
    incomplete["DUO-A02"] = {"decision": "needs-review", "reason": "test", "path": FOCUS_FINDINGS["DUO-A02"]["path"]}
    assert classify_hit("PooToolsSource/Category/AutoScale+PTEX.swift", "kSCREEN", incomplete)[0] == "needs-review"
    registry = {
        ("PooToolsSource/NewUIKitView.swift", "UIScreen.main", 7): {
            "decision": "reviewed-layout",
            "reason": "exact review",
        }
    }
    assert classify_hit("PooToolsSource/NewUIKitView.swift", "UIScreen.main", closed, 7, registry)[0] == "reviewed-layout"
    assert classify_hit("PooToolsSource/NewUIKitView.swift", "UIScreen.main", closed, 8, registry)[0] == "needs-review"
    synthetic = {
        "id": "new-high-risk",
        "path": "PooToolsSource/NewUIKitView.swift",
        "line": 1,
        "kind": "UIScreen.main",
        "layout_use": True,
        "hit_risk": "high",
        "run_status": "not_run",
        "decision": "needs-review",
    }
    assert release_blockers(Path("/tmp/duo-audit-self-test"), [synthetic], "strict") == [synthetic]
    assert release_blockers(Path("/tmp/duo-audit-self-test"), [{**synthetic, "hit_risk": "medium"}], "strict") == []
    assert release_blockers(Path("/tmp/duo-audit-self-test"), [{**synthetic, "decision": "reviewed-layout"}], "strict") == []
    assert len(release_blockers(Path("/tmp/duo-audit-self-test"), [{**synthetic, "run_status": "pass_static"}], "strict")) == 1
    assert classify_hit("PooToolsSource/Category/UICollectionView+PTEX.swift", "UIScreen.main", closed)[0] == "needs-review"
    print("PASS: Duo audit scanner self-tests")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("repo", nargs="?", default=".")
    parser.add_argument("--strict", action="store_true", help="Fail when focused findings, report metadata, or the configured release policy are not closed.")
    parser.add_argument("--check", action="store_true", help="Check existing reports without regenerating them.")
    parser.add_argument("--check-committed-snapshot", action="store_true", help="Validate committed report schema and warn when its checkout is stale.")
    parser.add_argument("--self-test", action="store_true", help="Run scanner classification self-tests without touching reports.")
    args = parser.parse_args()
    repo = Path(args.repo).resolve()
    if args.self_test:
        return run_self_tests()
    if args.check or args.check_committed_snapshot:
        return check_report_freshness(repo, strict=args.strict and not args.check_committed_snapshot, committed_snapshot=args.check_committed_snapshot)
    demos = demo_ids(repo)
    tests = test_ids(repo)
    review_registry = load_review_registry(repo)
    records: list[dict[str, object]] = []
    hits: list[dict[str, object]] = []
    for path in tracked_swift_files(repo):
        text = path.read_text(encoding="utf-8", errors="replace")
        scan_text = without_comments(text)
        is_ui = bool(UI_IMPORT.search(scan_text) or UI_SYMBOLS.search(scan_text) or EXTENSION_UI.search(scan_text))
        is_swiftui = bool(SWIFTUI_IMPORT.search(scan_text))
        is_foundation_only = "import Foundation" in scan_text and not is_ui and not is_swiftui
        file_hits = extract_hits(scan_text, path.relative_to(repo))
        hits.extend(file_hits)
        module = module_for(repo, path)
        module_demos = demos_for(module, demos)
        module_tests = tests_for(module, tests)
        context = source_context(repo, path.relative_to(repo).as_posix())
        if is_ui:
            kind = ui_type(text, path)
            risk = "high" if any(hit["kind"] in {"UIScreen.main", "kSCREEN", "keyWindow", "screen.bounds", "kNavBarHeight_Total", "kTabbarHeight_Total", "safe-area-global", "AppWindows", "convert-to-nil"} for hit in file_hits) else "medium"
            coverage = "mapped-by-module" if module_demos or module_tests or module.startswith("Tests/") else "needs-review"
        elif is_swiftui:
            kind, risk, coverage = "swiftui-only", "low", "not-applicable"
        elif is_foundation_only:
            kind, risk, coverage = "not-ui", "none", "not-applicable"
        else:
            kind, risk, coverage = "not-ui", "low", "not-applicable"
        relative = path.relative_to(repo).as_posix()
        evidence = ";".join(f"{relative}:{hit['line']}" for hit in file_hits)
        records.append({
            "path": relative,
            "module": module,
            "target": context["target"],
            "subspec": context["subspec"],
            "consumer_fixture": context["consumer_fixture"],
            "public_api": "yes" if PUBLIC_API.search(text) else "no",
            "ui_type": kind,
            "ownership": ownership(path.relative_to(repo), module),
            "layout_mode": layout_mode(text, file_hits),
            "risk": risk,
            "coverage": coverage,
            "demo_id": ";".join(module_demos),
            "test_id": ";".join(module_tests),
            "status": "candidate" if file_hits else "inventory",
            "decision": "not-reviewed",
            "evidence": evidence,
            "test_owner": context["target"],
            "run_status": "not_run",
            "reviewer": "",
        })
    focus_status = evaluate_focus_findings(repo, hits)
    for record in records:
        relative = str(record["path"])
        focus_id = next((finding_id for finding_id, config in FOCUS_FINDINGS.items() if config["path"] == relative), None)
        if focus_id is not None:
            result = focus_status[focus_id]
            record["decision"] = result["decision"]
            record["run_status"] = "pass_static" if result["decision"] in {"fixed", "display-only-allowed"} else "not_run"
            record["reviewer"] = "PTools Duo audit"
        elif any(str(hit["path"]) == relative for hit in hits):
            decisions = [
                classify_hit(relative, str(hit["kind"]), focus_status, int(hit["line"]), review_registry)
                for hit in hits if str(hit["path"]) == relative
            ]
            closed_decisions = {"legacy-allowlisted", "reviewed-layout", "reviewed-compatibility", "false-positive"}
            if decisions and all(item[0] in closed_decisions for item in decisions):
                record["decision"] = decisions[0][0] if len({item[0] for item in decisions}) == 1 else "reviewed"
                record["run_status"] = "waived" if all(item[0] == "legacy-allowlisted" for item in decisions) else "not_run"
                record["reviewer"] = "PTools Duo review registry"
            else:
                record["decision"] = "needs-review"
    write_reports(repo, records, hits, demos, tests, focus_status)
    ui_records = [record for record in records if record["ui_type"] not in {"not-ui", "swiftui-only"}]
    missing = [record for record in ui_records if record["coverage"] == "needs-review"]
    print(f"UIKit inventory: {len(ui_records)} files")
    print(f"Global geometry candidates: {len(hits)}")
    print(f"Coverage candidates: {len(missing)}")
    if args.strict:
        return check_report_freshness(repo, strict=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
