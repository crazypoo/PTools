<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: 7c37f5a9fe08f32af3161382c382b286f34e4096
Source version: 5.69.0
Source inputs digest: 3ba458becead5d2d41ea8e3574496c474e0917a20840d500c158002348916a15
Generator version: 1
Generator: manual Duo validation record maintained with the repository gates
Generated at: 2026-10-23T06:35:20Z
-->

# iPhone Duo 设备验收记录 / Aceptación de dispositivo / Device acceptance

## 运行环境 / Entorno / Environment

- 目标设备：Apple iPhone Duo Simulator，iOS 27.1。
- Simulator identifier：`9306D868-28E8-4D61-BBA5-173FBE0BD57F`。
- 目标：`PooTools-Example`，UIKit，iOS 17+ / Swift 6。
- 本记录只记录实际执行过的检查；静态报告和 Xcode 构建不会冒充真机视觉验收。

## 状态 / Estado / Status

| 场景 | 模拟器 | Device Hub／真机 | 结果 |
| --- | --- | --- | --- |
| Release App 安装、启动、基本画面截取 | 未测（本轮仅完成 Debug 构建） | 未测 | pending_device；历史版本的启动证据不复用到 5.69.0 |
| 外屏闭合 | 未测 | 未测 | 未测 |
| 内屏 portrait | 未测 | 未测 | 未测 |
| 内屏 landscape | 未测 | 未测 | 未测 |
| 部分折叠与 hinge reserved region | 未测 | 未测 | 未测 |
| 多 Scene／分屏 | 未测 | 未测 | 未测 |
| 键盘、Alert、Popover、ActionSheet | 未测 | 未测 | 未测 |
| PhotoPicker Done／权限 | 未测 | 未测 | 未测 |
| MediaViewer 四媒体连续翻页 | 未测 | 未测 | 未测 |
| ImageEditor／VideoEditor 控件与裁剪 | 未测 | 未测 | 未测 |
| RTL／Dynamic Type／VoiceOver | 未测 | 未测 | 未测 |
| Debug Console／Guide／Inspector | 未测 | 未测 | 未测 |

## 说明 / Notas / Notes

- 本轮已执行的构建：`PooTools-Example` iOS Simulator Debug 和 Release（均为 arm64、无签名）；未执行本轮 Duo Simulator 启动和视觉交互。
- 旧版本的 Simulator 启动截图和结果不作为 5.69.0 的验收证据；待官方 Duo Simulator、Device Hub 或实体设备可用后重新记录。
- SwiftPM `PToolsUIFoundationTests` 未在 macOS 主机上运行成功：`swift test` 使用 macOS SDK 编译 iOS-only UIKit target，因无法解析 `UIKit` 而停止；需要在 Xcode iOS Simulator test target 或 CI iOS runner 中执行。该结果不替代 Debug / Release App 构建，也不宣称 UI 测试通过。

English: Static inventory, geometry tests, and Xcode builds are tracked separately from device-only visual and interaction evidence.

Español: El inventario estático, las pruebas geométricas y las compilaciones Xcode se registran por separado de la evidencia visual e interactiva exclusiva del dispositivo.

中文：静态清单、几何测试和 Xcode 构建与设备专属的视觉、折叠和交互证据分开记录。
