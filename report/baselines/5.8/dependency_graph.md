# PTools 5.8 依赖图和边界

## 当前事实

当前 SwiftPM 已增加独立的 `PToolsCore`、`PToolsUIFoundation`、`PToolsPermissionCore` 和 `PToolsPermissionUI` target；Permission Core 不依赖第三方，Permission UI 只依赖 Core/UIFoundation。各系统权限 target 直接依赖 Permission Core，`ptools` 仍保留兼容 umbrella。CocoaPods 有 96 个 subspec，默认 subspec 为 `Core`。完整图由以下报告自动生成：

- `report/spm_dependency_graph.json`
- `report/cocoapods_subspec_graph.json`
- `report/module_parity_5_8.json`
- `report/dependency_direction_5_8.json`

## 5.8 边界规则

- Core 不依赖本地 feature target。
- SwiftPM Permission target 只依赖 `PToolsPermissionCore` 和对应系统框架；旧 CocoaPods/Xcode 权限源集保留 `ptools` 兼容链，直到独立 framework membership 完成。
- `PToolsPermissionUI` 只依赖 `PToolsPermissionCore` 与 `PToolsUIFoundation`，不得反向依赖 `ptools`、Network 或媒体模块。
- MediaViewer、PhotoPicker 不新增对具体 Network 实现的依赖；现有历史边由白名单登记。
- Navigation / Router 不依赖 PhotoPicker。
- UIFoundation 不依赖 PhotoKit、AVFoundation、Network 或具体调试实现。
- `ptools` 可以依赖 `PToolsCore` 和 `PToolsUIFoundation`；这两个依赖是基础分层，不属于 feature target。

## 当前例外

依赖方向门禁当前报告的内部边数以生成报告为准；历史媒体边 MediaViewer → Network、PhotoPicker → Network 仍单独登记。Permission Core/UI 的新边不属于历史例外，Permission UI 反向依赖 legacy `ptools` 会直接违反门禁。

## 维护规则

修改 Package.swift、PooTools.podspec 或 target 依赖后，必须重新运行 `bash Scripts/generate_58_reports.sh` 和 `bash Scripts/validate_58_contracts.sh --check`。报告中的 baseline 漂移必须经过 review，不得直接刷新来掩盖依赖变化。
