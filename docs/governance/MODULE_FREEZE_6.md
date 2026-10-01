# Module Freeze 6.0

模块事实来源为 `Scripts/module_registry.json`、`Package.swift`、`PooTools.podspec` 和 `report/current/module_parity.json`。每个模块必须有 source path、SwiftPM product、CocoaPods subspec、依赖、平台和 owner。

允许的差异只有 `INTENTIONAL`、`BUG`、`LEGACY`、`REMOVE_IN_6`；未知漂移必须阻断发布。
