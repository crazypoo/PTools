#!/usr/bin/env python3
"""English: Apply an explicitly reviewed repository cleanup manifest.
Español: Aplica un manifiesto de limpieza del repositorio revisado explícitamente.
中文：执行已经明确审阅的仓库清理清单。

The default mode is dry-run. Only --apply can move or delete files, and every
operation must use a repository-relative file path rather than a directory.
"""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def safe_path(value: str) -> Path:
    path = (ROOT / value).resolve()
    if path == ROOT or ROOT not in path.parents or path.is_dir():
        raise ValueError(f"cleanup path must be a repository file: {value}")
    return path


def apply(manifest: Path, should_apply: bool) -> int:
    payload = json.loads(manifest.read_text(encoding="utf-8"))
    operations = payload.get("operations", [])
    if not isinstance(operations, list):
        raise ValueError("manifest operations must be a list")
    for operation in operations:
        action = operation.get("action")
        source = safe_path(operation["source"])
        destination = safe_path(operation["destination"]) if operation.get("destination") else None
        if action == "move":
            if destination is None:
                raise ValueError("move operation requires destination")
            if source.exists() and not destination.exists():
                print(f"MOVE {source.relative_to(ROOT)} -> {destination.relative_to(ROOT)}")
                if should_apply:
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    shutil.move(str(source), str(destination))
            elif not source.exists() and destination.exists():
                print(f"ALREADY_APPLIED {source.relative_to(ROOT)} -> {destination.relative_to(ROOT)}")
            else:
                raise ValueError(f"unsafe or ambiguous move: {operation}")
        elif action == "delete":
            print(f"DELETE {source.relative_to(ROOT)}")
            if should_apply and source.exists():
                source.unlink()
        else:
            raise ValueError(f"unsupported cleanup action: {action}")
    if not should_apply:
        print("DRY_RUN_ONLY: pass --apply after consumer review")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Apply a reviewed PTools cleanup manifest")
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    return apply(args.manifest.resolve(), args.apply)


if __name__ == "__main__":
    raise SystemExit(main())
