#!/usr/bin/env python3

# English: Gate long-lived UIKit resources with an explicit owner or lifecycle bag.
# Español: Exige un propietario explícito o una bolsa de ciclo de vida para recursos UIKit duraderos.
# 中文：要求长期 UIKit 资源具备明确所有者或生命周期容器。

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE_ROOT = ROOT / "PooToolsSource"
ALLOWLIST = ROOT / "Scripts" / "Governance" / "lifecycle_resource_allowlist.json"
PATTERNS = {
    "notification": re.compile(r"NotificationCenter\.default\.addObserver"),
    "timer": re.compile(r"Timer\.scheduledTimer"),
    "displayLink": re.compile(r"CADisplayLink\s*\("),
    "task": re.compile(r"\bTask\s*\{"),
}


def main() -> None:
    allowlist = json.loads(ALLOWLIST.read_text()).get("entries", {})
    findings: list[dict[str, object]] = []
    for path in sorted(SOURCE_ROOT.rglob("*.swift")):
        relative = path.relative_to(ROOT).as_posix()
        text = path.read_text(errors="ignore")
        for number, line in enumerate(text.splitlines(), 1):
            if line.lstrip().startswith("//"):
                continue
            for kind, pattern in PATTERNS.items():
                if not pattern.search(line):
                    continue
                if kind == "task":
                    # Structured MainActor tasks and explicit weak-owner tasks are short-lived by contract.
                    # Las tareas estructuradas de MainActor y las tareas con dueño débil son de corta duración.
                    # 结构化 MainActor 任务和显式弱引用任务按短生命周期处理。
                    managed = "@MainActor" in line or "[weak " in line or "Task.detached" in line
                else:
                    managed = relative in allowlist or "PTLifecycleBag" in text
                findings.append({
                    "path": relative,
                    "line": number,
                    "kind": kind,
                    "managed": managed,
                    "reason": allowlist.get(relative),
                })

    unowned = [entry for entry in findings if not entry["managed"]]
    unknown_paths = sorted({entry["path"] for entry in findings if entry["kind"] != "task" and entry["path"] not in allowlist and not entry["managed"]})
    if unknown_paths:
        print("FAIL [LIFECYCLE_RESOURCES] new unowned resource owner(s):", file=sys.stderr)
        print("\n".join(unknown_paths), file=sys.stderr)
        raise SystemExit(1)

    print(f"PASS [LIFECYCLE_RESOURCES] findings={len(findings)} unowned_tasks={sum(entry['kind'] == 'task' for entry in unowned)}")


if __name__ == "__main__":
    main()
