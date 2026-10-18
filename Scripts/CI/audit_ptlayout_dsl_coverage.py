#!/usr/bin/env python3
# English: Keep the public DSL and fixture inventory in one reproducible report.
# Español: Mantiene el DSL público y el inventario de fixtures en un informe reproducible.
# 中文：用一个可复现报告维护公开 DSL 与夹具清单。
from pathlib import Path
import runpy

runpy.run_path(str(Path(__file__).with_name("audit_layout_567.py")), run_name="__main__")
