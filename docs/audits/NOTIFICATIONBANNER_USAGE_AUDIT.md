# NotificationBanner / MarqueeLabel 使用审计

## 审计范围

本审计覆盖 `Package.swift`、`Package.resolved`、`PooTools.podspec`、`Podfile.lock`、
`PooToolsSource`、`PooTools`、`Tests` 和构建脚本。

## 结果

| 文件 | 旧 API / 依赖 | 使用场景 | 新入口 | 风险 |
|---|---|---|---|---|
| `PooToolsSource/Category/UIViewController+PTEX.swift` | `FloatingNotificationBanner` | `UIViewController.drop` | `PTBannerCenter` / `showBanner` | 已改为 Core 兼容告警入口，避免 Core 反向依赖 Banner |
| `Package.swift` | `NotificationBannerSwift` | SwiftPM 直接依赖 | `PooToolsBanner` | 已移除 |
| `PooTools.podspec` | `NotificationBannerSwift` | CocoaPods NotificationBanner subspec | `PooTools/Banner` | 已改为兼容别名 |
| `Package.swift` / `Package.resolved` / `Podfile.lock` | `MarqueeLabel` | NotificationBanner 的传递依赖 | Banner 默认增长布局 | 已移除 |

## MarqueeLabel 结论

`PooToolsSource/Label/PTAutoScrollLabel.swift` 是 PTools 自有滚动文本实现，没有导入
`MarqueeLabel`。仓库没有其他直接使用点，因此可以随 NotificationBanner 依赖链一并移除。

## 保留的兼容边界

- CocoaPods 的 `NotificationBanner` subspec 名称暂时保留，但只转发到 `PooTools/Banner`。
- 不提供 `NotificationBanner` 第三方类型别名，避免继续污染公开 API。
- `UIViewController.drop` 保持可编译；新代码应使用 `showBanner` 或
  `PTBannerCenter.shared.show`。

## 验证命令

```bash
rg -n "NotificationBannerSwift|Daltron/NotificationBanner|import NotificationBannerSwift|GrowingNotificationBanner|FloatingNotificationBanner|StatusBarNotificationBanner|NotificationBannerQueue" Package.swift Package.resolved PooTools.podspec PooToolsSource Sources Tests
rg -n "MarqueeLabel|cbpowell/MarqueeLabel" Package.swift Package.resolved PooTools.podspec Podfile.lock PooToolsSource Sources Tests
```

