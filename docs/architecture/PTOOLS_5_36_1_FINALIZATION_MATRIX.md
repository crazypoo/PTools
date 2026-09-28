# PTools 5.36.1 收口矩阵

| 层级 | 唯一入口 | 静态/Simulator | 真机或宿主回归 |
| --- | --- | --- | --- |
| P0 | Connectivity / Keychain / Notification / Route / BackgroundTasks | Package、Xcode、兼容解码和配置测试 | 通知授权、推送路由、BGTask、URLSession 恢复、多 Scene |
| P1 | ContentState / Form / Documents / Provider | Provider 合同、表单稳定 ID、PDF 选择性桥接 | BLE、文档权限、VoiceOver、Dynamic Type、RTL |
| P2 | Feedback / AppIntents / WidgetCore / Activities | extension-safe 静态检查、值类型测试、示例 parse | 触觉/音频、Siri、Widget timeline、Live Activity、锁屏隐私 |

## 构建入口

- SwiftPM：Foundation-only target 运行 `swift build`；UIKit target 必须使用 iOS SDK/Xcode。
- CocoaPods：`PooTools.podspec` 读取根目录 `VERSION`，不修改第三方源码。
- Xcode：`PooTools-Example` 使用 iOS Simulator Debug/Release；外部 Pods 警告单独报告。
- Extension：使用 `Example/Extensions/extension_targets.json` 建立宿主 target，不能把示例源码直接
  混入普通 App target。
