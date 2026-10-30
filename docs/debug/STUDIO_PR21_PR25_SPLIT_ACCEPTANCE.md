# PTools PR21–PR25 — Capture Core split and compatibility acceptance

The patch sequence intentionally preserves existing network capture behavior and all 5.x Debug UI public entry points. These commits **do not** claim a finished UIKit Inspector/Console module split or successful physical-device acceptance.

## PR21 — CI & governance
- Add a fast Linux `debug-core-manifest` job in `.github/workflows/quality.yml` to catch invalid SwiftPM target paths, duplicate capture source ownership and forbidden UIKit imports before waiting on macOS runners.
- Add `PToolsDebugNetworkCoreTests` to `Scripts/CI/quality_gate.sh tests` and preserve the existing iOS build, CocoaPods and Swift 6 jobs.
- Document the deliberate SPM-only Network Core vs CocoaPods DEBUG aggregate in `Scripts/module_registry.json`. No additional CocoaPods library or duplicate Pod source is introduced.
- `Scripts/validate_instruments_5_11.sh` checks target uniqueness, legacy re-export, and Bridge ownership.

**Still required:** Reconcile generated reports and public API inventory through:
```sh
bash Scripts/Governance/generate_all_current_reports.sh --write
bash Scripts/Governance/generate_all_current_reports.sh --check
bash Scripts/CI/quality_gate.sh architecture
bash Scripts/CI/quality_gate.sh pods
bash Scripts/CI/quality_gate.sh tests
```
Do not waive an unexplained generator diff.

## PR22 — Studio responsiveness (separate Mac repository PR)
- See the PTNetworkStudio companion PR and `Docs/Studio_PR21_PR25_Performance_Gates.md`.
- No unmeasured CPU, FPS, or p95 improvements are claimed.

## PR23 — real Network data/presentation boundary
SwiftPM compiles:
```text
PToolsDebugNetworkCore
  PTNetworkCaptureModels.swift   — immutable Sendable contract
  PTNetworkCaptureStore.swift    — authoritative Actor Store
  PTNetworkRedactor.swift        — privacy authority
    ↓
PooToolsDEBUG (UIKit UI, legacy PTHttpDatasource/Model, exporters, adapters)
    ↓
PToolsDebugStudioBridge (explicit, read-only and authorized consumer)
```
`PooToolsDEBUG` excludes the three core source files from its own SwiftPM compilation and re-exports the canonical types via `PTNetworkCaptureCoreExport.swift` for source compatibility. CocoaPods intentionally compiles the same three files **once** inside its existing DEBUG subspec (no second actor or identity domain).

## PR24 — presentation boundary
- Debug panel enumeration now sorts by plugin identifiers rather than nondeterministic dictionary iteration.
- Storage and Inspector snapshot identity were already separated into `PToolsDebugInventoryCore` and `PToolsDebugInspectorCore`. Their native UIKit implementations remain in `PooToolsDEBUG` until the remaining callback/UI dependency graph is validated.

## PR25 — de-duplication / compatibility
- Removed an unused synchronous dump of legacy `PTHttpDatasource` models during Crash UI presentation. The authoritative Network store remains unchanged.
- Added a compile-level test that a client importing only `PooToolsDEBUG` can still resolve `PTNetworkCaptureStore`/`PTNetworkPrivacyPolicy`.
- Added independent actor tests for duplicate IDs, exactly-once finalize, clear and privacy replacements.
- Do not delete `PTHttpDatasource`, `PTHttpModel` or previously published UIKit tools during 5.x; they remain compatibility projections.

## Unverified release gates
1. `swift package dump-package`, SwiftPM tests, Debug+Release iOS simulator builds and Swift 6 concurrency.
2. CocoaPods `pod lib lint`, source parity, generated governance and source API freeze.
3. 7/7 physical iPhone ↔ Mac Network Bridge: TLS trust/pinning, authorization, Bonjour discovery, request/ACK, reset/delete, reconnect, rejected peer.
4. Multi-scene Debug sessions, Storage/Defaults, UIKit Inspector highlight/undo, Metrics recording owner handoff, Debug UI, retention and Core body eviction.
5. No public API, default behavior, hook, swizzle or network request policy regression.

The work remains Draft until all required gates are genuinely verified.
