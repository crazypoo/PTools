#!/usr/bin/env python3
# English: Check the independent target declaration instead of assuming the umbrella graph.
# Español: Comprueba la declaración del target independiente, no supone el grafo del umbrella.
# 中文：检查独立 target 声明，不把聚合依赖图误认为独立产品。
from pathlib import Path

root = Path(__file__).resolve().parents[2]
package = (root / "Package.swift").read_text(encoding="utf-8")
podspec = (root / "PooTools.podspec").read_text(encoding="utf-8")
if 'name: "PToolsConstraintLayout"' not in package:
    raise SystemExit("SwiftPM target is missing")
if "s.subspec 'ConstraintLayout'" not in podspec:
    raise SystemExit("CocoaPods ConstraintLayout subspec is missing")
source = "".join(path.read_text(encoding="utf-8") for path in (root / "PooToolsSource/PToolsConstraintLayout").glob("*.swift"))
if "import SnapKit" in source or "import PooTools" in source or "import ptools" in source:
    raise SystemExit("standalone PTLayout source imports a forbidden module")
print("PTLayout dependency boundary: standalone source has no SnapKit reference")
