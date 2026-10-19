# PTBannerView 与 PTCollectionView 迁移指南

## 兼容策略

`PTBannerView` 和公开的 `PTCycleScrollView` 类型、构造方法、PageControl、标题/描述、媒体播放、箭头和历史回调继续保留。内部滚动宿主统一为 `PTCollectionView`，不再维护第二个 `UICollectionView`、`count × 100` 数据源或第二套 Timer。

旧代码不需要修改：

```swift
let banner = PTCycleScrollView(frame: .zero)
banner.bannerModel = models
```

新代码仍可直接使用 `PTBannerView`：

```swift
let configuration = PTBannerConfiguration()
configuration.infiniteLoop = true
configuration.autoScroll = true
configuration.autoScrollInterval = 3

let banner = PTBannerView(viewConfig: configuration)
banner.bannerModel = models
```

## 分页和拖动语义

Banner 使用 viewport paging。实际列表启用 `isPagingEnabled`，并隐藏水平、垂直滚动条，避免滚动指示器覆盖媒体内容。

自动轮播状态顺序如下：

1. 用户开始拖动，立即暂停自动轮播。
2. `didEndDragging(willDecelerate: true)` 后仍保持暂停。
3. 没有减速时，在 `didEndDragging` 完成页状态后恢复。
4. 有减速时，在 `didEndDecelerating` 完成页状态后恢复。

手动调用停止入口会覆盖自动恢复，直到调用对应的启动入口。Reduce Motion、离屏和后台状态不会创建新的轮播任务。

## 图片和媒体

`PTBannerModel` 保留 `UIImage`、URL、Data、GIF、`AVAsset`、视频封面和富文本等旧媒体入口。Cell 通过 `cellInCollectionV2` 按逻辑 Row 绑定，物理循环回绕不会把旧 Cell 的异步结果写入新页面。

## 迁移注意

- 不要把无限投影的物理 IndexPath 当作业务数组下标。
- 业务选择优先使用统一的逻辑页回调。
- 如果仅使用旧 `cellInCollection`，无限模式会被安全拒绝；请迁移到稳定的 V2 Provider。
- 普通列表继续使用 `.normal`，不会因为安装新版本而自动分页。

## 平台说明

Banner 是 UIKit iOS 17+ 组件；watchOS、visionOS、macOS 只复用 Core 配置/身份契约，需由各平台宿主提供对应 UI。The public banner API remains source-compatible for iOS 17+ Swift 6 clients. La capa de UIKit es específica de iOS y los adaptadores de otras plataformas deben reutilizar solo los contratos de Core.
