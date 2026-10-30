<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: feature/pr46-pr50-inspector-layout-governance-20261030
Source revision: 0deb064cea510c896e78b35fab0997808e796173
Source version: 5.69.0
Source inputs digest: 8c745967288dcd0493111e7ec716d9f601938762a8f52bae2525c7d3591bb455
Generator version: 1
Generator: manual Duo validation record maintained with the repository gates
Generated at: 2026-10-30T03:42:31Z
-->

# iPhone Duo 设备验收记录 / Aceptación de dispositivo / Device acceptance

## 运行环境 / Entorno / Environment

- Xcode：27.2（build 17C5046f）。
- iOS Simulator SDK：27.2。
- 目标设备：Apple iPhone Duo Simulator，当前可用标识为 `839697B5-EE5E-44F5-A53C-C9F9964124BE`。
- 目标：`PooTools-Example`，UIKit，iOS 17+ / Swift 6。
- 本记录只记录实际执行过的检查；静态报告和 Xcode 构建不会冒充设备视觉验收。

## 启动结果 / Resultado de arranque / Boot result

| 设备 | 操作 | 结果 |
| --- | --- | --- |
| iPhone Duo Simulator `839697B5-EE5E-44F5-A53C-C9F9964124BE` | `simctl boot` + `simctl bootstatus -b` | blocked: `Data Migration Failed` |

未执行擦除模拟器或破坏性恢复；该环境问题需要保留设备数据后由 Xcode/Simulator 工具链处理。Duo 专属运行、视觉和交互结果不能由普通 iPhone 模拟器替代宣称通过。

## 状态 / Estado / Status

| 场景 | 模拟器 | Device Hub／真机 | 结果 |
| --- | --- | --- | --- |
| Release App 安装、启动、基本画面截取 | 未执行（Release 构建已通过） | 未测 | pending_device |
| 外屏闭合 | 未测 | 未测 | pending_device |
| 内屏 portrait | 未测 | 未测 | pending_device |
| 内屏 landscape | 未测 | 未测 | pending_device |
| 部分折叠与 hinge reserved region | 未测 | 未测 | pending_device |
| 多 Scene／分屏 | 未测 | 未测 | pending_device |
| 键盘、Alert、Popover、ActionSheet | 未测 | 未测 | pending_device |
| PhotoPicker Done／权限 | 未测 | 未测 | pending_device |
| MediaViewer 四媒体连续翻页 | 未测 | 未测 | pending_device |
| ImageEditor／VideoEditor 控件与裁剪 | 未测 | 未测 | pending_device |
| RTL／Dynamic Type／VoiceOver | 未测 | 未测 | pending_device |
| Debug Console／Guide／Inspector | 未测 | 未测 | pending_device |

## 已完成的非设备证据 / Evidencia no-device / 非设备证据

- 当前 HEAD 的 Duo 静态审计、严格策略、报告新鲜度和源码契约检查通过。
- `PooTools-Example` iOS Simulator Debug / Release 完整构建通过；该结果只证明编译和链接，不证明 Duo 布局、折叠区域、触控或媒体行为。
- Duo 模拟器在启动阶段因 `Data Migration Failed` 阻断；没有伪造截图、XCTest、XCUITest、Instruments 或真机结果。
- 工作区当前没有包含 `Tests/` 的 Xcode test scheme/testable target，因此没有把 macOS `swift test` 或测试源码存在误报为 iOS XCTest 通过。

English: Duo-specific runtime and visual acceptance remains blocked by the simulator migration failure.

Español: La aceptación de ejecución y visual específica de Duo sigue bloqueada por el fallo de migración del simulador.

中文：Duo 专属运行和视觉验收仍被模拟器数据迁移失败阻断。
