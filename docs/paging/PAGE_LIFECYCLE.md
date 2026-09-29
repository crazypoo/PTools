# Page Lifecycle

## 生命周期顺序

`PTPageContainer` 对页面发出以下事件：

```text
willLoad -> didLoad -> willAppear -> didAppear
willDisappear -> didDisappear -> didUnload
```

页面实现 `PTPageLifecycleObserving` 可以接收事件；外部也可以通过 `onLifecycle` 观察稳定 ID。页面创建和 UIKit 子控制器 containment 都在 MainActor 内完成。

## 缓存策略

- `keepAllLoaded`：适合页面少且状态昂贵的场景。
- `adjacent(radius:)`：默认策略，只保留当前页附近页面。
- `limit(_:)`：限制同时保留的页面数量。
- `discardOffscreen`：内存敏感场景使用，离屏页会收到 `didUnload`。

页面不要把异步结果直接写回“当前页面”判断之外；应使用页面 ID 或任务代际校验。离开页面时取消图片、网络和媒体任务。

## 已加载查询与可见状态

`loaded` 不等于 `visible`：

- `loadedPageIDs` 表示当前仍由 `PTPageContainer` 缓存持有的页面。
- `selectedID` 表示当前选择，不代表其他已缓存页面可见。
- `currentViewController` 只返回当前选中且已经加载的控制器。
- `willAppear` / `didAppear` 只描述可见性生命周期，不会因为查询而产生。

所有 `loadedPage(for:)`、`loadedViewController(for:)` 和批量查询都是无副作用读取，不会调用页面工厂。`didUnload` 之后，相关查询必须返回 `nil`，即使业务代码仍然持有原来的页面或 ViewController 引用。

## 选中状态

选中状态以稳定 ID 为准，数组索引只是展示层派生值。更新 descriptors 后，如果旧 ID 仍存在会保留它，否则使用显式 ID 或首个页面作为回退。这样可以安全处理动态插入、删除、移动和状态恢复。
