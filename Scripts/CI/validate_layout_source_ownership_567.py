#!/usr/bin/env python3
# English: Ensure the new target owns only its native layout source files.
# Español: Asegura que el nuevo target solo sea dueño de fuentes de layout nativas.
# 中文：确保新 target 只拥有原生布局源码。
from pathlib import Path

root = Path(__file__).resolve().parents[2]
layout = root / "PooToolsSource/PToolsConstraintLayout"
files = sorted(layout.glob("*.swift"))
if not files:
    raise SystemExit("PToolsConstraintLayout has no Swift sources")
for path in files:
    body = path.read_text(encoding="utf-8")
    if any(token in body for token in ("import SnapKit", "import PooTools", "import ptools")):
        raise SystemExit(f"standalone source imports a forbidden module: {path}")
print(f"PTLayout source ownership: {len(files)} native files; no forbidden imports")
