# PTools PR36–PR40 — Debug UI extraction and 6.0 release gate

## Implemented code

| Stage | Physical ownership | Compatibility |
| --- | --- | --- |
| PR36 | `Base/PTNavigationBarManager.swift` owns the manager and UINavigationControllerDelegate; `Base/PTNavigationBarManagerSupport.swift` owns renderer types and proxy; `Base/PTNavigationBarManager+Components.swift` owns display link, transition and custom item/layout operations | Original public navigation entrypoints, Scene handling, renderer decisions and status-bar behavior preserved; main file is 1,996 lines |
| PR37 | Dedicated iOS 17 simulator CI target build compiles Inspector's 305-file `PToolsDebugInspectorLegacyUI`, the new Console/Metrics leaves and original `PooToolsDEBUG` | No new hook or installer; old Inspector static API is retained |
| PR38 | `PToolsDebugConsoleUI/PTConsoleWindow.swift` solely owns the scene-local transparent UIWindow and touch passthrough | `LocalConsole` still owns its singleton, per-Scene log buffers, subscriptions and cleanup; its initialization injects a scene disconnect callback |
| PR39 | `PToolsDebugMetricsUI/PTDebugMetricsTrackRenderer.swift` draws track titles and separators; `PToolsDebugMetricsCore` supplies layout math | Original PTInstrumentSession/Recorder owns sampling, timeline data, events and export; no second recorder introduced |
| PR40 | SwiftPM/CocoaPods target parity, Linux syntax and source ownership gates, opt-in UIWindow/Metrics UIKit smoke tests and Studio two-phone wrong-session regression | Release blocked until the required tests pass |

### Scope limits

The Console **window layer** is physically extracted, but LocalConsole menus/log view remain in the Debug umbrella to avoid a cyclic dependency on Debug controllers and feature actions. The Metrics **track renderer** is physically extracted, but the complete PTInstrumentDashboardViewController remains in Debug because it owns the running PTInstrumentSession/Recorder. This is intentional staging, **not full UI target isolation**.

The full local Inspector module was extracted in PR33. PR37 specifically enforces Apple SDK compilation/behavioral acceptance for that split. Linux's `swiftc -frontend -parse` checks syntax only; they cannot establish iOS API correctness.

## Mandatory CI

```sh
# macOS with Xcode and CocoaPods, iOS 17+ simulator + current iOS SDK
swift package dump-package
swift build --triple arm64-apple-ios17.0-simulator --target PToolsDebugInspectorLegacyUI
swift build --triple arm64-apple-ios17.0-simulator --target PToolsDebugConsoleUI
swift build --triple arm64-apple-ios17.0-simulator --target PToolsDebugMetricsUI
swift build --triple arm64-apple-ios17.0-simulator --target PooToolsDEBUG
bash Scripts/Governance/generate_all_current_reports.sh --write
bash Scripts/Governance/generate_all_current_reports.sh --check
bash Scripts/CI/quality_gate.sh architecture
bash Scripts/CI/quality_gate.sh tests
bash Scripts/CI/quality_gate.sh concurrency
bash Scripts/CI/quality_gate.sh governance
bash Scripts/CI/quality_gate.sh pods
bash Scripts/CI/quality_gate.sh xcode
```

Review actual generator diffs and public-API changes before committing generated report files; do not edit generated reports or weaken the 2,000-line hard limit manually. Search/VariantCore parity entries must be reviewed by the packaging owner before expiration.

## Physical acceptance matrix

1. iOS 13+ and iOS 26/27, iPhone Duo folded/expanded, portrait/landscape and iPad: custom bar title/back controls, native vertical renderer, safe area and modal restore
2. Multi-Scene: independent UINavigationController transitions; background/foreground Scene disconnect without stale UIWindow or per-scene Console data
3. Inspector: original start/stop, hierarchy, selection, overlay highlight, property edit and Undo; no new global swizzles
4. Console: touch-through overlay, keyboard, 50k bounded log buffer, teardown of observers/tasks, multiple scenes without shared window capture
5. Metrics: 100/500/1000 events, FPS/CPU/memory readings, timeline range/zoom/filter, stop, archive and share
6. iPhone ↔ Mac: Bonjour, TLS CA + pin, explicit pairing, ACK/batching, deletion/reset, reconnect, wrong-peer rejection
7. SwiftPM and CocoaPods: release/debug simulator builds, strict concurrency, public API/source compatibility

