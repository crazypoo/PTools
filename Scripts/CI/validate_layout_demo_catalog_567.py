#!/usr/bin/env python3
# English: Validate stable demo IDs before the Example route is opened.
# Español: Valida los IDs estables antes de abrir la ruta del Example.
# 中文：在打开 Example 路由前校验稳定 Demo ID。
from pathlib import Path

root = Path(__file__).resolve().parents[2]
body = (root / "PooTools/PTDemoCatalog.swift").read_text(encoding="utf-8")
ids = [
    "ui.layout.snapkit-compatibility",
    "ui.layout.missing-superview-no-crash",
    "ui.layout.size-only-without-parent",
    "ui.layout.cross-tree-error",
    "ui.layout.safe-remake",
    "ui.layout.update-mismatch",
    "ui.layout.safe-area-keyboard-rtl",
    "ui.layout.profile-compare",
    "ui.layout.duo-adaptation",
    "ui.layout.lifecycle-reuse",
]
missing = [value for value in ids if value not in body]
if missing:
    raise SystemExit("missing PTLayout demo IDs: " + ", ".join(missing))
print(f"PTLayout demo catalog: {len(ids)}/10 IDs registered")
