# Popovers → PTools 迁移指南

## 依赖

删除旧的 `Popovers` Pod 或源码依赖，使用：

```ruby
pod 'PooTools/Popover'
```

历史项目如果仍写 `pod 'PooTools/PopoverKit'`，可以继续构建；该 subspec 现在只是 `PooTools/Popover` 的兼容别名。

## 基础迁移

旧逻辑需要业务手算 `sourceFrame`，新逻辑直接传入 Anchor：

```swift
let popover = PTPopover(content: .view {
    SettingsMenuView()
})

let handle = PTPopoverCenter.shared.present(
    popover,
    from: .view(settingsButton)
)
```

## 常用映射

| Popovers | PTools |
|---|---|
| `Popover` | `PTPopover` |
| `Attributes` | `PTPopoverConfiguration` |
| `tag` | `PTOverlayID` |
| `sourceFrame` | `PTAnchor` |
| `sourceFrameInset` | `anchorInsets` |
| `screenEdgePadding` | `screenEdgeInsets` |
| `tapOutside` | `outsideTapBehavior` |
| `excludedFrames` | `PTExcludedHitRegion` |
| `replace` | `PTPopoverHandle.replace` |
| `PopoverReader` | `PTPopoverContext` |
| `Templates.Menu` | `PTContextMenu` 或系统 `UIMenu` |

系统菜单足够时优先使用 `UIMenu`；需要任意 Anchor、滚动、高度自定义或平滑替换时使用 `PTContextMenu`。

