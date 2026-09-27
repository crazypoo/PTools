# Instructions 使用审计

版本：5.32.0

## 结论

- 已移除 CocoaPods 第三方 `Instructions` 依赖；`Podfile.lock` 不再解析该 Pod。
- CocoaPods 保留 `PooTools/Instructions` subspec，但实现来自 `PooToolsSource/Instructions`。
- SwiftPM 新增 `PooToolsInstructions` product/target。
- 现有 `Guide` 和 `WhatsNewsKit` 不迁移到 Coach Mark 语义：前者负责 onboarding/paging，后者负责版本说明。
- `PooToolsSource/VideoEditor` 中的 `AVVideoComposition.instructions` 只是系统视频合成属性，不属于第三方依赖。

## 扫描范围

扫描 `PooToolsSource`、`PooTools`、`Package.swift`、`PooTools.podspec`、`Podfile`、`Podfile.lock`、Scripts 和交付文档，排除迁移说明中的历史名称。

## 保留与迁移映射

| 原入口 | 处理 | 新入口 |
| --- | --- | --- |
| 第三方 `Instructions` / `CoachMarksController` | 删除依赖 | `PTInstructionCenter` |
| 目标注册 | 无第三方 Window | `PTInstructionTargetRegistry` / `UIView.pt_registerInstructionTarget` |
| Coach mark 遮罩 | 复用 Overlay | `PTInstructionMaskView` |
| 引导内容 | 类型化内容 | `PTInstructionContent.message/view/viewController` |

持续门禁：`Scripts/CI/check_instructions_removed.sh` 与 `Scripts/CI/check_instructions_architecture.sh`。
