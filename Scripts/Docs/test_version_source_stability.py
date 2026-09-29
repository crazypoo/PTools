#!/usr/bin/env python3
"""English: Regression check that module guides do not churn on VERSION bumps.
Español: Comprueba que las guías no cambien al incrementar VERSION.
中文：回归检查模块指南不会因为 VERSION bump 产生无意义 Diff。
"""

from __future__ import annotations

import hashlib
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Docs"))
import audit_docs  # noqa: E402


def digest_for(version: str) -> str:
    original = audit_docs.VERSION
    audit_docs.VERSION = version
    try:
        item = audit_docs.modules_registry()[0]
        text = audit_docs.module_document(item, "en")
        return hashlib.sha256(text.encode("utf-8")).hexdigest()
    finally:
        audit_docs.VERSION = original


def main() -> int:
    first = digest_for("5.57.0")
    second = digest_for("5.57.1")
    if first != second:
        print("FAIL [DOC_VERSION_COPY] module guide changes when only VERSION changes")
        return 1
    print("PASS: module guide output is stable across VERSION changes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
