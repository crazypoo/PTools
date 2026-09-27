# PTPagingView 使用指南（5.31.1）

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
pagingView.hostViewController = self
pagingView.isListHorizontalScrollEnabled = false
pagingView.setHeader(PTPagingHeader(height: .fixed(180)) {
    HeaderView()
})
pagingView.setPinnedHeader(PTPagingPinnedHeader(height: 44) {
    PTSegmentedView(frame: .zero)
})

let refreshControl = UIRefreshControl()
pagingView.refreshControl = refreshControl
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

## 5.31.1 迁移能力

- `pagingView.listContainerView` 和 `pagingView.mainScrollView` 是迁移期的命名适配入口；新代码优先使用 `pageContainer` 和 `outerScrollView`。
- `pagingView.pageContainer.select(index:)` 等价于旧的默认索引选择；动态 `apply` 会保留当前稳定 ID。
- `pagingView.scrollCurrentPageToTop()` 支持状态栏回顶和业务主动回顶。
- `pagingView.shouldRecognizeSimultaneously(_:_:)` 可在宿主已有手势代理中复用，不能替换 UIKit 自己管理的 ScrollView pan delegate。
- 内层列表可以实现 `PTScrollablePage` 显式提供 ScrollView；未实现时 PTools 会递归查找页面层级中的第一个 ScrollView。
- `gestureArena` 默认只允许分页所需的 ScrollView 协作，不会让所有 Pan 手势同时识别；需要列表 Cell 侧滑时，保持 `isListHorizontalScrollEnabled = false`。
