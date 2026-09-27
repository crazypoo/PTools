# DeviceKit 使用审计

## 结论

5.33.0 已移除 PTools 生产源码、SwiftPM、CocoaPods 和锁文件中的 `DeviceKit`。设备身份与能力现在由独立的 `PToolsDevice` 提供，Core 的历史全局变量仍保留为兼容别名。

## 迁移分类

| 原调用 | 分类 | 5.33.0 入口 |
| --- | --- | --- |
| `Device.current` / `Device.identifier` | Model Identification | `PTDevice.current` |
| `Device.allPads` / `isPad` | Family / Layout | `PTDeviceCatalog.models(family: .iPad)` 与 `PTDevice.isPad` |
| `isSimulator` | Simulator | `PTDevice.current.isSimulator` |
| `batteryState` / `batteryLevel` | Battery | `PTDevice.current.batteryState` / `batteryLevel` |
| `isFaceIDCapable` / `isTouchIDCapable` | Biometrics | `PTDevice.current` 的动态系统能力属性 |
| 相机、NFC、运动、定位 | Capability | `await PTDevice.current.status(for:)` |

具体型号不再承担响应式布局决策。布局代码应优先使用 safe area、trait collection、size class 和实际 bounds。

## 检查范围

审计覆盖 `PooToolsSource`、`PooTools`、`Package.swift`、`PooTools.podspec`、`Package.resolved` 和 `Podfile.lock`。CI 使用 `Scripts/CI/check_devicekit_removed.sh` 阻止重新引入第三方模块。

## 隐私边界

PToolsDevice 不读取或上传序列号、UDID、设备名称、Apple ID 或用户指纹。未知设备只保留稳定运行时标识、平台、系统版本和运行环境。
