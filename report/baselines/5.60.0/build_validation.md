# PTools 5.60.0 Build Validation

> English: This report records reproducible workspace evidence and unresolved environment blockers.
>
> Español: Este informe registra evidencia reproducible del workspace y bloqueos de entorno pendientes.
>
> 中文：本文记录可复现的 workspace 构建证据和仍待处理的环境阻断。

## Confirmed

| Entry | Result | Evidence |
| --- | --- | --- |
| Xcode workspace / Simulator / Debug | PASS | `PooTools-Example`, iOS Simulator, arm64, iOS 17 deployment target |
| Xcode workspace / Simulator / Release | PASS | `PooTools-Example`, iOS Simulator, arm64, iOS 17 deployment target |
| Package manifest | PASS | `swift package dump-package` |
| Build entries | PASS | `Scripts/validate_build_entries.sh` |
| Quality scans | PASS | `Scripts/validate_quality_scans.sh` |
| Current report freshness | PASS | `Scripts/Governance/generate_all_current_reports.sh --check` |
| Deprecated / concurrency / singleton governance | PASS | Individual validators pass; aggregate governance reaches the external SwiftPM test gate |

## Environment blockers

The SwiftPM test products cannot run because the existing checkout contains two different recorded revisions for Kakapos 1.1.0:

```text
Revision 64ef17d978700cbe5d1168be7e57561a4459feee
does not match previously recorded value
fe1e46ce27546d9436d5a1cc4ba68342eee29c0f
```

This report intentionally does not modify `Package.resolved`, dependency versions, or third-party source to bypass the conflict.

## Still required before the formal tag

- CocoaPods lint for the final podspec and selected subspecs.
- A real host exercising root, `$.data`, list, deep-path, nested-model and diagnostic failures.
- Physical-device multi-scene, permission, media and navigation runs.
- Long-session and PTInstruments CPU, memory, FPS, hitch and main-thread-stall traces.

The current version remains a development baseline; no `5.60.0` tag is created by this change.

## CocoaPods lint evidence

> English: `pod lib lint PooTools.podspec --no-clean --allow-warnings --skip-tests` was attempted on 2026-10-03. CocoaPods repeatedly entered temporary Release builds and the run was cancelled after no conclusive PASS/FAIL result; this is intentionally recorded as pending, not as a pass.
>
> Español: Se intentó `pod lib lint PooTools.podspec --no-clean --allow-warnings --skip-tests` el 2026-10-03. CocoaPods repitió compilaciones Release temporales y la ejecución se canceló sin un resultado PASS/FAIL concluyente; se registra como pendiente y no como aprobado.
>
> 中文：已于 2026-10-03 尝试执行 `pod lib lint PooTools.podspec --no-clean --allow-warnings --skip-tests`。CocoaPods 反复进入临时 Release 构建，未得到明确 PASS/FAIL 前主动取消；这里明确记录为待完成，不计为通过。
