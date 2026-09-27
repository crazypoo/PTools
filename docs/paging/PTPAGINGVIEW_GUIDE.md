# PTPagingView 使用指南

## 页面容器

```swift
@MainActor
let pageContainer = PTPageContainer(frame: .zero)
pageContainer.hostViewController = self
pageContainer.apply(pages: [
    PTPageDescriptor(id: "first") { FirstViewController() },
    PTPageDescriptor(id: "second") { SecondViewController() }
])

let pagingView = PTPagingView(pageContainer: pageContainer)
pagingView.setHeader(PTPagingHeader(height: .fixed(180)) {
    HeaderView()
})
pagingView.setPinnedHeader(PTPagingPinnedHeader(height: 44) {
    PTSegmentedView(frame: .zero)
})
```

## Header

- `PTPagingDimension.fixed` 用于已知高度。
- `automatic` 使用 Auto Layout 测量；异步内容变化后调用 `invalidateHeaderLayout()`。
- `custom` 用于根据宽度计算高度。
- `PTPagingPinnedHeader` 位于安全区下方，并随 Header 折叠进度更新透明度。

## 分段和页面同步

```swift
let coordinator = PTSegmentedPagingCoordinator(
    segmentedView: segmentedView,
    pageContainer: pageContainer
)
coordinator.apply(items: items, pages: pages)
```

两侧必须使用相同的稳定 ID。Coordinator 只做同步，不拥有任一 View；页面与分段 View 的销毁由宿主层级决定。

## 刷新和缓存

`PTRefreshAdapter` 只定义刷新契约，`PTUIRefreshAdapter` 提供系统实现。复杂刷新库可以在宿主层实现该协议，并根据 `PTPagingRefreshPolicy` 决定外层、内层或每页独立拥有刷新状态。
