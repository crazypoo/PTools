# PTTipsView Overlay 集成

简单提示使用：

```swift
PTTipsView.show("点击这里切换模式", from: modeButton)
```

该入口通过 `PTAnchorResolver` 把 View 转换为当前 Window 坐标，并用 `PTPopoverPositioningEngine` 选择上下左右空间，再交给既有 `PTTipsView` 绘制箭头和文本。

Tips 仍然是轻量、短时说明，不承载复杂列表、输入框、Picker 或多级菜单。复杂内容请使用 `PTPopover`。

