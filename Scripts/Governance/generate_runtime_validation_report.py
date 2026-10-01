#!/usr/bin/env python3

# English: Record runtime-only proof requirements without claiming simulator or device evidence.
# Español: Registra requisitos de prueba en ejecución sin afirmar evidencia de simulador o dispositivo.
# 中文：记录只能通过运行时验证的要求，不伪造模拟器或真机证据。

from __future__ import annotations

import hashlib
import os
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REPORT_DIR = Path(os.environ.get("PTOOLS_REPORT_DIR", ROOT / "report/current"))


def source_digest() -> str:
    digest = hashlib.sha256()
    for path in sorted((ROOT / "PooToolsSource").rglob("*.swift")):
        digest.update(path.relative_to(ROOT).as_posix().encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()


def main() -> None:
    rows = [
        ("PTVideoCoverCache", "REQUIRES_INSTRUMENTS_OR_DEVICE"),
        ("PTVideoThumbnailService", "REQUIRES_INSTRUMENTS_OR_DEVICE"),
        ("PTLoadImageFunction", "REQUIRES_INSTRUMENTS_OR_DEVICE"),
        ("MediaViewer", "REQUIRES_INSTRUMENTS_OR_DEVICE"),
        ("PTRichText media", "REQUIRES_INSTRUMENTS_OR_DEVICE"),
        ("VideoEditor", "REQUIRES_INSTRUMENTS_OR_DEVICE"),
        ("ImageEditor", "REQUIRES_INSTRUMENTS_OR_DEVICE"),
    ]
    lines = [
        "<!-- AUTO-GENERATED: do not edit manually. -->",
        "",
        "# MainActor Runtime Validation",
        "",
        f"Source inputs digest: `{source_digest()}`",
        "",
        "This report intentionally does not claim runtime proof. Execute the listed flows with Instruments or on a real iOS device before the 6.0 release gate.",
        "",
        "| Flow | Status | Required evidence |",
        "| --- | --- | --- |",
    ]
    lines.extend(f"| {name} | {status} | MainActor time, off-main work, cancellation, and memory trace |" for name, status in rows)
    lines.extend([
        "",
        "## Acceptance rule",
        "",
        "`REQUIRES_INSTRUMENTS_OR_DEVICE` is a release blocker until an attached Instruments trace or real-device run is recorded by the host project.",
    ])
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    (REPORT_DIR / "mainactor_runtime_validation.md").write_text("\n".join(lines) + "\n")
    print("PASS [RUNTIME_VALIDATION_REPORT] runtime evidence remains explicitly pending")


if __name__ == "__main__":
    main()
