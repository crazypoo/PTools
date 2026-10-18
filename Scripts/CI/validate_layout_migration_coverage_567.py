#!/usr/bin/env python3
# English: Require a generated full inventory and make legacy exceptions visible.
# Español: Exige un inventario completo generado y hace visibles las excepciones legacy.
# 中文：要求生成完整清单，并显式展示 legacy 豁免。
from pathlib import Path
import csv
import runpy

root = Path(__file__).resolve().parents[2]
runpy.run_path(str(Path(__file__).with_name("audit_layout_567.py")), run_name="__main__")
inventory = root / "report/layout/Full_Layout_Inventory.csv"
with inventory.open(newline="", encoding="utf-8") as handle:
    rows = list(csv.DictReader(handle))
if not rows:
    raise SystemExit("layout inventory is empty")
print(f"PTLayout migration inventory: {len(rows)} call sites; legacy rows remain explicitly reviewable")
