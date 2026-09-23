# PTools 5.25.0 富文本依赖吸收审计

## 结论

5.25.0 已将 `lixiang1994/AttributedString` 从 SwiftPM、CocoaPods、`Package.resolved`、
`Podfile.lock` 和生产源码移除。当前唯一实现入口是
`PooToolsSource/PToolsUIFoundation/PTRichText.swift`，公开值模型为 `PTRichText`。

## 迁移边界

| 原使用面 | 5.25.0 处理 | 结果 |
| --- | --- | --- |
| `ASAttributedString` 属性和参数 | 替换为 `PTRichText` | 由 Foundation `AttributedString` 存储 |
| `.attributed.text` UIKit 辅助 | 替换为 `PTRichText.value` / `PTRichTextRenderer` | 显式桥接，避免隐藏第三方扩展 |
| Font、颜色、段落、下划线 | `PTTextAttribute` 和 `PTTextStyle` | 支持 keep-existing、keep-new、replace-all |
| 插值和拼接 | `ExpressibleByStringInterpolation`、`+`、`+=` | 保留富文本片段的值语义 |
| Range、正则、链接、日期检测 | `PTRichText.validatedNSRange`、`matches` | 非法 UTF-16 边界安全返回空结果 |
| Action 闭包 | Button、Header、MediaViewer 显式 UI 回调；新代码可用 `PTTextActionRegistry` | 闭包不进入 Sendable 值模型 |
| Attachment / 图片加载 API | `PTTextAttachmentDescriptor`、`PTTextAttachmentCoordinator`、`PTTextAttachmentViewProvider` 和 `PTTextImageLoader` | 支持图片、Data、文件、远程加载、取消、注入 View Provider 和失败策略；View 仍只在 MainActor 创建 |

## 调用点分类

### 纯展示值

- `Base/PTFusionCellModel.swift`
- `Base/PTUnavailableFunction.swift`
- `ScrollBanner/PTBannerModel.swift`
- `Stepper/PTStepperView.swift`
- `WhatsNewsKit/PTWhatsNewsViewController.swift`
- `Search/PTSearchViewController.swift`
- `PhotoPicker/PTMediaLibCell.swift`
- `PermissionCore/PTPermissionCell.swift`
- `MessageKit` 文本和系统消息 Cell

这些调用点只保存不可变富文本值，UI 更新时通过 `value` 桥接到 UIKit。

### 交互文本

- `Button/PTLoginDescButton.swift`
- `Button/PTActionLayoutButton.swift`
- `Base/PTHeaderAndFooter.swift`
- `MediaViewer/PTMediaBrowserBottom.swift`
- `MediaViewer/PTMediaBrowserController.swift`

这些调用点不再依赖文本属性中的闭包。按钮、手势或控制器回调负责执行行为，文本只负责样式和内容。

## 依赖验证

- SwiftPM `ptools` 和 `PooToolsSearch` 不再声明第三方富文本包。
- CocoaPods `Core` 和 `Search` 不再声明第三方富文本包。
- `Podfile.lock` 不再包含 `AttributedString`。
- 生产目录 `PooToolsSource` 和示例目录 `PooTools` 不再包含 `import AttributedString` 或 `ASAttributedString`。
- 历史 API baseline、旧版本报告和 changelog 中的旧类型记录保留为历史事实，不作为当前依赖使用。

## 后续约束

1. 新 UI 只能使用 `PTRichText` 或 UIKit 原生富文本类型，不得重新引入第三方富文本包。
2. 跨 actor 传递富文本时只传 `PTRichText`、`String` 或明确的 Foundation 值快照。
3. 需要点击、长按或异步图片时，通过 `PTTextActionRegistry`、控件回调、`PTTextAttachmentCoordinator` 或专用渲染器处理，不把闭包写入文本存储。
4. 5.26.x 再评估将 UIKit 样式描述拆为纯 Foundation Core 与 UIKit Renderer 两个更小层；5.25.0 保持现有模块路径和调用方式稳定。
