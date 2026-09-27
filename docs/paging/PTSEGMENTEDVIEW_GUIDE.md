# PTSegmentedView 使用指南

## 基础标题

```swift
@MainActor
let segmentedView = PTSegmentedView(frame: .zero)
segmentedView.style = PTSegmentStyle(distribution: .adaptive)
segmentedView.apply(items: [
    .title(id: "home", "首页"),
    .title(id: "profile", "我的", badge: PTSegmentBadge(text: "3"))
])
segmentedView.onSelectionChanged = { event in
    print(event.newSelection.selectedID as Any)
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

## 选择和更新

- 使用 `select(id:)` 进行程序化选择。
- 使用稳定 ID 调用 `apply(items:)`，支持增删移动。
- `allowsReselect` 控制重复点击行为。
- `onTransition` 只描述相邻页面之间的进度，不作为业务数据源。
- RTL、Dynamic Type、Reduce Motion 和无障碍名称应由宿主在真实页面中回归验证。
