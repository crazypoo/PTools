#!/usr/bin/env python3
"""Create a pending candidate report; never overwrite the production catalog."""

# English: Candidate metadata is opt-in and requires human review before catalog changes.
# Español: Los candidatos son opcionales y requieren revisión humana antes de cambiar el catálogo.
# 中文：候选设备只生成待审报告，必须人工审核后才能修改正式目录。

from __future__ import annotations

import argparse
import json
from datetime import date
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUTPUT = ROOT / "PooToolsSource/PToolsDevice/Resources/DeviceCatalog/DeviceCatalog.pending.json"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--identifier", action="append", required=True)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    payload = {
        "generatedAt": date.today().isoformat(),
        "candidates": [{"identifier": identifier, "status": "needs-review"} for identifier in args.identifier],
    }
    args.output.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote pending catalog report: {args.output}")


if __name__ == "__main__":
    main()
