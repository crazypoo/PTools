# PTools Input TextFieldEffects

## 中文

`PooToolsInput` 面向 iOS 17+ / Swift 6 提供统一的输入框外观配置。`TextFieldEffects` 的九种样式和 `PTHoshiTextField` 继续保留原有公开 API，新增的共享配置只作为兼容增强：

```swift
let field = HoshiTextField()
field.placeholder = "邮箱"
field.leadingSpace = 12
field.textAndPlaceholderSpace = 8
field.textEditingEdges = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
field.placeholderFont = .preferredFont(forTextStyle: .footnote)
```

也可以一次性设置：

```swift
field.inputAppearance = PTInputAppearance(
    placeholderColorOverride: .secondaryLabel,
    placeholderFontOverride: .preferredFont(forTextStyle: .footnote),
    textAndPlaceholderSpace: 8,
    leadingSpace: 12,
    textEditingEdges: .init(top: 2, left: 4, bottom: 2, right: 4)
)
```

`placeholderAtt` 保留富文本的每个 run；设置为 `nil` 会清理 `attributedPlaceholder`，随后回退到普通 `placeholder`。`PTHoshiTextField` 只会在没有自定义 `leftView` 时安装内部间距视图，不会覆盖业务自定义视图。

旧拼写 `textAndPlceholderSpace` 仍可用，但新代码应使用 `textAndPlaceholderSpace`。旧属性和旧初始化方式不会改变动画和布局时机。

## English

`PooToolsInput` provides a shared appearance contract for iOS 17+ and Swift 6. Existing style-specific properties remain source compatible. Use `inputAppearance` when a screen needs one consistent placeholder font, color, leading space, and text insets. Rich placeholder runs are preserved, and assigning `nil` to `placeholderAtt` restores the plain UIKit placeholder path.

`PTHoshiTextField` keeps a caller-provided `leftView`; its internal spacer is installed only when no custom left view exists. Layout is invalidated instead of being invoked manually, so Auto Layout and cell reuse remain stable.

## Español

`PooToolsInput` ofrece un contrato común de apariencia para iOS 17+ y Swift 6. Se mantienen las propiedades específicas de cada estilo para conservar la compatibilidad. Usa `inputAppearance` cuando una pantalla necesite una fuente, color, espacio inicial e insets uniformes. Se conservan todos los runs del placeholder enriquecido y asignar `nil` a `placeholderAtt` vuelve al placeholder normal de UIKit.

`PTHoshiTextField` respeta un `leftView` proporcionado por la aplicación; el espaciador interno solo se instala cuando no existe uno personalizado. El layout se invalida en lugar de ejecutarse manualmente, lo que mantiene estable Auto Layout y la reutilización de celdas.

