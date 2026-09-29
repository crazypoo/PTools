# JX 到 PTools Paging 迁移指南

5.30.0 移除了交付路径中的 `JXSegmentedView` 和 `JXPagingView` 依赖；当前实现继续收口真实业务迁移中的
Badge 宽度、Indicator 坐标、稳定 ID 和手势语义。PTools 不提供 JX 类型别名，也不要求业务继续导入第三方库；
迁移时请按能力改写，而不是只替换类型名。

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
| `defaultSelectedIndex` | Coordinator 的稳定 `selectedID` / `PTPageContainer.select(index:)` |
| `scrollCallback` | `PTNestedScrollCoordinator` 和生命周期回调 |
| `reloadDataWithoutListContainer` | 独立调用 `apply(items:)` / `apply(pages:)` |
| `isListHorizontalScrollEnabled` | `PTPagingView.isListHorizontalScrollEnabled` |
| `mainTableView.refreshControl` | `PTPagingView.refreshControl` |
| `JXPagingMainTableViewGestureDelegate` | 宿主转发 `PTPagingView.shouldRecognizeSimultaneously(_:_:)` |

## 推荐迁移顺序

1. 给业务 Tab 和页面分配稳定 ID。
2. 用 `PTSegmentItem` 替换旧 DataSource Model。
3. 先单独验证 `PTSegmentedView`，再加入 `PTPageContainer`。
4. 有 Header 或嵌套滚动时使用 `PTPagingView`。
5. 页面需要提供明确滚动对象时实现 `PTScrollablePage`。
6. 在真实宿主中验证导航返回、刷新、横竖屏、Dynamic Type、RTL 和多 Scene。

## 5.31.1 行为补齐

- `PTSegmentedPagingCoordinator` 使用内部观察者，不会覆盖业务设置的 `onSelectionChanged` 和 `onTransition`。
- `PTPageContainer.apply(pages:)` 在角标、标题或页面描述更新时保留当前稳定 ID，不会无故回到第一个列表。
- 页面回收会完整发送 `willDisappear`、`didDisappear` 和 `didUnload`；UIViewController 页面会转发 appearance 生命周期。
- 外层和内层滚动统一按 `adjustedContentInset` 计算，适配自定义 `contentInset` 与安全区。
- `PTSegmentedView` 的 Indicator 位于 Cell 之上，反向分页同样会产生过渡进度。
- Segment 标题条横向滚动只负责浏览和 Indicator viewport 投影，不会像旧的“滚到中心即选择”逻辑那样切换业务页面。
- `PTSegmentStyle` 的 intrinsic/adaptive 宽度会计入 Badge、选中字体、选中缩放和实际图片尺寸。
- `PTSegmentIndicatorContext` 的 `itemFrames` 与 `contentFrames` 都使用 viewport 坐标；`fixed`、`item`、`content` 和自定义 placement 均可组合。
- 无 placeholder 的 `imageSource` / `titleImageSource` 会保留图片槽位，网络图片加载完成后能正确显示。

## JX 四项视觉开关

| JX 配置 | PTools 兼容开关 | 规范配置 |
| --- | --- | --- |
| `isTitleColorGradientEnabled` | `style.isTitleColorGradientEnabled` | `titleColorTransition` |
| `isTitleZoomEnabled` | `style.isTitleZoomEnabled` | `titleZoomTransition` + `selectedScale` |
| `isSelectedAnimable` | `style.isSelectedAnimable` | `selectionTransition` + `selectionAnimationDuration` |
| `isItemSpacingAverageEnabled` | `style.isItemSpacingAverageEnabled` | `spacingDistribution` |

平均间距不会把 Item 改成等宽：它先按标题、选中字体、图片、角标和 Insets 计算真实宽度，
再只增加 Item 之间的内部 Gap。`distribution = .equal` 仍然独立控制等宽，关闭平均间距后也不会
偷偷改变原来的 Width Policy。

## 角标迁移

```swift
var badgeConfiguration = PTBadgeConfiguration()
badgeConfiguration.maximumNumber = 99
badgeConfiguration.borderWidth = 1
badgeConfiguration.canDragToDelete = true

let item = PTSegmentItem.title(
    id: "orders",
    "订单",
    badgeDescriptor: PTSegmentBadgeDescriptor(
        content: .number(120),
        configuration: badgeConfiguration
    )
)
```

`PTBadgeContent.redDot`、`.number` 和 `.text` 分别对应红点、数字（自动显示 `99+`）和文本。
`PTBadgeAnimType`、Reduce Motion、自动圆角、边框以及拖拽删除均来自 Core Badge；删除回调通过
`PTSegmentedView.onBadgeRemoved` 通知业务，业务更新稳定 ID 对应的数组后重新 `apply(items:)`。
旧 `PTSegmentBadge` 仍可用，但只是兼容桥接，不再继续扩展第二套角标逻辑。

官方 JX 组件仍有一个需要在迁移时明确处理的手势边界：当横向分页容器持续参与手势识别时，列表 Cell 的侧滑操作可能失效（见 [JXSegmentedView Issue #303](https://github.com/pujiaxin33/JXSegmentedView/issues/303)）。PTools 默认只允许外层、当前内层和分页 ScrollView 的必要协作，不把无关 Pan 手势全部设为 simultaneous；需要列表侧滑时应保持 `isListHorizontalScrollEnabled = false`，或只在宿主确认不会与 Cell 手势冲突时打开更宽松的手势策略。

对应旧业务的完整示例见 [YDShipOrder PTools Paging 教程](YD_SHIP_ORDER_PTOOLS_PAGING_TUTORIAL.md)。

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
