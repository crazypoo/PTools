# 旧 JX 分段分页场景迁移到 PTools

本教程把 `YDShipOrderControl.swift` 中的“固定分段栏 + 多个订单列表 + 懒加载 + 动态角标 + 外层刷新”迁移到 PTools 5.31.1。PTools 不再暴露第三方类型，页面与分段都使用稳定 ID。

## 1. 组件对应关系

| 旧场景 | PTools 入口 |
| --- | --- |
| `JXSegmentedView` | `PTSegmentedView` |
| `JXSegmentedTitleDataSource` | `[PTSegmentItem]` + `PTSegmentStyle` |
| `JXSegmentedIndicatorLineView` | `PTLineIndicator` |
| `JXPagingView` | `PTPagingView` |
| `JXPagingView.listContainerView` | `PTPagingView.pageContainer` / `listContainerView` |
| `initListAtIndex` | `PTPageDescriptor` 的 `viewController` 工厂 |
| `defaultSelectedIndex` | `pageContainer.select(index:)` 或稳定 ID |
| `listViewDidScrollCallback` | `PTScrollablePage.pageScrollView`，或由 PTools 自动查找页面内 ScrollView |
| `mainTableView.refreshControl` | `pagingView.refreshControl` |
| `listContainerView.scrollView.isScrollEnabled = false` | `pagingView.isListHorizontalScrollEnabled = false` |

## 2. 基础初始化

```swift
@MainActor
final class YDShipOrderControl: PTBaseViewController {
    private let segmentedView = PTSegmentedView(frame: .zero)
    private let pagingView = PTPagingView()
    private var pagingCoordinator: PTSegmentedPagingCoordinator?
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()

        pagingView.hostViewController = self
        pagingView.isListHorizontalScrollEnabled = false
        pagingView.refreshControl = refreshControl
        pagingView.pageContainer.cachePolicy = .adjacent(radius: 1)

        view.addSubview(pagingView)
        pagingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pagingView.topAnchor.constraint(equalTo: view.topAnchor),
            pagingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pagingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pagingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        pagingView.setPinnedHeader(PTPagingPinnedHeader(height: GobalSegmentHeight) {
            self.segmentedView
        })

        refreshControl.addAction(UIAction { [weak self] _ in
            self?.reloadAllOrderLists()
        }, for: .valueChanged)

        pagingCoordinator = PTSegmentedPagingCoordinator(
            segmentedView: segmentedView,
            pageContainer: pagingView.pageContainer
        )

        reloadSegmentAndPages()
    }
}
```

没有头图时不需要伪造 Header，`setPinnedHeader` 会在 `headerHeight == 0` 时直接显示分段栏；有头图时再调用 `setHeader`，固定分段栏会随外层滚动折叠到安全区下方。

## 3. 用稳定 ID 生成分段和页面

不要使用标题、带角标的显示文本或数组索引作为长期 ID。角标变化只更新 `content`，不能让 Diffable 认为页面换了。

```swift
private func reloadSegmentAndPages() {
    let models = orderModels

    let items = models.map { model in
        PTSegmentItem.title(
            id: model.id,
            model.name,
            badge: model.badge > 0
                ? PTSegmentBadge(text: String(model.badge))
                : nil
        )
    }

    let pages = models.map { model in
        PTPageDescriptor(id: model.id) { [weak self] in
            let controller = YDShipOrderListViewController(
                segmentModel: model,
                listType: self?.orderType ?? .CN
            )
            controller.reloadMainListCallback = { [weak self] in
                self?.reloadAllOrderLists()
            }
            return controller
        }
    }

    pagingCoordinator?.apply(items: items, pages: pages, animated: false)
}
```

`PTSegmentedPagingCoordinator.apply` 会优先保留当前选中的稳定 ID。订单数量刷新、语言刷新和网络重载不会无故跳回第一个列表。

## 4. 导航栏和选中回调

旧代码把 `currentSegIndex` 和导航返回手势逻辑放在 `didSelectedItemAt` 中。新代码可以使用类型化事件：

```swift
segmentedView.onItemSelected = { [weak self] index, origin in
    guard let self else { return }
    self.currentSegmentIndex = index

    if origin == .tap {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = index == 0
    }
}

segmentedView.onScrolling = { [weak self] _, _, _ in
    guard let self else { return }
    PTNavigationBarManager.shared.restoreIfNeeded(for: self)
}
```

如果只关心最终选中项，使用 `onSelectionChanged`；如果需要像旧代理一样区分点击、横向滑动和重复点击，使用 `onItemSelected` 与 `onReselected`。

## 5. 页面滚动、刷新和返回顶部

页面是 `UIViewController` 时直接使用 `PTPageDescriptor(viewController:)`。PTools 会维护 child containment、懒加载和页面生命周期，并递归寻找页面内部的 `UIScrollView`。复杂页面可以显式实现 `PTScrollablePage`，返回真正用于列表滚动的 ScrollView。

```swift
pagingView.scrollCurrentPageToTop(animated: true)

// English: End the outer refresh after the host finishes reloading the header or pages.
// Español: Finaliza el refresco exterior cuando el host termina de recargar la cabecera o las páginas.
// 中文：宿主完成 Header 或页面刷新后结束外层刷新。
pagingView.refreshControl?.endRefreshing()

// English: Access the current list for per-page refresh, pagination or custom coordination.
// Español: Accede a la lista actual para refresco por página, paginación o coordinación personalizada.
// 中文：获取当前列表，用于单页刷新、分页加载或自定义协调。
let currentList = pagingView.pageContainer.currentPageScrollView
```

外层刷新和页面自己的刷新状态应分开管理；不要把同一个 `UIRefreshControl` 同时安装到外层和每个内层列表。页面需要独立下拉刷新时，使用页面自己的刷新控件，并把外层策略设置为 `.perPage` 或由宿主自行协调。

## 6. 手势协作

不要替换 `UIScrollView.panGestureRecognizer` 的系统 delegate。宿主如果有自定义手势 delegate，在已有代理回调中转发：

```swift
func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                       shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    pagingView.shouldRecognizeSimultaneously(
        gestureRecognizer,
        otherGestureRecognizer
    )
}
```

PTools 默认允许横向分页、垂直列表和导航返回之间进行必要的同时识别，并且所有嵌套偏移修正都考虑 `adjustedContentInset`。这避免了旧代码中直接操作内部列表代理后丢失业务回调的问题。

## 7. 动态数据和页面回收注意事项

- 更新角标时重新生成 `PTSegmentItem`，保持 `id` 不变。
- 更新页面数组时使用 `coordinator.apply`，不要手动删除当前页面 View。
- 默认 `.adjacent(radius: 1)` 只保留当前页和相邻页；需要保持全部页面状态时改为 `.keepAllLoaded`。
- 页面实现 `PTPageLifecycleObserving` 可以接收 `willLoad`、`didLoad`、`willAppear`、`didAppear`、`willDisappear`、`didDisappear` 和 `didUnload`。
- iOS 17+ 横竖屏、Dynamic Type、RTL、Reduce Motion、多 Scene 和真实刷新库仍应在宿主 App 中回归。
