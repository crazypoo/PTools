#!/usr/bin/env python3
"""PR54: guard ownership, privacy and framework boundaries of PTools Debug Studio.

This is a static CI smoke test. It does not substitute for native Apple SDK
builds or prove runtime authorization of a physical iPhone.
"""
from pathlib import Path
import re

root = Path(__file__).resolve().parent.parent
sources = root / "PooToolsSource"

def owners(regex: str):
    return sorted(
        p.relative_to(root).as_posix()
        for p in sources.rglob("*.swift")
        if re.search(regex, p.read_text(encoding="utf-8"))
    )

expected = {
    r"\bclass\s+PTStudioDiagnosticAgent\b": [
        "PooToolsSource/DebugStudioBridge/PTStudioDiagnosticAgent.swift"
    ],
    r"\benum\s+PTStudioDiagnosticPrivacy\b": [
        "PooToolsSource/PToolsStudioProtocolCore/PTStudioDiagnosticPrivacy.swift"
    ],
    r"\benum\s+PTDebugInspectorSnapshotSignature\b": [
        "PooToolsSource/PToolsDebugInspectorCore/PTDebugInspectorSnapshotSignature.swift"
    ],
    r"\benum\s+PTStudioInspectorLayoutMetadata\b": [
        "PooToolsSource/DebugStudioBridge/PTStudioDiagnosticAgent.swift"
    ],
}
for name, target in expected.items():
    actual = owners(name)
    assert actual == target, f"Debug studio owner drift: {name}: {actual}"

core = sources / "PToolsStudioProtocolCore"
for file in core.glob("*.swift"):
    text = file.read_text(encoding="utf-8")
    assert not re.search(r"\bimport\s+(UIKit|AppKit|SwiftUI)\b", text), file
    assert "UIApplication.shared" not in text, file

agent = (sources / "DebugStudioBridge" / "PTStudioDiagnosticAgent.swift").read_text()
for token in (
    '#if os(iOS) && DEBUG',
    'UserDefaults.standard.bool(forKey: "PTStudio.diagnosticsEnabled")',
    'UserDefaults.standard.bool(forKey: "PTStudio.editingEnabled")',
    "PTStudioDiagnosticPrivacy.sanitize(",
    "PTStudioInspectorLayoutMetadata.attributes(for: view)",
    'case (.inspector, "snapshot")',
    'case (.performance, "snapshot")',
    'case (.logging, "snapshot")',
):
    assert token in agent, f"Missing Debug-only consent/capability guard: {token}"

assert "let installedConstraints = view.constraints" in agent
assert "installedConstraints.reduce(into: 0)" in agent
assert "String(constraint)" not in agent, "Raw constraint descriptions must not leave iOS"
assert 'view.addConstraint(' not in agent and 'view.removeConstraint(' not in agent

wire = (core / "PTStudioDiagnosticProtocol.swift").read_text()
assert "public static let schemaVersion = 2" in wire
assert "public enum PTStudioDiagnosticDomain" in wire
assert "public struct PTStudioDiagnosticEntry" in wire

print("PASS: unique Debug Studio owners; strict consent, redaction and Foundation-only v2 wire")
