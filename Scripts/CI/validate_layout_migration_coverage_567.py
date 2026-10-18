#!/usr/bin/env python3
# English: Enforce zero unclassified ordinary layout call sites.
# Español: Exige cero llamadas de layout ordinarias sin clasificar.
# 中文：强制普通布局调用点零未分类。
from __future__ import annotations

import json
import csv
import subprocess
import sys
from pathlib import Path


root = Path(__file__).resolve().parents[2]
subprocess.run([sys.executable, str(Path(__file__).with_name("audit_layout_567.py"))], check=True)
inventory = root / "report/layout/Full_Layout_Inventory.csv"
with inventory.open(newline="", encoding="utf-8") as handle:
    rows = list(csv.DictReader(handle))
if not rows:
    raise SystemExit("layout inventory is empty")

unclassified = [row for row in rows if row["decision"] == "needs_review"]
ordinary_snp = [row for row in rows if row["construct"] == "snp"]
native_escape = [row for row in rows if row["construct"].startswith("native.") and row["decision"] == "needs_review"]
missing_evidence = [row for row in rows if not row["evidence"] or not row["regression_case"]]
duplicate_keys = len(rows) - len({(row["target"], row["path"], row["line"], row["construct"]) for row in rows})
unowned_exceptions = [
    row for row in rows
    if row["decision"] == "approved_exception"
    and (not row["exception_reason"] or not row["exception_owner"] or not row["regression_case"])
]

release = root / "report/releases" / (root / "VERSION").read_text(encoding="utf-8").strip()
gate_lines = (release / "PTLayout_final_release_gate.md").read_text(encoding="utf-8").splitlines()
fence = chr(96) * 3
start = gate_lines.index(fence + "json") + 1
end = gate_lines.index(fence, start)
gate = json.loads("\n".join(gate_lines[start:end]))
expected = {
    "unclassified_call_sites": len(unclassified),
    "ordinary_ptools_snp_call_sites": len(ordinary_snp),
    "unapproved_native_layout_escape_hatches": len(native_escape),
    "unowned_duplicate_symbols": duplicate_keys,
    "exception_rows_missing_reason_or_test": len(unowned_exceptions),
    "missing_evidence": len(missing_evidence),
}
if any(expected.values()):
    raise SystemExit("PTLayout migration gate failed: " + json.dumps(expected, ensure_ascii=False))
if gate.get("metrics", {}).get("missing_target_dependencies", 0) != 0:
    raise SystemExit("PTLayout migration gate failed: missing target dependencies")
print("PTLayout migration coverage: zero ordinary .snp, zero review rows, zero unapproved escapes")
