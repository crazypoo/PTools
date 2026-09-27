# PTPopover 使用指南

## 自定义 View

```swift
var configuration = PTPopoverConfiguration()
configuration.placement = .automatic
configuration.outsideTapBehavior = .dismiss

let popover = PTPopover(
    content: .view { customView },
    configuration: configuration
)

let handle = PTPopoverCenter.shared.present(popover, from: .view(sourceButton))
handle?.reposition()
```

## UIViewController 内容

```swift
let popover = PTPopover(content: .viewController {
    SettingsViewController()
})
PTPopoverCenter.shared.present(popover, from: .view(sourceButton))
```

Popover 会执行 `addChild`、`didMove`，关闭时执行 `willMove(nil)`、移除 View 和 `removeFromParent`。

## Menu

```swift
let menu = PTContextMenu(items: [
    PTContextMenuItem(id: "edit", title: "编辑") { edit() },
    PTContextMenuItem(id: "delete", title: "删除", state: .destructive) { remove() }
])
let popover = PTPopover(content: .menu(menu), configuration: .menu)
PTPopoverCenter.shared.present(popover, from: .view(sourceButton))
```

菜单超过可用高度时在内部滚动，不把无限高度交给外层布局。

## 生命周期

`PTPopoverHandle` 支持 `dismiss()`、`update(content:)`、`reposition()` 和 `replace(with:from:)`。Anchor 不在 Window 时展示失败；不会自动跳到其他 Scene。

