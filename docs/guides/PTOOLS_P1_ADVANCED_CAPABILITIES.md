# PTools 5.35.0 P1 使用指南

## Theme

```swift
let theme = PTTheme()
let primary = await MainActor.run {
    PTThemeResolver(theme: theme).color(.backgroundPrimary)
}
```

UIKit 页面中推荐在边界处解析 token，不要把 `UIColor` 放进跨 actor 模型。组件需要局部覆盖时使用 `PTThemeScope(theme:parent:)`，页面销毁时释放 scope。

## ContentState

```swift
let view = await MainActor.run { PTContentStateView(frame: .zero) }
view.contentHost.addSubview(contentView)
view.render(.loading(previous: nil))
view.render(.content(contentView))
view.render(.error(.init(message: "加载失败")))
```

状态容器不会修改业务数据源。请求成功、失败、取消都应显式渲染最终状态；有缓存时使用 `.loading(previous:)` 或 `.offline(previous:)` 保留已有内容。

## Form

```swift
let email: PTFormField = .init(
    id: "email",
    kind: .text,
    title: "Email",
    rules: [.required, .email]
)
let form = PTFormEngine(fields: [email])
let controller = PTFormViewController(form: form)
```

字段 ID 必须稳定，不要使用 indexPath。输入变化时调用 `setValue`；异步校验使用 `validateField(_:debounce:)`，旧输入的任务会自动取消。提交使用 `submit`，不要从 UI 层直接读取 actor 内部字典。

## Bluetooth

```swift
let central = PTBluetoothCentral()
let scan = await central.scan(policy: .init(serviceUUIDs: ["180D"], timeout: 10))
for await peripheral in scan {
    print(peripheral.identifier)
}
```

连接后先完成服务和特征发现，再调用 `read`、`write` 或 `notifications`。把业务协议封装在宿主适配器中，Bluetooth 模块不认识 XP400、YMOBD 或 OBD 帧。

需要系统恢复连接状态时，为 `PTBluetoothCentral` 注入 `PTBluetoothRestorationConfiguration`，然后读取 `restorationSnapshot()`；恢复结果只返回外设标识快照，实际业务重连仍由宿主决定。

## Documents

```swift
let request = PTDocumentRequest(
    allowedContentTypes: [.pdf, .image],
    allowsMultipleSelection: true,
    shouldCopyImportedFiles: true
)
await MainActor.run {
    PTDocumentPickerCoordinator.shared.present(from: viewController, request: request) { selections in
        // 在宿主中处理选择结果。
    }
}
```

需要长期访问外部文件时保存 `PTDocumentBookmark`，每次使用通过 `PTDocumentAccess.withSecurityScopedAccess` 包裹，避免泄漏安全作用域。

## Simulation

```swift
let runtime = PTSimulationRuntime(
    environment: .init(isEnabled: true),
    clock: .init(mode: .instant)
)
await runtime.install(.init(scenarios: [
    .init(identifier: "offline", events: [
        .init(time: .zero, kind: .online(true)),
        .init(time: .seconds(2), kind: .online(false))
    ])
]))
let events = try await runtime.replay(identifier: "offline")
for await event in events { print(event) }
```

Release 默认 `isEnabled == false`。生产宿主不要把模拟 runtime 写入共享单例；测试和 Demo 配置应显式注入环境与 Provider。

## Accessibility

```swift
let coordinator = PTAccessibilityFocusCoordinator()
coordinator.captureFocus()
coordinator.moveFocus(to: button)
coordinator.announce(.init(message: "已完成"))
coordinator.restoreFocus()
```

组件必须提供 label/value/hint，不要只用颜色表达状态；动态字体、Reduce Motion、Reduce Transparency 和 RTL 由系统环境快照驱动。
