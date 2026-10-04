# PTSplitViewController 与 Router 集成

5.61.0 将自适应容器能力放在 Core 协议边界：`PTRouter` 不依赖 SplitView 实现，
`PTSplitViewController` 实现 `PTAdaptiveNavigationContainer`。

当路由是 `.push` 时，Router 会从当前可见控制器向父层查找自适应容器：

```text
当前页面 → UINavigationController → PTSplitViewController
                                      ├─ compact: push
                                      └─ regular: set secondary
```

没有自适应容器时，原有 `PTUtils.push` 行为保持不变。这样旧项目无需迁移，iPad 项目只需把
根容器替换为 `PTSplitViewController` 即可获得默认适配。

`navigation.split-view` Demo 以 root container 全屏展示，避免把 `UISplitViewController` 放进外层
`UINavigationController`。Demo 的 Router 按钮和业务中的 `.push` 使用同一条路径：compact 环境
进入当前可见导航栈，regular 环境更新 secondary；不会把页面推入隐藏列或外层 Demo 导航栈。

显式 `split.show(_:target: .navigationPush)` 也只面向当前真实可见的导航栈。需要明确写入列时，
使用 `.primary`、`.supplementary`、`.secondary` 或 `.compact`；`.secondary` 不会因 compact 环境
而改变语义。

自定义业务目的地时直接调用：

```swift
split.pt_showAdaptive(detail, destination: .secondary)
```

不要在业务 Router 中增加 `isPad`、size class 或全局 key window 判断；Scene 和容器负责展示归属。
