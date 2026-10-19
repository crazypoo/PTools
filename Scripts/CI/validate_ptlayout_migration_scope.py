#!/usr/bin/env python3
# English: Block unreviewed large PTLayout migrations instead of allowing a global replacement.
# Español: Bloquea migraciones grandes de PTLayout sin revisión en lugar de permitir reemplazos globales.
# 中文：阻断未经审查的大规模 PTLayout 迁移，禁止一键全仓替换。

from __future__ import annotations

import os
import subprocess
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    base = os.environ.get("PTLAYOUT_MIGRATION_BASE", "HEAD")
    diff = subprocess.run(
        ["git", "diff", "--unified=0", base, "--", "PooTools", "PooToolsSource"],
        cwd=root,
        text=True,
        capture_output=True,
        check=False,
    ).stdout
    files: set[str] = set()
    calls = 0
    current = ""
    for line in diff.splitlines():
        if line.startswith("+++ b/"):
            current = line[6:]
        elif line.startswith("+") and not line.startswith("+++") and ".snp" in line:
            files.add(current)
            calls += line.count(".snp")
    if len(files) > 10 or calls > 30:
        approved = os.environ.get("PTLAYOUT_MIGRATION_APPROVAL", "").strip()
        if approved != "reviewed-large-migration":
            raise SystemExit(f"FAIL: PTLayout migration scope is {len(files)} files/{calls} calls; review required")
    print(f"PTLayout migration scope: {len(files)} files/{calls} added .snp calls")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
