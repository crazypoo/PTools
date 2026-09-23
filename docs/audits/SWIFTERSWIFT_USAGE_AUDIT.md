# SwifterSwift 使用审计

审计基线：PTools `5.22.2` 的迁移前工作区，交付目标：`5.23.0`，平台：iOS 17+ / Swift 6。

## 结论

当前仓库的 SwifterSwift 依赖主要来自三类：

1. Category 和 UI 文件直接导入模块；
2. `RateView`、`Picker` 在 SwiftPM 中声明了直接依赖；
3. 若干模块通过 PTools 已有 Category 或同一功能 target 间接使用扩展能力。

本轮只独立实现 PTools 实际需要的能力，不复制 SwifterSwift 源码。直接复制或实质改编的代码不纳入本轮，因此不产生新的第三方代码版权文件；迁移参考仍在 [`SWIFTERSWIFT_TO_PTOOLS.md`](../migrations/SWIFTERSWIFT_TO_PTOOLS.md) 中记录。

## 真实调用映射

| 文件/模块 | 使用能力 | PTools 处理 | 状态 |
| --- | --- | --- | --- |
| `PooToolsSource/Category/Array+PTEX.swift` | 去重、排序、safe subscript | `Sequence+PTEX`、`Collection+PTEX`、Array 安全入口 | 已迁移 |
| `PooToolsSource/Category/String+PTEX.swift` | `charactersArray`、`trimmed` | PTools 原生 String 扩展；时间能力继续由 SwiftDate 专项管理 | 已迁移 |
| `PooToolsSource/Category/Date+PTEX.swift` | 日期格式和解析附近的扩展可见性 | 移除直接导入，保留 SwiftDate 现有职责 | 已迁移 |
| `PooToolsSource/Category/UIImage+PTEX.swift` | 图片处理扩展可见性 | 移除直接导入，复用 PTools 现有实现 | 已迁移 |
| `PooToolsSource/Category/UIView+PTEX.swift` | `addSubviews`、父控制器、第一响应者、RTL | 新增 PTools UIKit helper，明确 `@MainActor` | 已迁移 |
| `PooToolsSource/RateView/PTRateView.swift` | `addSubviews`、`removeSubviews` | 使用 `addSubviews` 和 `removeAllSubviews` | 已迁移 |
| `PooToolsSource/Picker` | UI 添加和基础 Category 能力 | 使用 Core 的 PTools Category，并移除直接第三方导入 | 已迁移 |
| `PooToolsSource/MediaViewer/PTMediaBrowserCell.swift` | `removeGestureRecognizers` | 改为 `removeAllGestureRecognizers` | 已迁移 |
| `PooToolsSource/Inspector` | `isNilOrEmpty`、`trimmed`、StackView helper | 使用 PTools Optional/String；StackView 已由 Inspector 自有实现 | 已核验 |
| 其他 UIKit/Debug/媒体模块 | `addSubviews`、`emojiToImage`、`.appfont` 等 | `emojiToImage`、`.appfont` 属于 PTools；`addSubviews` 由 UIView+PTEX 提供 | 已迁移，等待完整构建核验 |

## 直接导入清单

以下文件在审计起点直接 `import SwifterSwift`，移除工作必须逐文件完成并经过 Xcode 编译：

```text
PooToolsSource/ActionsheetAndAlert/
PooToolsSource/Animation/
PooToolsSource/AppDelegate/
PooToolsSource/ApplicationFunction/
PooToolsSource/BankCard/
PooToolsSource/Base/
PooToolsSource/Button/
PooToolsSource/C7Collector/
PooToolsSource/CallMessageMail/
PooToolsSource/Category/
PooToolsSource/CheckUpdate/
PooToolsSource/Core/
PooToolsSource/DEBUGLocation/
PooToolsSource/DarkMode/
PooToolsSource/Debug/
PooToolsSource/DebugColor/
PooToolsSource/DebugCrash/
PooToolsSource/DebugFile/
PooToolsSource/DebugLibs/
PooToolsSource/DebugNetwork/
PooToolsSource/DebugPerformance/
PooToolsSource/DebugRuler/
PooToolsSource/DebugUserDefault/
PooToolsSource/DevMask/
PooToolsSource/Guide/
PooToolsSource/HeartRate/
PooToolsSource/ImageEditor/
PooToolsSource/Input/
PooToolsSource/Label/
PooToolsSource/LaunchTimeProfiler/
PooToolsSource/LocalConsole/
PooToolsSource/Log/
PooToolsSource/MediaViewer/
PooToolsSource/MessageKit/
PooToolsSource/NetWork/
PooToolsSource/PermissionCore/
PooToolsSource/PhotoPicker/
PooToolsSource/Picker/
PooToolsSource/QRCodeScan/
PooToolsSource/RateView/
PooToolsSource/ScrollBanner/
PooToolsSource/SegmentControl/
PooToolsSource/Segmented/
PooToolsSource/Share/
PooToolsSource/SideMenuControl/
PooToolsSource/SignView/
PooToolsSource/Stepper/
PooToolsSource/VideoEditor/
PooToolsSource/WhatsNewsKit/
```

## 需要重点防回归的能力

| 能力 | 原因 | 新入口 |
| --- | --- | --- |
| 保序去重 | 旧实现每次重新映射结果，数据量增长时为 O(n²) | `removingDuplicates(by:)` |
| 安全下标 | Array 和 Collection 曾有重复实现 | `Collection[safe:]` |
| 深层字典读写 | 动态 `Any` 入口容易失效且不清晰 | `value(at:)` / `setValue(_:at:)` |
| JSON | 多个旧名字和不同默认选项并存 | `jsonData(options:)` / `jsonString(options:)` |
| URL query | 不允许复制 force unwrap 实现 | `queryItems` / `queryValue(for:)` / `appendingQueryItems(_:)` |
| UIKit 子 View | 大量业务代码依赖第三方 `addSubviews` | `addSubviews` / `removeAllSubviews` |

## 依赖与结果门禁

```bash
rg -n "import SwifterSwift|SwifterSwift" \
  PooToolsSource PooTools Tests Package.swift PooTools.podspec Package.resolved Podfile.lock Scripts/module_registry.json
```

最终交付源码、清单和锁文件必须为零；迁移文档和本审计允许保留名称用于说明历史来源。若 Xcode 输出 `Value of type ... has no member ...`，必须回到调用点补充 PTools API 或改用系统 API，不能恢复依赖作为绕过。
