#!/usr/bin/env python3
# English: Inventory native and legacy layout call sites without mechanical rewriting.
# Español: Inventaría llamadas nativas y legacy sin reescritura mecánica.
# 中文：盘点原生与旧布局调用点，不执行机械替换。
from pathlib import Path
import runpy

runpy.run_path(str(Path(__file__).with_name("audit_layout_567.py")), run_name="__main__")
