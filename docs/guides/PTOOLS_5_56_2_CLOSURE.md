# PTools 5.56.2 闭环指南 / Closure Guide / Guía de cierre

## 中文

5.56.2 收口了四条能力链：Form 字段渲染、Documents PDF/分享、语义反馈和按钮异步 loading。
它们都是可选模块，Core 默认边界保持不变。

### Form

```swift
let form = PTFormEngine(fields: fields)
let controller = PTFormViewController(form: form)
navigationController?.pushViewController(controller, animated: true)
```

Form 会按字段类型选择 renderer，并复用仓库已有控件。文本输入支持 Previous、Next、Done；校验失败会更新无障碍信息并发送语义反馈。

### Documents

```swift
let request = PTDocumentRequest(allowedTypeIdentifiers: ["public.pdf"])
PTDocumentPickerCoordinator.shared.present(from: presenter, request: request) { result in
    // 中文：在主线程处理选择结果。
    // English: Handle the selection result on the main actor.
    // Español: Procesa el resultado de selección en el actor principal.
}
```

PDF 预览优先使用 PooToolsPDF，缺少可选模块时回退到 PDFKit。分享入口会根据当前 Scene 配置 iPad popover，并在完成或取消后释放安全作用域。

### Button loading 和反馈

```swift
button.performAsync {
    try await submit()
}
```

`PTBaseButton` 与 `PTActionLayoutButton` 共享 `PTControlLoadingCoordinator`，但各自保留控件展示方式。Alert、ActionSheet、Banner、Popover、Picker、TabBar、Navigation 和 Form 通过 `PTFeedbackCenter` 发送语义事件。

## English

PTools 5.56.2 closes the Form, Documents, semantic feedback, and button-loading paths without changing the Core default boundary. Form renderers reuse existing PTools controls, Documents uses the PooToolsPDF adapter with PDFKit fallback, and both button classes share one loading coordinator through composition.

## Español

PTools 5.56.2 cierra las rutas de Form, Documents, feedback semántico y carga asíncrona de botones sin cambiar el límite predeterminado de Core. Los renderizadores reutilizan los controles PTools existentes, Documents usa el adaptador PooToolsPDF con fallback a PDFKit y ambos botones comparten un único coordinador de carga mediante composición.

## 验证 / Verification / Verificación

- `swift package dump-package`
- `swift build --target PToolsForm --triple arm64-apple-ios17.0-simulator`
- `swift build --target PToolsDocuments --triple arm64-apple-ios17.0-simulator`
- Xcode workspace Debug / Release Simulator build
- `bash Scripts/CI/check_5_56_1_governance.sh`
