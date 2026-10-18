#!/usr/bin/env python3
# English: Generate the current semantic layout inventory.
# Español: Genera el inventario semántico de layout actual.
# 中文：生成当前语义布局清单。
from pathlib import Path
import subprocess
import sys


script = Path(__file__).with_name("audit_layout_567.py")
subprocess.run([sys.executable, str(script)], check=True)
