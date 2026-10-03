# PTools 5.60 Swift 6 Concurrency Exception Audit

<!-- English: Every retained exception has a narrow boundary, a protection mechanism, and a removal or replacement plan. -->
<!-- Español: Cada excepción conservada tiene un límite estrecho, una protección y un plan de reemplazo o eliminación. -->
<!-- 中文：每个保留的并发例外都有明确边界、保护机制和替换或删除计划。 -->

## Rules

PTools does not use `@unchecked Sendable` as a general compiler escape hatch. The source-level registry and allowlist are validated by:

```text
python3 Scripts/Governance/validate_concurrency_registry.py
```

The audit categories are:

- `SYSTEM_WRAPPER`: PhotoKit, AVFoundation, CoreMotion, MetricKit, Operation, or other SDK reference types crossing a framework callback boundary.
- `LOCK_PROTECTED`: legacy reference types whose mutable state is accessed through a lock.
- `MAIN_ACTOR_ONLY`: UI, lifecycle, or diagnostic state confined to `MainActor`.
- `IMMUTABLE_BRIDGE`: a value snapshot crosses the boundary instead of the original SDK object.
- `SERIAL_CALLBACK`: callbacks are serialized before state is exposed.

## Current high-risk modules

| Module | Boundary decision | Remaining work |
| --- | --- | --- |
| Network | typed request/config snapshots; cache file I/O uses immutable values | migrate legacy dynamic API callers to the typed executor before 6.0 |
| OSSSpeech | lock-protected legacy speech state and MainActor delegate callbacks | replace SDK reference wrappers with value snapshots where Speech APIs permit |
| Motion | CoreMotion callbacks enter a serialized operation queue; public data is a value snapshot | keep the exception narrow and complete the lock-backed state adapter before removing the marker |
| MetricsManager | MetricKit payloads are converted to `Data` before async work; registration lifecycle is lock-protected | keep upload policy separate from MetricKit callback delivery |
| PhotoPicker | PHAsset/Operation boundaries are registered wrappers; picker UI remains MainActor | never pass PHAsset, Progress, UIKit objects, or dynamic dictionaries through a transport actor |
| VideoEditor | AVFoundation compositor/export wrappers are bounded by MainActor, serial queues, and immutable callback data | remove any wrapper when the SDK exposes a Sendable value API |

## Detached task policy

`Task.detached` is permitted only for pure value work or blocking file/JSON operations where the closure captures immutable `Sendable` values. It is not permitted for UI state, `PHAsset`, `AVAsset`, `UIView`, `Progress`, `Any`, or shared mutable configuration. The current cache and export uses are therefore reviewed as file/codec boundaries; new detached uses require a registry entry or must use structured `Task` instead.

## Acceptance evidence

- No production `nonisolated(unsafe)` is present.
- No newly introduced business-level unchecked marker may bypass the registry.
- `MetricsManager` registration state is protected by `NSLock`; MetricKit payload objects are converted to `Data` before asynchronous persistence.
- The allowlist and symbol registry are checked as a pair, including after physical file splits.
