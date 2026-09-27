#!/usr/bin/env python3
"""Regenerate the catalog in a temporary directory and fail when checked-in output drifts."""

# English: CI compares generated output without modifying the repository.
# Español: CI compara la salida generada sin modificar el repositorio.
# 中文：CI 在临时目录比较生成物，不修改仓库。

from __future__ import annotations

import argparse
import filecmp
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = Path(__file__).resolve().with_name("generate_device_catalog.py")
DEFAULT_OUTPUT = ROOT / "PooToolsSource/PToolsDevice/Generated"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--catalog-dir", type=Path)
    parser.add_argument("--generated-dir", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="ptools-device-catalog-") as directory:
        command = ["python3", str(SCRIPT), "--output-dir", directory]
        if args.catalog_dir:
            command.extend(["--catalog-dir", str(args.catalog_dir)])
        subprocess.run(command, check=True)
        expected = sorted(Path(directory).glob("*.generated.swift"))
        actual = sorted(args.generated_dir.glob("*.generated.swift"))
        expected_names = {path.name for path in expected}
        actual_names = {path.name for path in actual}
        if expected_names != actual_names:
            raise SystemExit(f"generated file set differs: expected={expected_names}, actual={actual_names}")
        different = [name for name in expected_names if not filecmp.cmp(Path(directory) / name, args.generated_dir / name, shallow=False)]
        if different:
            raise SystemExit("generated catalog is stale: " + ", ".join(sorted(different)))
    print("generated catalog is up to date")


if __name__ == "__main__":
    main()
