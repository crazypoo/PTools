#!/usr/bin/env python3
# English: Normalize independent consumer diagnostics into one actionable report.
# Español: Normaliza los diagnósticos de consumidores independientes en un informe accionable.
# 中文：将独立消费者诊断归一为一份可执行报告。

from __future__ import annotations

import csv
import hashlib
import re
import sys
from pathlib import Path


ERROR = re.compile(r"^(?P<path>.*?):(?P<line>\d+):(?P<column>\d+):\s*(?P<kind>error|warning):\s*(?P<message>.*)$")
MISSING = re.compile(r"(?:no such module|unable to resolve module dependency)[: ]+'?([^']+)'?", re.I)


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    source_root = root / "report/spm/onepass/consumer"
    rows: list[dict] = []
    for log in sorted(source_root.glob("**/*.log")):
        relative = log.relative_to(root).as_posix()
        parts = log.relative_to(source_root).parts
        product = parts[0] if parts else "unknown"
        configuration = parts[1].removesuffix(".log") if len(parts) > 1 else "unknown"
        for raw in log.read_text(errors="replace").splitlines():
            match = ERROR.match(raw.strip())
            if not match:
                continue
            message = match.group("message")
            missing = MISSING.search(message)
            category = "missing-import" if missing else ("compiler" if match.group("kind") == "error" else "warning")
            symbol = missing.group(1) if missing else ""
            issue_key = "|".join([product, configuration, category, symbol, message])
            issue_id = "SPM-" + hashlib.sha1(issue_key.encode()).hexdigest()[:12]
            rows.append({
                "issue_id": issue_id, "phase": "consumer-build", "product": product, "target": f"SPMConsumer_{product}",
                "configuration": configuration, "path": match.group("path"), "line": match.group("line"), "column": match.group("column"),
                "diagnostic_code": "", "category": category, "symbol": symbol, "provider_target": "", "message": message,
                "root_cause": "explicit consumer import/dependency boundary requires repair" if missing else "compiler diagnostic",
                "status": "open", "repair_action": "repair target dependency/import or source diagnostic", "owner": product, "evidence": relative,
            })
    columns = ["issue_id","phase","product","target","configuration","path","line","column","diagnostic_code","category","symbol","provider_target","message","root_cause","status","repair_action","owner","evidence"]
    output = root / "report/spm/onepass/all_findings.csv"
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns, lineterminator="\n")
        writer.writeheader(); writer.writerows(rows)
    print(f"diagnostics={len(rows)} output={output.relative_to(root)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
