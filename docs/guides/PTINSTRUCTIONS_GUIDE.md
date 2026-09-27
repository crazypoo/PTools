# PooToolsInstructions 使用指南

## Swift Package Manager

```swift
import PooToolsInstructions

@MainActor
func showTour(from viewController: UIViewController, button: UIButton) {
    let tour = PTInstructionTour(
        id: "home-tour",
        steps: [
            PTInstructionStep(
                id: "primary-action",
                target: .view(button),
                content: .message(.init(title: "操作提示", message: "点击这里继续")),
                touchForwarding: .target,
                advancePolicy: .any
            )
        ],
        presentationPolicy: .once
    )

    Task { @MainActor in
        _ = try? await viewController.presentInstructions(tour)
    }
}
```

## 注册复用 Cell 或动态页面目标

```swift
cell.actionButton.pt_registerInstructionTarget("order-action", businessID: model.id)
let target = PTInstructionTarget.registered("order-action")
```

目标视图销毁或复用时调用 `pt_unregisterInstructionTarget`，避免旧 Cell 被重新定位。

## CocoaPods

```ruby
pod 'PooTools/Instructions'
```

CocoaPods 使用 `import PooTools`；SwiftPM 使用 `import PooToolsInstructions`。两种入口都使用同一套 Overlay 定位和生命周期规则。
