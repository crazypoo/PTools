#!/usr/bin/env python3
# English: Verify the public product owns the expected names and no SnapKit type leaks.
# Español: Verifica los nombres públicos esperados y que no se filtren tipos de SnapKit.
# 中文：校验公开产品的 API 名称，并确保不泄漏 SnapKit 类型。
from pathlib import Path
import runpy

runpy.run_path(str(Path(__file__).with_name("audit_layout_567.py")), run_name="__main__")
