# JX 到 PTools Paging 迁移指南

5.30.0 移除了交付路径中的 `JXSegmentedView` 和 `JXPagingView` 依赖。PTools 不提供 JX 类型别名，也不要求业务继续导入第三方库；迁移时请按能力改写，而不是只替换类型名。

## 类型映射

| 旧入口 | PTools 入口 |
| --- | --- |
| `JXSegmentedView` | `PTSegmentedView` |
| `JXSegmentedTitleDataSource` | `PTSegmentItem` + `PTSegmentStyle` |
| `JXSegmentedTitleImageDataSource` | `PTSegmentContent.titleImage` |
| `JXSegmentedIndicatorLineView` | `PTLineIndicator` |
| `JXSegmentedListContainerView` | `PTPageContainer` |
| `JXPagingView` | `PTPagingView` |
| `JXPagingSmoothView` | `PTPagingView` 的嵌套滚动协调 |
| `JXPagingListContainerView` | `PTPageContainer` |
| `JXPagingViewListViewDelegate` | `PTPage` / `PTScrollablePage` |
| `defaultSelectedIndex` | Coordinator 的稳定 `selectedID` |
| `scrollCallback` | `PTNestedScrollCoordinator` 和生命周期回调 |
| `reloadDataWithoutListContainer` | 独立调用 `apply(items:)` / `apply(pages:)` |

## 推荐迁移顺序

1. 给业务 Tab 和页面分配稳定 ID。
2. 用 `PTSegmentItem` 替换旧 DataSource Model。
3. 先单独验证 `PTSegmentedView`，再加入 `PTPageContainer`。
4. 有 Header 或嵌套滚动时使用 `PTPagingView`。
5. 页面需要提供明确滚动对象时实现 `PTScrollablePage`。
6. 在真实宿主中验证导航返回、刷新、横竖屏、Dynamic Type、RTL 和多 Scene。

## 示例

```swift
@MainActor
let segmented = PTSegmentedView(frame: .zero)
let pages = [
    PTPageDescriptor(id: "home") { HomeViewController() },
    PTPageDescriptor(id: "orders") { OrdersViewController() }
]
let items = [
    PTSegmentItem.title(id: "home", "首页"),
    PTSegmentItem.title(id: "orders", "订单")
]
let pageContainer = PTPageContainer(frame: .zero)
let coordinator = PTSegmentedPagingCoordinator(segmentedView: segmented,
                                               pageContainer: pageContainer)
coordinator.apply(items: items, pages: pages)
```

旧公开 PTools 兼容模型至少保留一个完整版本周期，但新代码不应再依赖旧 JX 语义或索引驱动状态。
