# PToolsDevice 使用指南

## 安装

SwiftPM 选择 `PToolsDevice` product；CocoaPods 选择 `PooTools/Device`。使用完整 Core 时会自动带入 Device subspec。

默认 `PToolsDevice` / `PooTools/Device` 不链接 CoreNFC；`PTDeviceCapability.nfc` 在未显式接入 NFC 时返回 `.unsupported`。只有确实需要读取或写入 NFC 时才添加 `PooTools/NFCKit`，并由宿主自行提供 Apple 要求的 NFC 使用说明和对应能力配置。没有 NFC 功能的 App 不应添加 `NFCReaderUsageDescription` 或 NFC entitlement，并应在 App Review Notes 中明确说明未使用 NFC。

## 查询设备身份

```swift
import PToolsDevice

let device = PTDevice.current
print(device.identifier)
print(device.model.rawValue)
print(device.specification?.marketingName ?? "Unknown device")
print(device.environment)
```

## 查询能力

```swift
let status = await PTDevice.current.status(for: .camera)
switch status {
case .available:
    startCamera()
case .permissionDenied, .restricted:
    showPermissionHelp()
case .unavailableOnSimulator:
    showSimulatorHint()
default:
    showUnsupportedMessage()
}
```

定位能力不因模拟器直接判为不可用；它按 Core Location 的公开 API 返回状态。视觉、NFC、运动和相机能力同样不通过营销名称猜测。

## 布局建议

不要用具体机型替代响应式布局：

```swift
let bottomInset = view.safeAreaInsets.bottom
let isPad = traitCollection.userInterfaceIdiom == .pad
```

只有设备识别、调试展示和能力门控才读取 `PTDevice`。

## 未知设备

未知设备是正常兼容路径：展示 `identifier` 或通用名称，不阻塞启动、不强制转换、不写入隐私数据。
