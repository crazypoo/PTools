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

`YoshikoTextField` 的 `activeBorderColor` 只控制激活边框，不再影响占位符文字。激活态默认沿用 `placeholderColor`；如果需要独立配置，可分别设置 `activePlaceholderColor`、`activePlaceholderFont` 和 `activePlaceholderAtt`。悬浮占位符会按实际字体或富文本高度动态调整输入区域。

所有继承 `TextFieldEffects` 的样式都支持统一的激活状态回调。`isActive` 在输入框获得焦点或包含文本时为 `true`，`activityChangeHandler` 只在状态发生变化时调用：

```swift
@MainActor
final class FormViewController: UIViewController {
    private func configure(field: HoshiTextField) {
        field.activityChangeHandler = { [weak self] isActive in
            self?.updateSubmitState(for: isActive)
        }
    }
}
```

回调同样覆盖用户编辑、失去焦点以及程序化设置 `text` / `attributedText` 的场景。独立的 `PTHoshiTextField` 不继承 `TextFieldEffects`，继续使用自身 API。

旧拼写 `textAndPlceholderSpace` 仍可用，但新代码应使用 `textAndPlaceholderSpace`。旧属性和旧初始化方式不会改变动画和布局时机。

## English

`PooToolsInput` provides a shared appearance contract for iOS 17+ and Swift 6. Existing style-specific properties remain source compatible. Use `inputAppearance` when a screen needs one consistent placeholder font, color, leading space, and text insets. Rich placeholder runs are preserved, and assigning `nil` to `placeholderAtt` restores the plain UIKit placeholder path.

`PTHoshiTextField` keeps a caller-provided `leftView`; its internal spacer is installed only when no custom left view exists. Layout is invalidated instead of being invoked manually, so Auto Layout and cell reuse remain stable.

For `YoshikoTextField`, `activeBorderColor` controls only the active border. The floating placeholder falls back to the shared placeholder configuration and can override its color, font, and rich text with `activePlaceholderColor`, `activePlaceholderFont`, and `activePlaceholderAtt`. The input area reserves the placeholder's measured height while it floats.

Every `TextFieldEffects` style exposes the same active-state API. `isActive` is `true` while the field is focused or contains text, and `activityChangeHandler` is called only when that value changes. The callback also covers user editing, resigning first responder, and programmatic `text` / `attributedText` assignments. The standalone `PTHoshiTextField` is not a `TextFieldEffects` subclass and keeps its own API.

## Español

`PooToolsInput` ofrece un contrato común de apariencia para iOS 17+ y Swift 6. Se mantienen las propiedades específicas de cada estilo para conservar la compatibilidad. Usa `inputAppearance` cuando una pantalla necesite una fuente, color, espacio inicial e insets uniformes. Se conservan todos los runs del placeholder enriquecido y asignar `nil` a `placeholderAtt` vuelve al placeholder normal de UIKit.

`PTHoshiTextField` respeta un `leftView` proporcionado por la aplicación; el espaciador interno solo se instala cuando no existe uno personalizado. El layout se invalida en lugar de ejecutarse manualmente, lo que mantiene estable Auto Layout y la reutilización de celdas.

En `YoshikoTextField`, `activeBorderColor` solo controla el borde activo. El placeholder flotante usa la configuración compartida o puede sobrescribir color, fuente y texto enriquecido con `activePlaceholderColor`, `activePlaceholderFont` y `activePlaceholderAtt`. El área de entrada reserva la altura medida del placeholder mientras flota.

Todos los estilos que heredan de `TextFieldEffects` ofrecen el mismo estado activo. `isActive` es `true` cuando el campo tiene el foco o contiene texto, y `activityChangeHandler` solo se ejecuta cuando ese valor cambia. También cubre la edición del usuario, la pérdida del foco y las asignaciones programáticas de `text` / `attributedText`. `PTHoshiTextField` es una variante independiente y conserva su propia API.

