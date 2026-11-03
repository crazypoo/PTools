# PTRichText · 圆角文字背景（iOS 13+）

## 范围

`PTTextAttribute.roundedBackground(color:cornerRadius:insets:borderColor:borderWidth:)`
可为单个富文本片段配置背景颜色、圆角、绘制扩展区域以及可选描边。
样式存入 Foundation `AttributedString` 的类型化属性，桥接到 `NSAttributedString` 时保留；
与其他 `PTRichText` 片段拼接、按范围设置属性及重新构造后不会丢失。

## 用法

```swift
let text = PTRichText {
    PTRichText("我很")
    PTRichText("喜欢",
               .foreground(.black),
               .roundedBackground(color: .systemYellow,
                                  cornerRadius: 6,
                                  insets: UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4),
                                  borderColor: .orange,
                                  borderWidth: 1,
                                  hitTestInsets: UIEdgeInsets(top: 6, left: 8,
                                                               bottom: 6, right: 8)))
    PTRichText("你。")
}

let label = PTRichTextStyledLabel()
label.numberOfLines = 0
label.lineBreakMode = .byCharWrapping
label.pt_apply(richText: text)
```

支持的圆角背景宿主：

- `PTRichTextStyledLabel`：常规/多行文字；沿用 `UILabel.pt_apply(richText:)`。
- `PTRichTextFlowLabel`：已有的片段限行宿主，同时支持圆角背景。
- `PTRichTextStyledTextView`：只读、可滚动富文本，沿用 `UITextView.pt_apply(richText:)`。

原生 `UILabel`、`UITextView`、以及直接设置 `label.attributedText = text.value`
的代码保持向后兼容，背景显示为无圆角矩形（系统 `.backgroundColor`）。
**要看到圆角必须使用上述显式宿主并调用 `pt_apply`。** 库不会 swizzle
`UILabel` 或覆盖宿主的其他绘制行为。

## 几何说明

- 渲染层对行布局逐行绘制 `UIBezierPath`；换行时每一行分别拥有圆角。
- 片段的颜色在创建时采样浅色/深色变体，显示时按 `traitCollection` 选择。
- `insets` 仅向外扩张**绘制区域**，**不增加文字排版宽度**。如需真正的布局间距，
  请在片段附近增加间隔字符或另用附件/独立视图，避免和临近文字重叠。
- 文字的链接、Action、媒体附件仍由既有富文本交互及布局链路处理；不把文字换成图片。
- 根据宿主的 `numberOfLines` 和 `lineBreakMode` 控制可绘制范围，
  不对被截断的字符绘制背景。
- 描边包含在背景区域内绘制；颜色和边距输入的非有限/负值会规整为零。

## 点击与长按

- 局部片段同时提供 `.action(PTTextActionID(...))`，并通过 `pt_apply(richText:actionRegistry:)` 关联处理器时，圆角背景可以响应已有的点击、长按事件；不需要单独的点击回调 API。
- `insets` 决定**绘制背景**扩大多少，背景自身在带 Action 的片段上也是点击区域。
- 新的 `hitTestInsets` 默认 `.zero`，从**背景外沿**继续扩大可触控区域（不会扩大绘制，也不会影响文字换行）。只有 .action 片段能通过此属性触发回调。
- 真实文字、链接、附件和相邻 Action 字形优先于扩大后的背景命中区域，两个扩大的目标重叠时按距离选择最近的目标。
- 命中仍以原始 Action 字符范围发回 `PTTextActionEvent`；扩大的是手指容错范围，不会改变 `event.range` 与 `event.text`。
- 手势只会在宿主 UIView 自身的 `bounds` 以内接收触摸。文字标签过窄时，请扩大标签容器/约束，而不是期望 `hitTestInsets` 自动让 UIKit 在视图外接受触摸。
- `PTRichTextFlowLabel` 有或没有片段限行时都可以响应带背景的 Action；`PTRichTextStyledTextView` 按滚动偏移量和 `textContainerInset` 计算命中位置。

## 验收

`Tests/PToolsRichTextTests/PTRichTextRoundedBackgroundTests.swift`
覆盖属性往返、范围变更、普通宿主兼容、专用宿主背景移除、跨行与截断、
异常参数规整，以及 `hitTestInsets`、真实字形优先、无 Action 不触发、FlowLabel
映射、TextView 滚动偏移后的点击与长按语义。请在 Xcode 的 iOS Simulator 上运行 `PToolsRichTextTests`；
深色模式、Dynamic Type、混合 Emoji、RTL、多行带 Action 和 UITextView
滚动时的实际绘制，仍建议在设备上进行视觉验收。
