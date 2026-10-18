#!/usr/bin/env python3
# English: Check the standalone target and the approved legacy source boundaries.
# Español: Comprueba el target independiente y los límites legacy aprobados.
# 中文：检查独立 target 与已批准的 legacy 源码边界。
from pathlib import Path
import re


root = Path(__file__).resolve().parents[2]
package = (root / "Package.swift").read_text(encoding="utf-8")
podspec = (root / "PooTools.podspec").read_text(encoding="utf-8")
if 'name: "PToolsConstraintLayout"' not in package:
    raise SystemExit("SwiftPM target is missing")
if "s.subspec 'ConstraintLayout'" not in podspec:
    raise SystemExit("CocoaPods ConstraintLayout subspec is missing")
source = "".join(path.read_text(encoding="utf-8") for path in (root / "PooToolsSource/PToolsConstraintLayout").glob("*.swift"))
if any(token in source for token in ("import SnapKit", "import PooTools", "import ptools")):
    raise SystemExit("standalone PTLayout source imports a forbidden module")

allow = {
    "PooToolsSource/Base/PTSnapKitEX.swift",
    "PooToolsSource/PToolsUIFoundation/PTUIFoundationSnapKitEX.swift",
    "PooToolsSource/Category/UIView+PTEX+Constraints.swift",
    "PooToolsSource/Category/NSImageView+PTEX.swift",
    "PooToolsSource/iOS17Tips/PTTip.swift",
    "PooToolsSource/MessageKit/PTChatBaseCell.swift",
}
snp = re.compile(r"\.snp\.")
ordinary = []
for base in (root / "PooToolsSource", root / "PooTools"):
    for path in base.rglob("*.swift"):
        relative = path.relative_to(root).as_posix()
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            code = line.split("//", 1)[0]
            if snp.search(code) and relative not in allow:
                ordinary.append(f"{relative}:{number}")
if ordinary:
    raise SystemExit("ordinary PTools .snp call sites remain: " + ", ".join(ordinary))
print("PTLayout dependency boundary: standalone source is SnapKit-free; ordinary .snp is zero")
