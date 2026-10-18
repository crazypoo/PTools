#!/usr/bin/env python3
# English: Validate the standalone product boundary before the aggregate bridge.
# Español: Valida el límite del producto independiente antes del puente agregado.
# 中文：先验证独立产品边界，再验证聚合桥接。
from pathlib import Path
import runpy

runpy.run_path(str(Path(__file__).with_name("audit_layout_567.py")), run_name="__main__")
