# PTSplitViewController 使用指南

`PTSplitViewController` 是 iOS 17+ / Swift 6 的 UIKit 自适应容器，直接继承
`UISplitViewController`。它同时支持 iPhone、iPad 和可调整窗口：compact 环境使用导航栈，regular
环境使用双栏或三栏。它只负责分栏、紧凑宽度自适应和状态恢复，不要求现有页面改变继承关系，
也不替换 `PTBaseViewController`。

## 基础用法

```swift
let split = PTSplitViewController(configuration: PTSplitConfiguration(
    style: .tripleColumn,
    displayMode: .oneBesideSecondary,
    splitBehavior: .tile,
    navigationPolicy: .wrapAll
))

split.setPrimary(SidebarViewController())
split.setSupplementary(SearchViewController())
split.setSecondary(DetailViewController())
split.setCompact(MenuViewController())
split.setInspector(InspectorViewController())
```

`wrapAll` 会包装 primary、supplementary、secondary 和 compact 中不是 `UINavigationController` 的栏位，
避免重复导航控制器；Inspector 不会被包装。只想包装 compact 时使用 `.wrapCompact`，需要完全自行
管理导航栈时使用 `.none` 或 `.custom`。

## 自适应展示

```swift
split.show(detailViewController, target: .automatic)
```

紧凑宽度会优先 push 到当前可见导航栈；regular 宽度会替换 secondary。也可以显式指定
`.primary`、`.supplementary`、`.secondary`、`.compact`、`.inspector` 或 `.navigationPush`。

`.automatic` 和 `.navigationPush` 都不会按 iPhone/iPad 设备类型判断，也不会把页面推入隐藏的
secondary 栈；它们使用 UIKit 当前折叠状态、水平 Size Class 和真实可见导航栈。显式 `.secondary`
仍然只表示更新 secondary，不会偷偷转换成 push。

Inspector 默认使用 `PTSplitInspectorMode.automatic`：iOS 26+ 使用原生 inspector column，旧系统
使用 page sheet 兼容展示。需要固定行为时可以配置 `.nativeWhenAvailable` 或 `.sheet`。

## 状态恢复

```swift
let state = split.makeState { controller in
    (controller as? PTIdentifiableController)?.stableID
}

split.restore(state: state) { identifier in
    controllerFactory.make(identifier: identifier)
}
```

状态只保存业务稳定 ID、compact selection 和 inspector 可见性，不跨并发边界保存 UIKit 控制器。

## iPhone / iPad 同一套 Demo

Example 中的 `navigation.split-view` 使用 root-container presentation，不会把
`UISplitViewController` push 到外层导航栈。打开后可以按以下路径验证：

```text
compact: Category → Component → Detail（导航 push）
regular: Primary Category → Supplementary Component → Secondary Detail
```

Inspector 页面还提供 `Save State`、`Reset`、`Restore State`、Router `.push` 和运行时状态信息。
同一个 Demo 可以在 iPhone portrait/landscape、iPad portrait/landscape 以及可调整窗口中使用；
真正的 Stage Manager、外接屏和真机视觉证据仍由宿主项目补充。

完整验证矩阵见 `docs/splitview/PTSplitViewController_Simulator_Matrix.md`。

## 选择建议

- 普通单栏页面：继续使用 `PTBaseViewController` + `PTBaseNavControl`。
- iPhone/iPad、多窗口、Stage Manager：使用同一个 `PTSplitViewController`，让 UIKit 处理 collapse/expand。
- 路由场景：让 `PTRouter` 通过 `PTAdaptiveNavigationContainer` 进入自动展示，不在 Router 内判断设备类型。
- Inspector 只在 iOS 支持的原生展示能力下使用，不能把 UIKit 控制器强行伪装成固定列。
