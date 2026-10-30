# PTools PR31–PR35: Debug module boundaries and release gates

## Scope and principles

This branch implements the next source-compatible extraction from the PTools 5.x `PooToolsDEBUG` umbrella. Do **not** treat branch creation, CI submission, or a Linux-only compile as evidence that the full Inspector and Console UI compile on an Apple SDK. CocoaPods DEBUG keeps its old files and API. SwiftPM obtains one physical source owner per module.

| Phase | Code change | Verification |
| --- | --- | --- |
| PR31 | Add independent Linux generator reproducibility check and macOS-15 Apple SDK build check for the extracted Inspector and Debug umbrella; retain the macOS-26 full Quality jobs | Source ownership check, macOS-15 SwiftPM target compilation, full macOS-26 gates |
| PR32 | Replace the unbounded 5.x capture list subscription with a 32-event newest buffer; continue rebuilding from the authoritative `PTNetworkCaptureStore` Actor snapshot | Burst changes, navigation/cancellation/Scene cleanup, clear/reset, long-running memory |
| PR33 | Give all original `PooToolsSource/Inspector/` UIKit sources one standalone SwiftPM target, `PToolsDebugInspectorLegacyUI`; consume its public static Inspector start/stop/present API from Debug and Console | Build all Inspector files and verify the old `PooToolsDEBUG` import contract; highlight, hierarchy, edits and Undo |
| PR34 | Give Console event delivery its own `PToolsDebugConsoleCore` SwiftPM target; re-export via `PToolsDebugCore`; move Metrics timeline layout math to `PToolsDebugMetricsCore` | Swift 6 real module compile, Console observer tokens, timeline geometry and rendering parity |
| PR35 | Add legacy compatibility tests, static source ownership contracts and a release audit; keep iPhone–Mac Bridge schema and opt-in hooks unchanged | Entire regression matrix below |

## SwiftPM build graph

```text
PToolsDebugConsoleCore (PTDebugEvent, PTDebugEventCenter)
    -> PToolsDebugCore (source-compatible @_exported facade + session owner)
       -> PooToolsDEBUG (collector and legacy UI)
PToolsDebugMetricsCore (bounded ring + timeline geometry)
    -> PooToolsDEBUG (UIKit Instruments timeline and dashboard)
PToolsDebugInspectorLegacyUI (original 300+ local Inspector UIKit files)
    -> PooToolsDEBUG (source-compatible Inspector exports; local Debug and LocalConsole clients)
PToolsDebugInspectorCore (Studio fingerprint) + PToolsDebugInspectorUI (Studio highlight)
    -> PToolsDebugStudioBridge (authorized diagnostics)
PToolsDebugNetworkCore -> PooToolsDEBUG (single Actor Store)
PToolsDebugInventoryCore -> PToolsDebugStorageCore -> PooToolsDEBUG
```

The source-facing `Inspector.start()`, `Inspector.stop()`, and `Inspector.present(animated:)` calls still refer to the same internal singleton. No new window owner, swizzle, URLProtocol or Metrics sampler is introduced.

The **Console window** and **Metrics UIKit dashboard** are still source-owned by `PooToolsDEBUG`; only their event/geometry data cores are separated in this PR. Any complete UI migration that depends on Debug controllers must be staged behind a reversible façade after Apple's target compiler verifies access control.

## Required commands

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
swift build --triple arm64-apple-ios17.0-simulator --target PToolsDebugInspectorLegacyUI
swift build --triple arm64-apple-ios17.0-simulator --target PooToolsDEBUG
```

Never blindly accept generated report drift or mutate version baselines solely to force a green check; regenerate with the existing generator, review every difference, and rerun check mode.

### Confirmed current full-governance blocker

The Linux report generator first failed because `cocoapods` was not installed; its CI job now installs CocoaPods 1.16.2. The next run reached the pre-existing hard file-size rule and failed on **`PooToolsSource/Base/PTNavigationBarManager.swift` (2,499 lines, limit 2,000)**. This navigation-bar refactor is outside the Debug compatibility patch, and must not be silently waived or changed without its own iOS 26/27, transition, large-title and multi-scene regression. Because the generator aborts there, its reproducibility check is **not yet passed**, even if the Debug Core smoke checks are green.

The separate Apple SDK job is currently queued; neither 300+ source Inspector compilation nor CocoaPods lint is confirmed. Keep the PR Draft until these blockers are addressed.

## 6.0 real-device acceptance

Test Debug and Release on supported iPhones, multiple active UIWindowScenes and one real Mac Studio. Confirm: (1) Bonjour discovery; (2) CA/TLS pin trust; (3) explicit authorization/pairing; (4) live requests and ACK; (5) delete/reset; (6) reconnect after app/background/network change; (7) bad peer rejection. Also check Inspector hierarchy/selection/highlight/edit/Undo, Console visibility/observer cleanup, Storage/Defaults metadata privacy, 30-minute idle capture overhead, bounded memory and at least 100/500/1000 network records.

No percentage speedup, native Apple compilation, CocoaPods success, 7/7 acceptance or published PTools 6.0 release is claimed until the relevant jobs and devices actually establish it.
