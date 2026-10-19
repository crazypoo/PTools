# PTools 5.67.x SPM / CocoaPods parity baseline

> 这是分发兼容基线，不是“已通过”报告。This is a distribution baseline, not a pass report. Esta es una línea base de distribución, no un informe aprobado.

- `sourceRevision`: `b5898d124c409bcf25ba824e40cdd616cf9284df`
- `version`: `5.67.2`
- `auditDate`: `2026-10-19`
- `status`: `blocked_parity`

## 当前证据 / Current evidence / Evidencia actual

| Area | SwiftPM | CocoaPods | Finding | Decision |
|---|---|---|---|---|
| SnapKit helpers | `PToolsUIFoundation` owns the implementation; aggregate `ptools` enables `POOTOOLS_SPLIT_UIFOUNDATION` and keeps the legacy path out | Core includes the thin Base bridge and depends on `PToolsUIFoundation`; Core defines split UI condition | One implementation is compiled in UIFoundation; Base only provides the compatibility re-export when the flattened legacy path requires it | Aggregate CocoaPods build passed; exported-symbol diff and runtime layout timing matrix remain |
| Permission core | `PToolsPermissionCore` is the standalone Foundation target used by `ptools` and split permission targets | CocoaPods subspecs share one aggregate target, so the same `PToolsPermissionCore` source is embedded once and adapters use the compatibility facade without importing a nonexistent module | One contract owner now supplies both distributions; legacy facade and public nested APIs remain available | Code-level distribution migration complete; runtime/API parity still needs permission-kind regression coverage |
| Network transfer | `PToolsTransferCore` contracts and `PToolsTransfer` foreground executor are separate from the Network adapter | Core embeds TransferCore once and Network keeps the legacy facade while using the shared executor | Foreground Network/audio/video paths now share file execution, retry, range resume and subscriber cancellation; background URLSession delegate and Live Photo remain specialized | Build parity is established; live auth/cookie/protocol-class/background/disk-pressure matrix is still required before marking verified |
| Segment | `SegmentControl` and legacy `Segmented` surfaces coexist | Legacy public symbols remain available | New stable-ID model does not cover every legacy property | Add mapping and event regression before thin adapter |
| HUD/Overlay | Overlay and HUD products are separately assembled | Overlay/Hud subspecs are separately assembled | Host lifecycle can share PTOverlayCore; visual semantics cannot be flattened | Migrate host responsibility one consumer at a time |

## Required parity gates / Puertas requeridas / 必需门禁

1. `Package.swift` target graph and public symbol visibility must be checked independently from CocoaPods subspec assembly.
2. Every compatibility facade must compile in both distributions; a successful aggregate build alone is insufficient.
3. API differences must record symbol, signature, availability, owner target and removal gate in `API_COMPATIBILITY_BASELINE.json`.
4. Platform boundaries must be explicit: Foundation-only code may be assessed for watchOS, visionOS and macOS; UIKit, Speech hardware and iOS background behavior require platform-specific validation.
5. No entry may be marked `migrated` or `verified` until the corresponding runtime test IDs have evidence.

## Existing validators / Existing validation / 现有验证器

- `Scripts/validate_module_parity.sh --check`
- `Scripts/validate_distribution_parity.sh`
- `Scripts/CI/audit_spm_target_graph.py --strict`
- `Scripts/CI/audit_spm_symbol_ownership.py --strict`
- `Scripts/report_public_api.rb`
- `Scripts/compare_public_api.rb`

The current generated `report/current` inventories are historical and are not silently promoted to a 5.67.2 pass. They must be refreshed and reviewed after each implementation work package.
