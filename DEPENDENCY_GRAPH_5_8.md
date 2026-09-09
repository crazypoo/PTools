# PTools 5.8 依赖图和边界

## 当前事实

当前 SwiftPM 有 81 个 target，`ptools` 有 18 个直接第三方依赖；CocoaPods 有 96 个 subspec，默认 subspec 为 `Core`。完整图由以下报告自动生成：

- `report/spm_dependency_graph.json`
- `report/cocoapods_subspec_graph.json`
- `report/module_parity_5_8.json`
- `report/dependency_direction_5_8.json`

## 5.8 边界规则

- Core 不依赖本地 feature target。
- Permission target 在真正的 PermissionCore 拆分完成前，依赖关系保持显式并记录迁移原因。
- MediaViewer、PhotoPicker 不新增对具体 Network 实现的依赖；现有历史边由白名单登记。
- Navigation / Router 不依赖 PhotoPicker。
- UIFoundation 不依赖 PhotoKit、AVFoundation、Network 或具体调试实现。

## 当前例外

依赖方向门禁当前报告 118 条内部边，其中 2 条是已登记的历史迁移边：MediaViewer → Network、PhotoPicker → Network。它们不是新依赖，5.8.7 迁移完成后应删除白名单。

## 维护规则

修改 Package.swift、PooTools.podspec 或 target 依赖后，必须重新运行 `bash Scripts/generate_58_reports.sh` 和 `bash Scripts/validate_58_contracts.sh --check`。报告中的 baseline 漂移必须经过 review，不得直接刷新来掩盖依赖变化。
