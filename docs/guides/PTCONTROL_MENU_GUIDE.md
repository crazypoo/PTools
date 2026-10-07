# UIControl Native Menu Guide

## Scope / 范围 / Alcance

PTools 在 iOS 17+ / Swift 6 下直接复用 UIKit 的 `UIMenu`、`UIAction` 和
`UIContextMenuInteraction`，不重新绘制菜单，也不使用 Runtime Swizzling。

PTools reuses UIKit's native `UIMenu`, `UIAction`, and `UIContextMenuInteraction` on
iOS 17+ / Swift 6. It does not recreate the menu UI or use runtime swizzling.

PTools reutiliza `UIMenu`, `UIAction` y `UIContextMenuInteraction` nativos de UIKit en
iOS 17+ / Swift 6. No recrea la interfaz del menú ni usa swizzling de Runtime.

## Static Menu / 静态菜单 / Menú estático

```swift
let control = PTActionLayoutButton()
control.pt_setMenu(
    UIMenu(children: [
        UIAction(title: "编辑", image: UIImage(systemName: "pencil")) { _ in
            // Handle edit.
        },
        UIAction(title: "删除", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            // Handle delete.
        }
    ]),
    trigger: .longPress
)
```

`longPress` 保留普通点击事件；`primaryAction` 用控件主操作直接展示菜单：

```swift
control.pt_setMenu(menu, trigger: .primaryAction)
```

`PTActionLayoutButton` 和 Inspector 的 PTools 控件支持两种触发方式。`UIButton` / `PTBaseButton`
内部直接使用 UIKit 原生 `menu` 和 `showsMenuAsPrimaryAction`。普通外部 `UIControl` 通过安全的
长按 interaction 支持菜单；如果要主点击菜单，请使用 `UIButton`、`PTBaseButton` 或实现 PTools
菜单代理回调的自定义 `UIControl`。

## Dynamic Menu Provider / 动态菜单 / Menú dinámico

```swift
control.pt_setMenuProvider(trigger: .primaryAction) { [weak owner] in
    owner?.makeCurrentMenu()
}
```

Provider 在每次菜单展示前执行，不缓存旧的标题、权限或状态。

The provider runs before every presentation and does not cache stale title, permission, or state.

El proveedor se ejecuta antes de cada presentación y no conserva títulos, permisos ni estados obsoletos.

## Selection Menu / 选择菜单 / Menú de selección

`selectedID` 是唯一状态源。选中项显示 `selectedImage`，未选项的 `image` 永远为 `nil`；未提供
`selectedImage` 时，PTools 使用系统 `checkmark`：

```swift
enum SortType: Hashable {
    case all, sales, price, latest
}

var sortType = SortType.all

button.pt_setSelectionMenuProvider(
    trigger: .primaryAction,
    items: {
        [
            .init(id: .all, title: "综合"),
            .init(id: .sales, title: "销量", selectedImage: UIImage(systemName: "chart.bar.fill")),
            .init(id: .price, title: "价格"),
            .init(id: .latest, title: "最新")
        ]
    },
    selectedID: {
        sortType
    },
    selectionChanged: { id in
        sortType = id
        reloadData()
    }
)
```

当前选中项为 `sales` 时：

```text
综合
▥ 销量
价格
最新
```

业务更新 `sortType` 后，不需要重新安装菜单；下次打开会读取最新的 `selectedID`。

## Loading / 禁用 / Carga

PTools 复用已有 `PTControlLoadingCoordinator`。Loading 时会将 `isUserInteractionEnabled` 设为
`false`，因此菜单不会绕过 loading 或 disabled 状态；`stopLoading()` 后原菜单自动恢复。

```swift
button.startLoading()
// Menu is unavailable while loading.
button.stopLoading()
```

## Accessibility and RTL / 无障碍与 RTL / Accesibilidad y RTL

菜单项使用 UIKit 原生 `UIAction`，VoiceOver 会读取其标题和可用状态。PTools 不硬编码业务文案，
调用方应按业务设置 `accessibilityLabel` 和 `accessibilityHint`。原生 UIKit 负责 RTL 的菜单布局；
PTools 不把 leading/trailing 写死为左/右。

菜单位置由 UIKit 根据触点、可用空间和当前界面方向自动选择。PTools 不增加不会改变 UIKit
实际定位的伪 `leading` / `trailing` 参数；RTL 由 UIKit 的
`effectiveUserInterfaceLayoutDirection` 自动处理。Inspector 原有的
`menuAttachmentPoint(for:)` 继续保留给它自己的 `UIView` 菜单定位逻辑。

`pt_removeMenu()` 只移除 PTools 自己安装的菜单和 interaction，并恢复控件原来的 UIKit 状态。

```swift
control.pt_removeMenu()
```

## API Summary / API 摘要 / Resumen de API

| API | 用途 |
| --- | --- |
| `pt_setMenu(_:trigger:)` | 静态原生菜单 |
| `pt_setMenuProvider(trigger:_:)` | 每次展示动态生成菜单 |
| `pt_setSelectionMenu(items:selectedID:trigger:selectionChanged:)` | 一次性选择菜单 |
| `pt_setSelectionMenuProvider(trigger:items:selectedID:selectionChanged:)` | 动态选择菜单 |
| `pt_removeMenu()` | 删除 PTools 菜单并恢复原状态 |
