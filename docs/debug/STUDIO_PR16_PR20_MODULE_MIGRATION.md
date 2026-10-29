# PTools PR16–PR20 — Debug module migration and CI acceptance

Scope: incremental, source-compatible migration on a dedicated feature branch. Full DebugNetwork/UIKit presentation splitting is not declared complete.

## PR16 — independent build and test gates
- `Scripts/CI/quality_gate.sh tests` runs standalone Core, InventoryCore, InspectorCore and StudioProtocolCore XCTest filters, plus iOS simulator compile coverage for the Debug and Studio Bridge tests.
- `Scripts/validate_instruments_5_11.sh` verifies the new source ownership/SwiftPM/CocoaPods mappings and rejects UIKit imports in the Foundation-only modules.
- `Scripts/module_registry.json` documents deliberate SwiftPM target vs CocoaPods aggregate subspec differences. Regenerate all `report/current` audit artifacts before acceptance.

## PR18 — Debug ownership
```text
PToolsDebugCore (PTDebugSessionOwnerLedger, Foundation)
    -> PooToolsDEBUG.PTDebugManager (MainActor adapter)
    -> PTDebugHookRegistry -> opt-in UIKit collectors
```
Scene owner duplication, unknown releases and global stop are idempotent. Underlying reversible hooks and irreversible swizzle rules are unchanged.

## PR19 — physical module extraction
```text
PToolsDebugMetricsCore (PTDebugRingBuffer)
    -> PooToolsDEBUG.PTInstrumentSession (actor)
PToolsDebugInspectorCore + PToolsStudioProtocolCore
    -> PToolsDebugStudioBridge (UIKit diagnostic adapter)
PToolsDebugInventoryCore
    -> PooToolsDEBUG (compatibility inventory facade)
```
SwiftPM exposes separately buildable Foundation-only targets. CocoaPods DEBUG and DEBUG_StudioBridge embed each exact source once to preserve the existing subspec API. Local Console and Debug UI are still UIKit modules, not rebranded as macOS-compatible components.

## PR20 — de-duplication
- Studio Agent no longer implements a separate image-free Inspector fingerprint hash; it calls the Inspector Core contract.
- Studio log and file-name redaction now share the Studio Protocol privacy scrub instead of a second independent Debug Instruments text adapter.
- The active Network capture remains `PTNetworkCaptureStore`. `PTHttpDatasource` and `PTHttpModel` remain legacy UI projections, not deleted or promoted to the authoritative data source.

## Safety and compatibility release gates
- SwiftPM module builds and XCTest, CocoaPods lint, strict Swift 6 diagnostics, Debug and Release Example builds, and generated module/API governance reports all pass.
- iPhone physical-device pairing, Bonjour, CA/TLS and pin, Network Bridge schema v1 7/7, Inspector tree/highlight/edit/undo, Storage/Defaults, Console and Performance all pass.
- Recorder startup is still opt-in; no new DisplayLink or swizzle appears when Debug is disabled.
- Repeat single- and multi-scene start/stop cycles and verify collector counts.
- Do not remove the `PooToolsDEBUG` façade or old capture models until the published 6.0 API-removal conditions and device evidence are met.

### Deferred work
- Separate UIKit Inspector, DebugNetwork and presentation targets require an interface dependency map and SPM/Pods behavior tests for each old public symbol.
- Full 30-minute Mac/iPhone Instruments profiling requires a real macOS runner and paired device; it cannot be proven by source or simulator-only checks.
