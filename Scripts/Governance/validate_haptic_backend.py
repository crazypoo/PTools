#!/usr/bin/env python3

# English: Keep UIKit feedback-generator construction inside the one native backend.
# Español: Mantiene la creación de generadores UIKit dentro del único backend nativo.
# 中文：确保 UIKit 反馈生成器只在唯一原生后端中创建。

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE_ROOT = ROOT / "PooToolsSource"
# English: Standalone Slider and CheckBox targets intentionally keep their local wrapper because their SwiftPM targets do not depend on PToolsFeedback.
# Español: Los destinos independientes Slider y CheckBox conservan intencionalmente su wrapper local porque sus destinos SwiftPM no dependen de PToolsFeedback.
# 中文：独立 Slider 和 CheckBox target 有意保留本地包装器，因为它们的 SwiftPM target 不依赖 PToolsFeedback。
ALLOWED = {
    "PooToolsSource/PToolsFeedback/PTFeedback.swift",
    "PooToolsSource/Slider/PTRangeSeekSlider.swift",
    "PooToolsSource/Slider/PTSlider.swift",
    "PooToolsSource/CheckBox/PTCheckBox.swift",
}
PATTERN = re.compile(r"\bUI(?:Impact|Selection|Notification)FeedbackGenerator\s*\(")


def main() -> None:
    violations: list[str] = []
    for path in sorted(SOURCE_ROOT.rglob("*.swift")):
        relative = path.relative_to(ROOT).as_posix()
        if relative in ALLOWED:
            continue
        for number, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
            if line.lstrip().startswith("//"):
                continue
            if PATTERN.search(line):
                violations.append(f"{relative}:{number}:{line.strip()}")
    if violations:
        print("FAIL [HAPTIC_BACKEND] direct UIKit generator construction outside PTHapticEngine", file=sys.stderr)
        print("\n".join(violations), file=sys.stderr)
        raise SystemExit(1)
    print("PASS [HAPTIC_BACKEND] direct UIKit generator construction is confined to PTHapticEngine")


if __name__ == "__main__":
    main()
