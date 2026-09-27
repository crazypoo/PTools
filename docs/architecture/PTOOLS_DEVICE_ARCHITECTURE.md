# PToolsDevice 架构

## 分层

```text
DeviceCatalog JSON
        ↓ 校验 / 生成
Generated Swift catalog
        ↓
PToolsDevice value model + runtime resolver
        ↓
Apple framework capability checks
        ↓
Core compatibility aliases / feature modules
```

`PToolsDevice` 位于 `PooToolsSource/PToolsDevice`，只依赖 Foundation；UIKit、AVFoundation、LocalAuthentication、CoreMotion、CoreLocation 和 CoreNFC 仅在平台能力分支中使用。运行时不解析 JSON。

## 身份与能力分离

`PTDeviceSpecification` 描述静态目录信息，`PTDeviceRuntimeInfo` 描述当前进程环境，`PTDeviceCapabilityStatus` 描述当前 API、权限和模拟器环境下的可用性。硬件存在不等于 App 当前可用。

```swift
let device = PTDevice.current
let model = device.model
let nfcStatus = await device.status(for: .nfc)
```

未知标识符会得到 `unknown:<identifier>` 模型、`.unknown` family/platform，不会因为目录缺少新设备而崩溃。

## 构建边界

- SwiftPM `PToolsDevice` 单独提供 iOS 17、macOS 14、tvOS 17、watchOS 10 和 visionOS 1 的 Foundation-first 能力。
- `ptools`、`PooToolsAll` 和 CocoaPods 根 Pod 仍按 UIKit/iOS 17 约束构建，不能据此宣称所有功能跨平台。
- CocoaPods 使用 `PooTools/Device` subspec；Core 通过它替代 DeviceKit。

## 并发规则

模型、目录和运行时快照都是 `Sendable` 值类型。动态能力查询是 async，不把 UIKit、PhotoKit 或第三方对象跨 actor 传递，也不使用业务级 `@unchecked Sendable`。
