#!/usr/bin/env python3
# English: Verify the public PTLayout contract and the deterministic bridge path.
# Español: Verifica el contrato público de PTLayout y la ruta determinista del puente.
# 中文：校验 PTLayout 公开契约与确定性的诊断桥路径。
from pathlib import Path
import subprocess
import sys


root = Path(__file__).resolve().parents[2]
subprocess.run([sys.executable, str(Path(__file__).with_name("audit_layout_567.py"))], check=True)
core = (root / "PooToolsSource/PToolsConstraintLayout/PTLayoutCore.swift").read_text(encoding="utf-8")
performance = (root / "PooToolsSource/PToolsConstraintLayout/PTLayoutPerformance.swift").read_text(encoding="utf-8")
bridge = (root / "PooToolsSource/Core/PTLayoutConsoleBridge.swift").read_text(encoding="utf-8")
base = (root / "PooToolsSource/Base/PTBaseViewController.swift").read_text(encoding="utf-8")
required = {
    "atomic_group_activation": "activateAtomically" in core,
    "diagnostic_codes": all(code in core for code in ("PTL001", "PTL009")),
    "weak_diagnostics": "NSMapTable<UIView" in core,
    "keyboard_support": "PTLayoutKeyboardSupport" in performance,
    "console_bridge_install": "PTLayoutConsoleBridge.install()" in base and "PTLayoutDiagnostics.onFailure" in bridge,
}
if not all(required.values()):
    raise SystemExit("PTLayout API contract failed: " + repr(required))
if any(token in core + performance for token in ("import SnapKit", "import ptools", "import PooTools")):
    raise SystemExit("standalone PTLayout source leaks an aggregate dependency")
print("PTLayout API contract: native product, atomic groups, bounded diagnostics, and bridge path present")
