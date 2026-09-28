# PTools 5.35.0 P1 示例入口

示例按能力分为：

- `ThemeGallery`
- `ContentStateDemo`
- `FormDemo`
- `BluetoothDemo`
- `DocumentsDemo`
- `SimulationDemo`
- `AccessibilityDemo`

这些目录只描述宿主集成边界，不把演示代码编译进发布模块。需要真实 UI、系统权限或 BLE 时，应在 `PooTools-Example` 中按需挂载对应 CocoaPods subspec，并使用真实 Simulator/Device 场景验证。
