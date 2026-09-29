# PTSegmentedView 使用指南（5.57.3）

## 基础标题

```swift
@MainActor
let segmentedView = PTSegmentedView(frame: .zero)
segmentedView.style = PTSegmentStyle(distribution: .adaptive)
segmentedView.apply(items: [
    .title(id: "home", "首页"),
    .title(id: "profile", "我的", badgeDescriptor: PTSegmentBadgeDescriptor(content: .number(3)))
])
segmentedView.onSelectionChanged = { event in
    print(event.newSelection.selectedID as Any)
}

// English: Receive final selections by origin when migrating from a delegate.
// Español: Recibe la selección final por origen al migrar desde un delegate.
// 中文：从旧 delegate 迁移时，可以按来源接收最终选中项。
segmentedView.onItemSelected = { index, origin in
    print(index, origin)
}
segmentedView.onReselected = { index in
    print("reselected", index)
}
```

## 图片、富文本和自定义内容

`PTSegmentContent` 支持 `title`、`image`、`titleImage`、`attributed`、`imageSource`、`titleImageSource` 和 `custom`。网络图片由 PTools 图片入口加载，Cell 复用时取消旧任务并校验资源身份。

```swift
let item = PTSegmentItem.titleImage(
    id: "photos",
    title: "图片",
    image: UIImage(systemName: "photo")!,
    placement: .leading
)
segmentedView.apply(items: [item])
```

## Indicator

可组合 `PTLineIndicator`、`PTStretchLineIndicator`、`PTDotIndicator`、`PTDoubleLineIndicator`、`PTTriangleIndicator`、`PTBackgroundIndicator`、`PTGradientIndicator` 和 `PTImageIndicator`。Indicator 通过 `PTSegmentIndicator` 协议接收选中与过渡状态，不需要依赖第三方类型。

```swift
segmentedView.indicators = [
    PTLineIndicator(color: .systemBlue, height: 2, widthPolicy: .content)
]
```

`PTSegmentedView` 会把 Segment Cell 的布局属性转换到自身的 viewport 坐标系后再交给
Indicator。`item` 使用整个 Cell 宽度，`fixed` 使用指定宽度，`content` 使用标题或图片主体
区域的真实宽度；`placement: .custom` 收到的也是 viewport 中的 Cell frame。

Badge 的文字、内边距、圆点和 normal/selected 字体都会参与 Item 宽度测量。更新同一个稳定 ID
的标题或 Badge 时，重新调用 `apply(items:)` 即可，页面选择不会因为显示文本变化而丢失。

## 选择和更新

- 使用 `select(id:)` 进行程序化选择。
- 使用稳定 ID 调用 `apply(items:)`，支持增删移动。
- `allowsReselect` 控制重复点击行为。
- `onTransition` 只描述相邻页面之间的进度，不作为业务数据源。
- Segment 标题条的横向拖动只改变标题 viewport 和 Indicator 几何位置，不会自动改变业务选择或页面。
- `select(id:animated:)` 是程序化选择入口；开启 Reduce Motion 时会自动取消滚动动画。
- RTL、Dynamic Type、Reduce Motion 和无障碍名称应由宿主在真实页面中回归验证。
- Indicator 会位于分段 Cell 之上；`PTSegmentedView` 会保留稳定 ID，不要使用带角标的显示文本作为 ID。
- `imageSource` 与 `titleImageSource` 即使没有 placeholder 也会预留图片位置，下载完成后自动更新。

## JX 视觉迁移配置

`PTSegmentStyle` 提供 JX 常用的四项兼容开关，同时保留枚举作为规范入口：

```swift
var style = PTSegmentStyle(distribution: .adaptive,
                           selectedScale: 1.12,
                           titleColorTransition: .gradient,
                           titleZoomTransition: .selectedScale,
                           selectionTransition: .animated,
                           spacingDistribution: .averageWhenPossible)
style.isTitleColorGradientEnabled = true
style.isTitleZoomEnabled = true
style.isSelectedAnimable = true
style.isItemSpacingAverageEnabled = true
segmentedView.style = style
```

- `titleColorTransition` 只由分页 `PTSegmentTransition` 驱动，动态颜色会先按当前 Trait 解析再插值。
- `titleZoomTransition` 只缩放标题，不缩放角标、图片或整个 Cell；`selectedScale` 继续作为缩放比例。
- `selectionTransition` 控制点击和程序选择动画；分页交互始终直接使用 progress，快速点击时最后一次选择优先。
- `spacingDistribution = .averageWhenPossible` 保留真实 Item 宽度，只在容器有剩余空间时平均增加内部 Gap；放不下时恢复 `itemSpacing` 并允许横向滚动。

## 类型化角标

新代码使用 `PTSegmentBadgeDescriptor`，角标尺寸、`99+`、边框、圆角、动画、Reduce Motion
和拖拽删除均复用 Core Badge：

```swift
var badge = PTBadgeConfiguration()
badge.animType = .scale
badge.canDragToDelete = true
badge.maximumNumber = 99

let item = PTSegmentItem.title(
    id: "orders",
    "订单",
    badgeDescriptor: PTSegmentBadgeDescriptor(content: .number(120), configuration: badge)
)
segmentedView.onBadgeRemoved = { id in
    // 业务方按稳定 ID 更新自己的 items，再调用 apply(items:)，控件不修改数据源。
}
```

`PTSegmentBadge` 和 `badge:` 参数仍保留为兼容入口，但新代码不要再把数字字符串当作隐含协议。
