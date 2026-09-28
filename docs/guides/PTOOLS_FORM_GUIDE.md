# PTools Form 2.0 / 表单 2.0 / Formulario 2.0

> Version: 5.57.0 · iOS 17+ · Swift 6+

## 1. Quick Start / 快速开始 / Inicio rápido

~~~swift
let form = PTFormEngine(fields: [
    PTFormField(id: "email", kind: .text, title: "Email", rules: [.required, .email]),
    PTFormField(id: "password", kind: .secureText, title: "Password", rules: [.required])
])
let controller = PTFormViewController(form: form)
~~~

PTools Form 2.0 uses a PTFormEngine actor for values and validation and a MainActor controller for UIKit.
The public field and section identifiers are stable values; UIKit objects never cross the engine boundary.

PTools Form 2.0 使用 PTFormEngine actor 管理值和校验，由 MainActor 控制器负责 UIKit。字段和 Section
标识符都是稳定值，UIKit 对象不会跨越引擎并发边界。

PTools Form 2.0 usa un actor PTFormEngine para valores y validación y un controlador MainActor para UIKit.
Los identificadores de campos y secciones son valores estables y las vistas UIKit no cruzan el límite del actor.

## 2. Field types / 字段类型 / Tipos de campo

text、secureText、multilineText、number、phone、bankCard、toggle、checkbox、slider、stepper、date、picker
和 custom 均可用。渲染器继续优先复用 PTTextField、PTGrowingTextView、PTSwitch、PTCheckBox、PTSlider、
PTStepper 和 PTools Picker。

## 3. Multiple sections / 多 Section / Varias secciones

~~~swift
let sections = [
    PTFormSection(id: "account", title: "Account", fieldIDs: ["email", "password"]),
    PTFormSection(id: "profile", title: "Profile", fieldIDs: ["name"])
]
let form = PTFormEngine(fields: fields, sections: sections)
~~~

Sections map one-to-one to PTSection. A field not listed in a section is placed in the stable
__pt_form_implicit_section__ section by default. Use unsectionedFieldPolicy: .reject when the host wants
definition diagnostics instead of an implicit section.

每个 Section 会一对一映射到 PTSection。未列入 Section 的字段默认进入稳定的
__pt_form_implicit_section__；需要严格诊断时使用 unsectionedFieldPolicy: .reject。

## 4. Configuration and spacing / 配置与间距 / Configuración y espaciado

Use PTFormConfiguration.plain、.grouped、.insetGrouped or .card, then override contentInsets、sectionSpacing、
defaultSectionConfiguration and defaultFieldConfiguration. Section configuration wins over form defaults,
and an explicit zero is respected.

~~~swift
let configuration = PTFormConfiguration(
    contentInsets: .init(top: 16, leading: 20, bottom: 24, trailing: 20),
    sectionSpacing: 24,
    defaultSectionConfiguration: .init(rowSpacing: 8)
)
let controller = PTFormViewController(form: form, configuration: configuration)
~~~

## 5. Header and footer / Header 与 Footer / Encabezado y pie

Use .text(.init(title:subtitle:)) for the built-in dynamic header/footer. Use .custom(identifier:) for a
registered renderer. Custom renderers should provide viewClass, reuseID, and configure a dequeued view so that
UICollectionView reuse remains safe.

## 6. Section appearance / Section 外观 / Apariencia de sección

PTFormSectionAppearance supports grouped and card backgrounds, corner radius, separators and shadows.
Appearance stays in the Sendable configuration; the renderer resolves colors through PTFormThemeAdapter.

## 7. Field layout / 字段布局 / Diseño de campo

PTFormFieldConfiguration supports top、leading and hidden titles, content insets, minimum/preferred height,
validation-message visibility, numeric/date/text input configuration and automatic Dynamic Type height.
There is no universal fixed 92 point row height.

## 8. Validation / 校验 / Validación

Built-in rules include required, length, regex, range, email, phone and bank card. Async validators are
Sendable; field generations and form revisions discard stale results. PTFormValidationPolicy controls trigger,
debounce, inline messages and first-invalid focus.

## 9. Async and cross-field validation / 异步与跨字段校验 / Validación asíncrona y entre campos

