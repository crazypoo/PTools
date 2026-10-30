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
