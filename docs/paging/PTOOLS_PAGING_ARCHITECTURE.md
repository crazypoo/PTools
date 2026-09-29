# PTools Paging Architecture

> 5.57.3 / iOS 17+ / Swift 6+

## 目标

PTools 5.30.0 将分段与分页能力收口为 UIKit 原生实现，不再把第三方容器、索引回调和页面生命周期胶水暴露给业务层。

核心组件可以独立使用，也可以按下面的关系组合：

```text
PTSegmentedView        -> 只负责分段展示、选择、Indicator 和 Diffable Snapshot
PTPageContainer        -> 只负责页面创建、水平分页、生命周期和缓存
PTPagingView           -> 负责 Header、Pinned Header、外层滚动和嵌套滚动
PTSegmentedPagingCoordinator -> 负责稳定 ID 的双向同步
```

## 已加载页面查询层（5.57.2）

`PTPageContainer` 将可变缓存留在内部，只通过只读查询 API 对外提供事实：

```text
private loadedPages
        │
        ├── load / unload / cachePolicy
        │
        └── public read-only query
                ├── loadedPageIDs
                ├── loadedPage(for:)
                ├── loadedViewController(for:)
                ├── loadedViewControllers(of:)
                └── currentViewController
```

查询层只接受稳定 ID，不公开内部字典，也不提供 `validListDict` 兼容副本。读取未加载的 ID 不会调用 `makePage()`，不会改变 `selectedID`、缓存策略或生命周期。`loadedPageIDs` 使用 descriptor 顺序，避免把 Dictionary 的内部顺序变成业务契约。

`PTViewPage` 与 `PTViewControllerPage` 保持明确区别：前者可以通过 `loadedPage(for:)` 查询，后者才可以通过 `loadedViewController(for:)` 查询。缓存回收仍完全由 `PTPageCachePolicy` 决定。

## 稳定 ID

`PTSegmentItem.id` 与 `PTPageDescriptor.id` 是同步的唯一依据。业务不要用数组下标或每次读取都会变化的 UUID 作为 Diffable 身份。插入、删除、移动和恢复选择时，先保持 ID 稳定，再调用 `apply`。

```swift
@MainActor
let items = [
    PTSegmentItem.title(id: "all", "全部"),
    PTSegmentItem.title(id: "saved", "收藏")
]

let pages = [
    PTPageDescriptor(id: "all") { AllViewController() },
    PTPageDescriptor(id: "saved") { SavedViewController() }
]
```

## 5.57.3 的 Segment / Indicator 边界

`PTSegmentedView` 的宽度由统一测量契约计算，包含 Badge 内边距、normal/selected 字体、
selectedScale 和实际图片尺寸。`PTSegmentIndicatorContext.itemFrames` 与 `contentFrames`
都属于 Segment viewport 坐标；标题条滚动只更新几何投影，页面滑动才产生 transition。
因此 Segment、Page、Indicator 和稳定 ID 的职责不会互相污染。

## 并发和生命周期边界

- UIKit 对象和所有公开 UI 组件均在 `MainActor` 上使用。
- 页面构造器是 `@MainActor` 闭包，不把 View、ViewController 或 UIKit delegate 跨 actor 传递。
- `PTPageContainer` 负责 `addChild`、`didMove`、`willMove`、`removeFromParent` 和页面生命周期事件。
- 缓存策略由 `PTPageCachePolicy` 控制；缓存淘汰不依赖 Cell reuse。
- Coordinator 使用弱引用，避免分段 View 与页面容器互相强持有。

## 滚动和手势

`PTNestedScrollCoordinator` 将外层 Header 折叠和当前页面 ScrollView 的偏移归一化，`PTGestureDirectionResolver` 与 `PTGestureArena` 为横向分页、垂直滚动和系统返回手势提供统一策略。页面确实需要滚动联动时，实现 `PTScrollablePage`，不要从业务层直接替换容器 delegate。

## 5.30.0 的边界

当前实现覆盖常用标题/图片/富文本/徽标、内置 Indicator、懒加载、基础缓存、Header、Pinned Header、嵌套滚动和刷新适配契约。复杂业务仍应在宿主项目验证自定义 Header、刷新库、横竖屏切换、键盘、指针和多层嵌套滚动；这些验证不由静态检查替代。
