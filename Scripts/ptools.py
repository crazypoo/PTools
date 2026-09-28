#!/usr/bin/env python3
"""English: Provide one stable developer command router for repository automation.
Español: Proporciona un único enrutador estable para la automatización del repositorio.
中文：提供统一稳定的仓库自动化开发者命令入口。
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def run(command: list[str]) -> int:
    """English: Run a repository command without introducing a shell quoting boundary.
    Español: Ejecuta un comando del repositorio sin introducir una frontera de comillas del shell.
    中文：执行仓库命令，不额外引入 Shell 引号边界。
    """

    completed = subprocess.run(command, cwd=ROOT)
    return completed.returncode


def dispatch(arguments: argparse.Namespace) -> int:
    group = arguments.group
    action = arguments.action

    if group == "docs" and action == "audit":
        return run([sys.executable, "Scripts/Docs/audit_docs.py", "--check"])
    if group == "docs" and action == "generate":
        return run([sys.executable, "Scripts/Docs/audit_docs.py", "--write-all"])
    if group == "repo" and action == "audit":
        return run([sys.executable, "Scripts/Governance/audit_repository.py", "--write-all"])
    if group == "repo" and action == "duplicates":
        return run([sys.executable, "Scripts/Governance/find_duplicates.py", "--write-all"])
    if group == "repo" and action == "cleanup":
        return run([sys.executable, "Scripts/Docs/apply_cleanup.py", *arguments.extra])
    if group == "tests" and action == "audit":
        return run([sys.executable, "Scripts/Governance/audit_tests.py", "--write"])
    if group == "privacy" and action == "validate":
        return run(["bash", "Scripts/Privacy/validate_privacy_accessed_api.sh", *arguments.extra])
    if group == "ci" and action == "check":
        return run(["bash", "Scripts/CI/quality_gate.sh", *(arguments.extra or ["all"])])
    if group == "release" and action == "verify":
        return run(["bash", "Scripts/validate_release.sh", *arguments.extra])
    if group == "reports" and action == "regenerate-5.8":
        commands = [
            ["ruby", "Scripts/report_spm_dependency_graph.rb"],
            ["ruby", "Scripts/report_cocoapods_subspec_graph.rb"],
            ["bash", "Scripts/validate_file_size_gate.sh"],
            ["ruby", "Scripts/report_sendable_exceptions.rb"],
        ]
        for command in commands:
            if run(command) != 0:
                return 1
        return 0

    raise ValueError(f"unsupported command: {group} {action}")


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description="PTools repository automation")
    groups = result.add_subparsers(dest="group", required=True)
    for name, actions in {
        "docs": ("audit", "generate"),
        "repo": ("audit", "duplicates", "cleanup"),
        "tests": ("audit",),
        "privacy": ("validate",),
        "ci": ("check",),
        "release": ("verify",),
        "reports": ("regenerate-5.8",),
    }.items():
        group = groups.add_parser(name)
        group.add_argument("action", choices=actions)
        group.add_argument("extra", nargs=argparse.REMAINDER)
    return result


if __name__ == "__main__":
    raise SystemExit(dispatch(parser().parse_args()))
