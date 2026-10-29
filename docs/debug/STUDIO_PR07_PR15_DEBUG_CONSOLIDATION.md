# Studio PR07–PR15: PTools diagnostics consolidation

This document describes what this branch implements and what is still blocked. It does not supersede the 5.x API or 6.0 removal gates.

## Implemented
- PR10: HTTPS long-poll client timeout adjusted to the Mac eight-second wait; bounded failure backoff; pause periodic polls when the app is inactive.
- PR10/14: Studio FPS, CPU and memory observations now use the existing `PTInstrumentRecorder` snapshots. The duplicate `PTStudioFrameCounter` display link and separate Mach CPU/memory reader were removed. The recorder is created lazily on first Performance request.
- PR12: `PToolsDebugInventoryCore` standalone, Foundation-only SwiftPM product/target and privacy redactor in `PToolsStudioProtocolCore`.
- PR13: `PTDebugFileInventory` and `PTDebugDefaultsInventory` remain public adapters in `PooToolsDEBUG`; the source of truth is now `PTDebugInventoryCore`. CocoaPods DEBUG embeds the same Core source exactly once.
- PR14: Studio Agent delegates file and defaults inventory to the shared core and performs bounded filesystem scans off MainActor. Existing Debug APIs and LocalConsole are not removed.
- PR11: Inspector unchanged responses are fingerprinted; privacy sanitation is applied before returning diagnostics, independently of the Mac's redaction.
- PR15: Standalone DebugInventoryCore and StudioProtocolCore privacy XCTest regression suites.

## Architecture
```text
PToolsDebugInventoryCore (Foundation-only)       PToolsStudioProtocolCore (Foundation-only)
                |                                         |
                v                                         v
       PooToolsDEBUG (legacy facade) -----------------> PToolsDebugStudioBridge
                ^                                         |
     LocalConsole, PTInstruments                      paired macOS Studio
```

## Remaining full 6.0 modularization
- Split `PooToolsDEBUG` into independently buildable Inspector, Network, Metrics, Storage and presentation targets. This branch begins extraction with Foundation inventory; it does not complete that larger replatform.
- Migrate remaining callers from `PTHttpDatasource` / `PTHttpModel` before deleting them. Keep `PTNetworkCaptureStore` as sole capture source.
- Unify Inspector local UI and remote value model after public API mapping.
- Consider log-sink bridging using `PTLogger` subscriptions; no interception of app secrets.
- SegmentedControl, Speech, HUD/Overlay and Media cache duplication retain their separate existing 6.0 behavior-matrix gates. Do not delete based on names alone.

## Required regression
- `swift package dump-package`, target-specific SwiftPM tests and CocoaPods Debug integration.
- Test Standalone Foundation compilation, Swift 6 strict concurrency and Release with Studio diagnostics excluded.
- Confirm 1-device and multiple-scene UIView inspection; edit/undo, opt-in screen preview and valid sanitized exports.
- Confirm Performance first snapshot can be `Sampling…` until recorder samples arrive. Multiple users of `PTInstrumentRecorder.shared` must be coordinated before changing its lifecycle further.
- Verify all seven previously passed Network Bridge checks, paired token/CA renewal, reconnect, background suspension and Debug disabled-state overhead.
- No assertion of physical-device acceptance or merged state until tests complete.

## Definition of done
A module is marked migrated only after public API parity, SPM + Pods build, iPhone runtime verification, safety/permission checks and a documented source-of-truth owner. Generated reports must be refreshed by existing repository governance generators; do not hand-edit generated audit files.
