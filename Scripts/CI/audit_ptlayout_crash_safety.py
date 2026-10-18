#!/usr/bin/env python3
# English: Reuse the single source-of-truth audit for crash-safety fixtures.
# Español: Reutiliza la auditoría única para los fixtures de seguridad ante fallos.
# 中文：复用唯一审计入口，检查防崩溃故障夹具。
from pathlib import Path
import runpy

runpy.run_path(str(Path(__file__).with_name("audit_layout_567.py")), run_name="__main__")
