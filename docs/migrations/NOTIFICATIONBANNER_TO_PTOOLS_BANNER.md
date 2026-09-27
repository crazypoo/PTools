# NotificationBannerSwift → PooToolsBanner 迁移指南

`PTools 5.29.0` 移除了 NotificationBannerSwift 和 MarqueeLabel，新增原生 UIKit
`PToolsOverlay` 与 `PooToolsBanner`。最低支持 iOS 17、Swift 6。

## 入口映射

| 旧入口 | 新入口 |
|---|---|
| `NotificationBanner` | `PTBanner` + `PTBannerLayoutMode.standard` |
| `GrowingNotificationBanner` | `PTBanner` + `.growing` |
| `FloatingNotificationBanner` | `PTBanner` + `.floating` |
| `StatusBarNotificationBanner` | `PTBanner` + `.compact` |
| `BannerStyle` | `PTBannerStyle` |
| `BannerHaptic` | `PTBannerHaptic` |
| `NotificationBannerQueue` | `PTBannerCenter` + `PTBannerQueueConfiguration` |
| `show()` | `PTBannerCenter.shared.show(...)` |
| `dismiss()` | `PTBannerHandle.dismiss()` |
| `autoDismiss` | `PTBannerDuration` |
| `onSwipeUp` | Banner 根据顶部/底部位置自动处理滑动方向 |

## 基础展示

```swift
let handle = PTBannerCenter.shared.show(
    .success(title: "保存成功", subtitle: "数据已同步")
)

handle.dismiss()
```

## Growing / Attributed

```swift
var configuration = PooToolsBannerConfiguration()
configuration.layoutMode = .growing
configuration.duration = .seconds(4)

let banner = PTBanner(
    content: PTBannerContent(
        title: .string("同步完成"),
        subtitle: .attributed(NSAttributedString(string: "查看详情"))
    ),
    style: .info,
    configuration: configuration
)
PTBannerCenter.shared.show(banner)
```

## Queue / Priority / Update

```swift
PTBannerCenter.shared.queueConfiguration = PTBannerQueueConfiguration(
    maxVisibleCount: 3,
    maxQueueCount: 20,
    deduplication: .byContent(window: 2),
    overflow: .dropOldest
)

let loading = PTBannerCenter.shared.show(.loading("正在上传"))
loading.update(.success(title: "上传完成"))
```

## UIViewController 便捷入口

```swift
self.showBanner(.warning(title: "网络较慢"))
```

`UIViewController.drop` 作为旧 Core 兼容入口继续保留，但新代码不应再依赖它获得
Banner 样式。