~~~swift
let passwordMatch = PTFormCrossValidator(fieldIDs: ["password", "confirm"]) { context in
    guard context.value(for: "password") == context.value(for: "confirm") else {
        return [PTFormValidationIssue(fieldID: "confirm", message: "Passwords do not match")]
    }
    return []
}
let form = PTFormEngine(fields: fields, crossValidators: [passwordMatch])
~~~

## 10. Dependencies and visibility / 依赖与可见性 / Dependencias y visibilidad

The legacy dependency remains supported. For compound rules use .all、.any、.not、.equals、.notEquals、
.isEmpty and .isNotEmpty. Hidden fields are excluded from snapshots and keyboard navigation.

## 11. Custom renderer / 自定义 Renderer / Renderer personalizado

Register a renderer by field kind or rendererIdentifier. Renderers receive PTFormFieldRenderContext, theme,
validation issue and accessibility environment. A renderer can declare .notFocusable so keyboard navigation skips it.

## 12. Custom section header / 自定义 Section Header / Encabezado personalizado

~~~swift
@MainActor
final class VehicleHeaderRenderer: PTFormSectionSupplementaryRenderer {
    let identifier = "vehicle-header"
    let reuseID = "VehicleHeaderView"
    let viewClass: UICollectionReusableView.Type? = VehicleHeaderView.self

    func makeView(content: PTFormSupplementaryContent,
                  context: PTFormSectionRenderContext) -> UICollectionReusableView {
        VehicleHeaderView(frame: .zero)
    }

    func configure(view: UICollectionReusableView,
                   content: PTFormSupplementaryContent,
                   context: PTFormSectionRenderContext) {
        (view as? VehicleHeaderView)?.apply(theme: context.theme)
    }
}

let sections = PTFormSectionRendererRegistry()
sections.register(VehicleHeaderRenderer())
~~~

## 13. Theme and accessibility / 主题与无障碍 / Tema y accesibilidad

Theme colors and fonts come from PTFormThemeAdapter. The controller refreshes on Dynamic Type, dark mode and
accessibility contrast changes. Required, read-only, disabled and validation states are exposed to VoiceOver.
RTL, Reduce Motion, Reduce Transparency and High Contrast remain host environment inputs.

## 14. Keyboard / 键盘 / Teclado

Previous、Next and Done are calculated from field IDs and current visibility, not from a hard-coded section 0.
Disabled、read-only and non-focusable fields are skipped, including across sections.

## 15. Runtime update / 运行时更新 / Actualización en tiempo de ejecución

Use setValue、updateField、setFieldEnabled、setFieldReadOnly、updateSection、setSectionVisible or
performUpdates. The engine increments revision; the controller rebuilds a typed snapshot and lets PTCollectionView
apply stable Diffable identities.

## 16. Submit / 提交 / Envío

Call await controller.validate() before custom flows, or try await controller.submit { values in ... }.
Validation errors are returned as typed PTFormValidationResult; cancellation becomes PTFormError.cancelled.

## 17. Reset and dirty state / 重置与脏状态 / Restablecer y cambios

await form.reset() restores initial values. await form.reset(field:)、await form.isDirty and
await form.changedFieldIDs support partial reset and unsaved-change prompts.

## 18. Snapshot and performance / 快照与性能 / Snapshot y rendimiento

await form.makeSnapshot() is the Sendable presentation boundary. Value changes preserve field and section identity.
Large-form regression coverage uses 20、100、500 and 1000 fields; avoid rebuilding UIKit views outside the
controller refresh boundary.

## 19. Migration / 迁移 / Migración

Existing calls to PTFormEngine(fields:), PTFormViewController(form:) and PTFormField(...) remain valid.
Passing sections now renders real multiple sections instead of flattening them into one "form" section.
Use .flat presentation or an explicit single section when the previous visual layout is required.

## 20. Troubleshooting / 排查 / Diagnóstico

Check stable IDs, section membership, target membership, PToolsForm selection, MainActor ownership and the
returned definitionIssues before changing a renderer. A missing custom section renderer falls back to a dequeued
diagnostic header/footer instead of returning a view from another hierarchy.

