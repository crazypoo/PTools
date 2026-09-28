# PTools 5.35.0 P1 高阶能力架构

5.35.0 在既有 `PToolsCore` / `PToolsUIFoundation` 基础上补齐表单、主题、页面状态、无障碍、BLE、文档和确定性模拟能力。所有模块面向 iOS 17+ / Swift 6+，不引入新的第三方运行时依赖。

## 分层

```text
PToolsUIFoundation
├── PToolsTheme
├── PToolsAccessibility
└── PToolsContentState
    └── PToolsForm

Foundation / system frameworks
├── PToolsBluetooth
├── PToolsDocuments
└── PToolsSimulationCore
    └── PToolsSimulation
```

Theme、Accessibility 和 ContentState 不依赖 Network、Debug、LocalConsole 或宿主业务协议。Form 只消费 Core、Theme、ContentState 和 Accessibility；它不把第三方输入控件类型泄漏到公共模型。Bluetooth 不包含 CrazyDashboard、XP400、YMOBD 或 OBD 协议。Documents 不持有业务存储单例。Simulation 只通过 Provider 合约注入替身，Release 默认关闭。

## 模块职责

| 模块 | Canonical API | 关键能力 |
| --- | --- | --- |
| Theme | `PTTheme`, `PTThemeResolver`, `PTThemeScope` | 语义颜色、Dynamic Type、材质、玻璃降级和作用域 |
| Accessibility | `PTAccessibilityFocusCoordinator` | 环境快照、焦点、公告和启发式审计 |
| ContentState | `PTContentState`, `PTContentStateView` | idle/loading/content/empty/error/offline、旧内容和重试 |
| Form | `PTFormEngine`, `PTFormViewController` | 稳定 ID、依赖、校验、取消和提交 |
| Bluetooth | `PTBluetoothCentral`, `PTBluetoothConnection` | 扫描、连接、GATT、通知、重连、状态恢复和诊断 |
| Documents | `PTDocumentPickerCoordinator`, `PTDocumentAccess` | picker、UTType、安全作用域、bookmark、QuickLook |
| Simulation | `PTSimulationRuntime`, `PTSimulationClock` | 手动时钟、确定性回放、Mock Provider 和显式启用 |

## 并发边界

- 公共配置、状态快照和事件均为 `Sendable` 值类型。
- UIKit、QuickLook 和 CoreBluetooth delegate 对象分别留在 MainActor 或内部系统对象边界。
- Form、Bluetooth、Documents bookmark 和 Simulation runtime 的共享状态由 actor 管理。
- 取消、超时和代际检查在请求完成前生效，旧结果不能覆盖新状态。
- 没有新增业务级 `@unchecked Sendable` 或 `nonisolated(unsafe)`。

## 主题和无障碍

`PTTheme` 只保存可跨 actor 传递的值；`PTThemeResolver` 在 MainActor 上依据 trait collection、Dynamic Type、High Contrast、Reduce Transparency 和 Reduce Motion 生成 UIKit 对象。玻璃材质不可用或用户降低透明度时自动回退为系统 material 或不透明颜色。

`PTAccessibilityEnvironment` 是 UI 环境快照，不把 UIKit 对象跨 actor 传递。Alert、Popover、Guide 等宿主可使用 `PTAccessibilityFocusCoordinator.move(to:)`，关闭时通过 `capture()` / `restore()` 恢复焦点。

## 页面状态和表单

`PTContentState` 允许 loading/offline 保留旧内容；视图层只负责表现，网络层和业务层负责产生状态。`PTFormEngine` 使用 `PTFormFieldID` 作为稳定身份，校验任务按字段取消并由 generation 防止过期结果回写。`PTFormViewController` 使用 diffable collection view，不伪造业务数据源。

## 系统服务

`PToolsBluetooth` 只提供通用 BLE 基础设施。业务协议应在宿主中另建适配器，将 UUID、帧格式和领域状态转换为 Bluetooth 模块的值类型。

`PToolsDocuments` 统一安全作用域生命周期：进入 `withSecurityScopedAccess` 后使用 URL，闭包返回即停止访问。Bookmark 解析遇到 stale 会重新生成并返回新的 bookmark 数据。

`PToolsSimulationCore` 与真实 Provider 解耦。`PTSimulationEnvironment(isEnabled: false)` 是默认值；宿主只有在 Demo/Test 配置中显式启用，才能安装场景和回放。

## 发布入口

SwiftPM products：`PToolsTheme`、`PToolsAccessibility`、`PToolsContentState`、`PToolsForm`、`PToolsBluetooth`、`PToolsDocuments`、`PToolsSimulationCore`、`PToolsSimulation`。

CocoaPods subspec：`Theme`、`Accessibility`、`ContentState`、`Form`、`Bluetooth`、`Documents`、`SimulationCore`、`Simulation`。`SimulationCore` 是为了保持 SwiftPM 和 CocoaPods 的最小依赖边界；`Simulation` 仅依赖它。

模块关系和有意差异由 `Scripts/module_registry.json` 与 `report/current/module_parity.*` 管理，不能通过手工删除报告来绕过门禁。
