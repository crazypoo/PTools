# PTSplitViewController 使用指南

`PTSplitViewController` 是 iOS 17+ / Swift 6 的 UIKit 分栏容器，直接继承
`UISplitViewController`。它只负责分栏、紧凑宽度自适应和状态恢复，不要求现有页面改继承
关系，也不替换 `PTBaseViewController`。

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
split.setInspector(InspectorViewController())
```

`wrapAll` 只会包装不是 `UINavigationController` 的栏位，避免重复导航控制器。需要完全自行管理
导航栈时使用 `.none` 或 `.custom`。

## 自适应展示

```swift
split.show(detailViewController, target: .automatic)
```

紧凑宽度会优先 push 到当前可见导航栈；regular 宽度会替换 secondary。也可以显式指定
`.primary`、`.supplementary`、`.secondary`、`.inspector` 或 `.navigationPush`。

## 状态恢复

```swift
let state = split.makeState { controller in
    (controller as? PTIdentifiableController)?.stableID
}

split.restore(state: state) { identifier in
    controllerFactory.make(identifier: identifier)
}
```

状态只保存业务稳定 ID 和 inspector 可见性，不跨并发边界保存 UIKit 控制器。

## 选择建议

- iPhone 或单栏页面：继续使用 `PTBaseViewController` + `PTBaseNavControl`。
- iPad、多窗口、Stage Manager：使用 `PTSplitViewController`。
- 路由场景：让 `PTRouter` 通过 `PTAdaptiveNavigationContainer` 进入自动展示，不在 Router 内判断设备类型。
- Inspector 只在 iOS 支持的原生展示能力下使用，不能把 UIKit 控制器强行伪装成固定列。