Each acceptance case requires a test environment, run logs, outcomes, and measured timing/memory for any claimed performance improvement. Do not publish PTools 6.0 from a merged PR or Linux-only validation.

## PR41–PR45 follow-on: candidate, not 6.0 release approval

| Stage | Actual incremental work | Remaining acceptance |
| --- | --- | --- |
| PR41 | `quality-summary` now depends on independent Swift 6 Debug Foundation build, iOS 17+ Inspector/Console/Metrics target compile and generator reproducibility. Its final step fails when any required upstream gate fails, including skipped/cancelled gates. | Compare artifacts, generated current reports and Xcode/CocoaPods outcomes on an Apple runner |
| PR42 | The existing Metrics Core tests now exercise bounded ring/geometry scenarios with 100, 500 and 1000 entries, recording median and p95 wall-clock timings in test logs. | Match against baseline on a fixed device; this is not a Mac Studio UI/FPS benchmark |
| PR43 | Metrics UIKit track renderer now resolves Dynamic Type font/color once per draw pass, rather than once per track, retaining trait-change responsiveness. | Visually compare captions and grid on iOS 17/26/27 and Dynamic Type settings |
| PR44 | Moves the existing Metrics timeline sample, event-marker and selected-range drawing primitives into the separate Metrics UIKit leaf, while keeping collector ownership and selection logic in Debug. Full Debug-menu/dashboard migration remains blocked by controller dependencies. | Verify identical marker colors, coordinates and range highlight, and run old `PooToolsDEBUG` entry-point compatibility |
| PR45 | Release verification carries the real-device and security acceptance requirements below, with no waiver for native builds. | 7/7 Mac–iPhone scenarios, two paired iPhones, 30-minute idle profile and report digests |

### Mandatory PR41 checks

```sh
bash Scripts/Governance/generate_all_current_reports.sh --check
bash Scripts/CI/quality_gate.sh architecture
bash Scripts/CI/quality_gate.sh governance
bash Scripts/CI/quality_gate.sh tests
bash Scripts/CI/quality_gate.sh concurrency
bash Scripts/CI/quality_gate.sh pods
bash Scripts/CI/quality_gate.sh xcode
swift build --triple arm64-apple-ios17.0-simulator --target PToolsDebugInspectorLegacyUI
swift build --triple arm64-apple-ios17.0-simulator --target PToolsDebugConsoleUI
swift build --triple arm64-apple-ios17.0-simulator --target PToolsDebugMetricsUI
swift build --triple arm64-apple-ios17.0-simulator --target PooToolsDEBUG
swift test --filter PTDebugCoreTests
```

Do not mistake a Linux Swift syntax parse for a real Apple SDK typecheck.
Do not edit generated reports by hand or add exceptions to the 2000-line gate.
Generated report changes must come from the canonical generator and be reviewed.

### PR45 acceptance record

| # | Check | Actual | Evidence |
| --- | --- | --- | --- |
| 1 | Bonjour auto discovery, identity and reconnect | NOT RUN | — |
| 2 | TLS CA/pin trust and invalid leaf rejection | NOT RUN | — |
| 3 | Explicit pairing, revocation and token refusal | NOT RUN | — |
| 4 | Request capture, 100/500/1000 records, batching and ACK | NOT RUN | — |
| 5 | Delete and reset with no stale resurrection | NOT RUN | — |
| 6 | Background/foreground, Scene disconnect, multi-window UI | NOT RUN | — |
| 7 | Two iPhones, forged wrong-session response, replay refusal | NOT RUN | — |

Additional blocking checks: Inspector hierarchy/highlight/edit/Undo, Console scene teardown,
Metrics export, iOS 26/27 navigation regression and 30-minute Mac CPU/memory idle measurement.

**Status: awaiting Apple CI and physical-device evidence; not approved for release.**
