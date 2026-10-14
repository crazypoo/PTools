# PTRichText 多行附件布局指南

## 中文

### 推荐用法

```swift
@MainActor
func applyRichText(to label: UILabel, image: UIImage, actionRegistry: PTTextActionRegistry) {
    let actionID = PTTextActionID("rule")
    let imageAttribute = PTTextAttribute.image(
        image,
        .custom(size: CGSize(width: 24, height: 24)),
        baselineOffset: -7
    )
    let richText = PTRichText(string: "\u{FFFC}", with: [imageAttribute])
        + PTRichText(" 标题与描述，后面继续显示足够长的内容以触发换行。")
        + PTRichText("点击规则", with: [.action(actionID), .foreground(.systemBlue)])

    actionRegistry.register(actionID) { event in
        print("点击：\(event.text)")
    }
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.pt_apply(richText: PTRichText(wrap: .embedding(richText),
                                         .paragraph(.lineBreakMode(.byWordWrapping))),
                   actionRegistry: actionRegistry,
                   interactionMode: .actionsOnly)
}
```

`PTRichText` 仍以值模型保存原始 `.baselineOffset`。渲染器把富文本交给 UIKit 时，
只复制并调整附件副本的 `bounds.origin.y`，普通文字的基线属性不会被删除，也不会重复移动。
远程图片占位、真实图片回填和长按高亮使用同一套渲染准备流程。

调用方仍然负责给 UILabel 提供足够高度。`numberOfLines`、`lineBreakMode`、Dynamic Type 和约束
不会被库偷偷改写；如果 `sizeThatFits` 高于容器高度，UIKit 仍会按照调用方设置裁剪或省略。

在 Example 中打开 `Rich Text · Attachment Multiline Regression`，可切换：

- 容器高度：40 / 64 / 80 / 120pt
- 容器宽度：280 / 366 / 430pt
- 图片基线：-7 / 0 / +7pt
- 换行：按单词 / 按字符

### 诊断

Debug 构建可调用：

```swift
let report = label.pt_richTextLayoutDiagnosticReport()
print(report)
```

报告包含 UILabel bounds、行数、换行模式、intrinsic size、sizeThatFits 和各个富文本 run 的字体、
段落、附件 bounds、基线和 Action ID。Release 构建不会执行这段遍历。

## English

Use `UILabel.pt_apply(richText:)` with `numberOfLines` and `lineBreakMode` chosen by the host. The
value model keeps the original attachment baseline offset; UIKit receives an idempotent display copy
whose attachment bounds carry the visual offset exactly once. Async image replacement and temporary
action highlighting use the same path, so the first render cannot be fixed while a later update regresses.

The Example regression screen covers 24×24 attachments, 40/64/80/120pt heights, widths 280/366/430pt,
negative/zero/positive offsets, word/character wrapping, and an action on a wrapped line.

## Español

Usa `UILabel.pt_apply(richText:)` con `numberOfLines` y `lineBreakMode` definidos por el host. El modelo
conserva el desplazamiento original del adjunto; UIKit recibe una copia idempotente cuyo `bounds` aplica
el desplazamiento visual una sola vez. La sustitución asíncrona de imágenes y el resaltado temporal usan
el mismo camino, evitando que la primera representación sea correcta y una actualización posterior vuelva
a romper el layout.

La pantalla de regresión del Example cubre adjuntos de 24×24, alturas 40/64/80/120pt, anchos 280/366/430pt,
desplazamientos negativos/cero/positivos, ajuste por palabra o carácter y una acción en una línea envuelta.
