# PTools 5.60 UI / Scene Ownership

<!-- English: This document records the 5.60 singleton migration boundary. -->
<!-- Español: Este documento registra el límite de migración de singletons de 5.60. -->
<!-- 中文：本文档记录 5.60 的 UI / Scene 单例迁移边界。 -->

## Policy

PTools 5.x keeps `shared` / `share` for source compatibility. New code should own mutable UI state at the smallest useful scope:

- `instance-capable`: the caller creates and owns a configuration or service instance.
- `scene-scoped`: one instance belongs to one `UIWindowScene` or navigation tree.
- `process-scoped`: the service represents one process-wide timeline, environment observer, or debug primitive; creating duplicates would produce competing observers or windows.

The complete decision table is the machine-readable [`Scripts/ui_singleton_ownership.json`](../../Scripts/ui_singleton_ownership.json). The gate compares it with `report/current/singletons.json`; a new category-D declaration cannot silently enter the repository without an ownership decision.

## Migration examples

```swift
@MainActor
let navigationManager = PTNavigationBarManager()
let alertManager = PTAlertManager(sceneContextProvider: sceneProvider)
let console = LocalConsole.console(for: windowScene)
let pickerConfig = PTMediaLibConfig()
let pickerStyle = PTPickerStyle()
```

Legacy code may continue to use `PTNavigationBarManager.shared`, `PTAlertManager.shared`, `LocalConsole.shared`, `PTMediaLibConfig.share`, and `PTPickerStyle.shared` during the 5.x compatibility window. The compatibility values must not be used as a temporary cross-scene mutable store in new code.

## Why process-scoped entries remain

`PTDarkModeScheduleMonitor` owns one set of system time/environment observers. `PTLaunchProfiler` describes a process launch timeline. `EntryWindow`, `PTConsoleWindow`, and the color-picker window are debug UI primitives that must not be duplicated by an uncoordinated caller. These entries are documented rather than mechanically made public.

## Verification

```text
python3 Scripts/Governance/validate_ui_singleton_ownership.py
```

The check requires every current category-D declaration to have:

1. an explicit ownership scope;
2. an instance entry point or a documented process-scoped reason;
3. a compatibility policy for the old shared entry;
4. a migration status of `READY` or `DOCUMENTED`.

This is an ownership boundary, not a promise that every global service can be removed in 5.60. The removal window remains `6.0.0` where the public compatibility contract requires it.
