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
    "kvo": re.compile(r"observe\s*\(\s*\\\.[A-Za-z_]"),
    "dispatchSource": re.compile(r"DispatchSource(?:Timer|Signal|Process|\.make)"),
    "task": re.compile(r"\bTask(?:\.detached)?\s*\{"),
}

LONG_LIVED_MARKERS = (
    "for await",
    "while !Task.isCancelled",
    "AsyncStream",
    "AsyncThrowingStream",
)


def context_lines(lines: list[str], index: int, radius: int = 24) -> list[str]:
    # English: Use local evidence; a whole-file marker is not ownership proof.
    # Español: Usa evidencia local; un marcador de archivo completo no prueba la propiedad.
    # 中文：只使用局部证据；整文件标记不能证明资源归属。
    return lines[max(0, index - 2):min(len(lines), index + radius)]


def has_local_lifecycle_store(context: list[str]) -> bool:
    return any("lifecycleBag.store(" in line or "lifecycleBag.storeCancellation(" in line for line in context)


def has_explicit_owner(context: list[str]) -> bool:
    assignment = re.compile(r"(?:let|var)?\s*((?:self\.)?[A-Za-z_][A-Za-z0-9_]*)\s*=")
    markers = ("task", "timer", "displaylink", "display_link", "observer", "observation", "source")
    for line in context:
        match = assignment.search(line)
        if match and any(marker in match.group(1).lower().replace(".", "") for marker in markers):
            return True
    return False


def task_is_long_lived(context: list[str]) -> bool:
    joined = "\n".join(context)
    # English: Task-group collection is bounded even though it uses `for await`.
    # Español: La recolección de un grupo de tareas es acotada aunque use `for await`.
    # 中文：TaskGroup 的结果收集虽然使用 `for await`，但生命周期是有界的。
    if "withTaskGroup" in joined or "withThrowingTaskGroup" in joined:
        return False
    return "for await" in joined or "while !Task.isCancelled" in joined


def classify_task(lines: list[str], index: int) -> tuple[bool, str]:
    context = context_lines(lines, index)
    if has_local_lifecycle_store(context):
        return True, "stored in lifecycleBag"
    if has_explicit_owner(context):
        return True, "stored in an explicit owner"
    if task_is_long_lived(context):
        return False, "unowned long-lived task"
    if "[weak " in lines[index] or "@MainActor" in lines[index] or "Task.detached" in lines[index]:
        return True, "bounded task with explicit isolation or weak owner"
    return True, "bounded one-shot task"


def main() -> None:
    allowlist = json.loads(ALLOWLIST.read_text()).get("entries", {})
    findings: list[dict[str, object]] = []
    for path in sorted(SOURCE_ROOT.rglob("*.swift")):
        relative = path.relative_to(ROOT).as_posix()
        lines = path.read_text(errors="ignore").splitlines()
        for number, line in enumerate(lines, 1):
            if line.lstrip().startswith("//"):
                continue
            for kind, pattern in PATTERNS.items():
                if not pattern.search(line):
                    continue
                if kind == "task":
                    # Structured MainActor tasks and explicit weak-owner tasks are short-lived by contract.
                    # Las tareas estructuradas de MainActor y las tareas con dueño débil son de corta duración.
                    # 结构化 MainActor 任务和显式弱引用任务按短生命周期处理。
                    managed, reason = classify_task(lines, number - 1)
                else:
                    local_context = context_lines(lines, number - 1)
                    managed = has_local_lifecycle_store(local_context) or has_explicit_owner(local_context)
                    reason = "stored in lifecycleBag" if managed else allowlist.get(relative)
                findings.append({
                    "path": relative,
                    "line": number,
                    "kind": kind,
                    "managed": managed,
                    "reason": reason,
                })

    unowned = [entry for entry in findings if not entry["managed"]]
    unowned_long_lived_tasks = [entry for entry in unowned if entry["kind"] == "task"]
    unknown_paths = sorted({entry["path"] for entry in findings if entry["kind"] != "task" and entry["path"] not in allowlist and not entry["managed"]})
    if unknown_paths:
        print("FAIL [LIFECYCLE_RESOURCES] new unowned resource owner(s):", file=sys.stderr)
        print("\n".join(unknown_paths), file=sys.stderr)
        raise SystemExit(1)

    if unowned_long_lived_tasks:
        print("FAIL [LIFECYCLE_RESOURCES] unowned long-lived task(s):", file=sys.stderr)
        for entry in unowned_long_lived_tasks:
            print(f"{entry['path']}:{entry['line']} ({entry['reason']})", file=sys.stderr)
        raise SystemExit(1)

    legacy_resources = sum(
        entry["kind"] != "task" and not entry["managed"] and entry["path"] in allowlist
        for entry in findings
    )
    print(
        "PASS [LIFECYCLE_RESOURCES] "
        f"findings={len(findings)} "
        f"unowned_long_lived_tasks={len(unowned_long_lived_tasks)} "
        f"legacy_allowlisted_resources={legacy_resources}"
    )


if __name__ == "__main__":
    main()
