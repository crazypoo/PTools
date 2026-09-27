# DeviceKit → PToolsDevice 迁移

## 直接替换

| DeviceKit | PToolsDevice |
| --- | --- |
| `Device.current` | `PTDevice.current` |
| `Device.identifier` | `PTDevice.current.identifier` |
| `Device.current.model` | `PTDevice.current.specification?.marketingName` |
| `Device.current.isSimulator` | `PTDevice.current.isSimulator` |
| `Device.current.isPad` | `PTDevice.current.isPad` 或 UIKit trait |
| `Device.allPads` | `PTDeviceCatalog.models(family: .iPad)` |
| 机型 Bool 能力判断 | `await PTDevice.current.status(for:)` |

## 兼容入口

Core 中的 `deviceInfo`、`deviceIsSimulator`、`allIPadDevices` 等旧全局入口仍然存在，但底层已是 `PTDevice` 和 `PTDeviceModel`。新代码直接使用 `PTDevice`，不要重新暴露 DeviceKit 类型别名。

## 线程与权限

`PTDevice` 的身份字段是 Sendable 值。相机、麦克风、NFC、定位和运动能力可能受系统权限影响，使用 async capability API；UI 展示回到 `MainActor`。不要把 `AVCaptureDevice`、`CLLocationManager` 或 `LAContext` 放进业务模型跨 actor 传递。

## CocoaPods

```ruby
pod 'PooTools/Device', :path => '../PTools'
```

完整 `PooTools/Core` 会自动依赖 `PooTools/Device`。不再添加 `DeviceKit`。
