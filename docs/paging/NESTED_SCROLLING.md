# Nested Scrolling

## 所有权模型

`PTNestedScrollCoordinator` 在三个状态之间切换：

- `outer`：Header 尚未折叠完，由外层 ScrollView 消耗垂直偏移。
- `inner(pageID:)`：当前页面接管滚动，外层保持在折叠上限。
- `transitioning`：外层和内层正在交接，避免两个滚动容器同时修正位置。

## 页面接入

实现 `PTScrollablePage` 时返回页面自己的 ScrollView：

```swift
@MainActor
final class ListPage: UIViewController, PTScrollablePage {
    let tableView = UITableView()

    var pageView: UIView { view }
    var pageScrollView: UIScrollView { tableView }
}
```

如果页面没有明确提供 ScrollView，`PTPagingView` 会尝试查找页面层级中的第一个 ScrollView。复杂页面建议显式实现协议，避免把错误的内部滚动视图当作分页对象。

## 约束

- 不要在页面中覆盖容器已经接管的 `UIScrollView.delegate`；需要监听时使用页面自身的回调或适配器。
- 不要在每次 `scrollViewDidScroll` 中创建新 Task、刷新数据或重建 Header。
- 保留 `adjustedContentInset`，尤其是 iOS 26+ 使用额外 `contentInset` 时，应由协调器统一计算偏移。
- 真实项目需要验证刷新控件、键盘、横向 Carousel 和多层 Nested Paging 的手势优先级。
