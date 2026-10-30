# PTools PR26–PR30 — Implementation and release gates

This PR is a code-bearing incremental split, not an assertion that PTools 6.0 or all UIKit Debug modules are fully modular.

## PR26: Build and governance
- SwiftPM exposes independently compiled Inspector UI and Storage Core targets; legacy `PooToolsDEBUG` remains the 5.x facade.
- CocoaPods DEBUG aggregates Foundation Console/Storage sources once; DEBUG_StudioBridge includes the Inspector UI leaf source once.
- A Linux Quality smoke job checks physical SwiftPM source ownership. `Scripts/validate_instruments_5_11.sh` guards against duplicate declarations and missing exported APIs.
- Required XCTest filters include StorageCore, DebugCore, InspectorCore, InventoryCore, NetworkCore, and StudioProtocolCore, and the existing iOS Debug/Bridge simulator compile gate remains.

**Unresolved:** Complete generated-report reconciliation (`Scripts/Governance/generate_all_current_reports.sh --write` followed by `--check`), public API freeze classification and macOS CocoaPods/Swift 6 validation. Do not waive CI, edit generated files manually, or claim those jobs passed without their logs.

## PR27: Network compatibility lifecycle
- `PTNetworkCaptureStore` remains the sole authoritative capture actor; `PTHttpDatasource` remains an optional, private MainActor 5.x projection only.
- The legacy array gains a bounded O(1) ID membership index with removal and eviction cleanup, and no longer conflates all nil request IDs.
- The presentation hook owner registry releases metadata when the last owner unregisters. The source itself explicitly imports `PToolsDebugNetworkCore` for SwiftPM.
- Tests cover duplicate IDs, nil IDs, 1,001-entry eviction, and multi-scene final-owner release.

## PR28: Inspector UIKit leaf
- `PToolsDebugInspectorUI` is independently compiled UIKit highlight functionality. Studio Agent uses it rather than maintaining another CAShapeLayer lifecycle.
- Inspector fingerprint/data contract remains in `PToolsDebugInspectorCore`; full local UIKit inspector screens remain in the original Debug aggregate until their dependencies are decoupled.
- Existing two-second highlight lifetime, active UIWindow requirement, Debug-only consent and Undo pipeline remain unchanged.

## PR29: Storage, Console, Metrics, UI boundaries
- `PToolsDebugStorageCore` compiles the existing public filesystem/defaults metadata projection independently from `PooToolsDEBUG` and consumes `PToolsDebugInventoryCore`.
- `PTDebugEvent` and `PTDebugEventCenter` have one owner in Foundation-only `PToolsDebugCore`; LocalConsole, PTInstruments and URLProtocol observer use that module.
- Existing Metrics ring data target remains `PToolsDebugMetricsCore`; rendering/UIView logic is not duplicated into another metric recorder.
- `PooToolsDEBUG` reexports Storage and Console API, CocoaPods compiles the canonical sources once. These do not imply full Inspector/Console/Metrics **UI** physical separation.

## PR30: Release gates
Run and attach results:
```sh
swift package dump-package
bash Scripts/Governance/generate_all_current_reports.sh --write
bash Scripts/Governance/generate_all_current_reports.sh --check
bash Scripts/CI/quality_gate.sh architecture
bash Scripts/CI/quality_gate.sh governance
bash Scripts/CI/quality_gate.sh tests
bash Scripts/CI/quality_gate.sh concurrency
bash Scripts/CI/quality_gate.sh pods
bash Scripts/CI/quality_gate.sh xcode
```
Additionally run Debug/Release builds and a paired iPhone ↔ Mac acceptance matrix: Bonjour discovery, TLS CA trust+pin, pairing, request/ACK, deletion/reset, reconnect, invalid peer, Inspector highlight/undo, Console event delivery and Storage metadata.

**No merge until** generated reports, SwiftPM/Pods/Xcode tests and device regression pass. Preserve all published 5.x APIs. Hardware CPU, FPS, peak memory and p95 latencies must be measured, not estimated.
