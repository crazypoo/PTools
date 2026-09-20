# PTools 测试矩阵

本矩阵对应 5.19.x 的领域测试计划。它区分已经存在的 SwiftPM/XCTest 契约测试、只适合
iOS 宿主或真机验证的场景，以及尚未建立独立 target 的领域。矩阵不通过创建空壳测试 target
伪装覆盖率；缺口必须在发布前有明确的验证方式和负责人。

## Domain matrix

| Domain | SwiftPM/XCTest target | 当前验证 | 主要缺口 | 5.19 处理 |
| --- | --- | --- | --- | --- |
| `PToolsCoreTests` | `Tests/PooToolsCoreTests` | Core 契约测试 | 真实宿主和并发运行时 | 保留并纳入 SwiftPM Debug/Release |
| `PToolsUIFoundationTests` | `Tests/PToolsUIFoundationTests` | UIKit/UIFoundation 契约测试 | Simulator 视觉和 Dynamic Type | 保留并纳入 Simulator |
| `PToolsNavigationTests` | `Tests/PToolsNavigationTests` | 导航栏和转场回归 | 交互式手势和多 Scene | 保留并补充人工宿主验证 |
| `PToolsCollectionTests` | `Tests/PToolsListTests` | `PTCollectionView`/列表质量扫描 | 真实滚动、骨架和大数据量 | 以现有 target 作为兼容映射，不新增空 target |
| `PToolsNetworkTests` | `Tests/PToolsNetworkTests` | 请求契约、取消和日志扫描 | 真实服务、弱网和 TLS | 保留并由 Example/Mock 服务补充 |
| `PToolsSocketTests` | — | 静态契约和构建入口 | 真机连接、重连、前后台 | 记录为宿主/真机门禁 |
| `PToolsSecurityTests` | — | 静态 API 边界扫描 | Keychain、Secure Enclave 和真机权限 | 记录为真机门禁 |
| `PToolsMediaTests` | `Tests/PToolsMediaTests` | MediaCore/媒体契约测试 | PhotoKit、iCloud、相机和内存峰值 | 保留并纳入 Simulator/真机场景 |
| `PToolsPermissionTests` | `Tests/PToolsPermissionTests` | 权限状态和 completion 契约 | 系统弹窗、restricted/limited 真机状态 | 保留并纳入真机场景 |
| `PToolsSystemTests` | — | 构建入口和源码契约 | Scene、通知、HealthKit、CoreNFC | 记录为真实宿主/真机门禁 |
| `PToolsWebKitTests` | — | 源码和依赖边界扫描 | WebKit 页面、导航和 cookie | 记录为 Simulator 宿主门禁 |
| `PToolsDebugTests` | — | Debug/LocalConsole 静态与构建检查 | 多 Scene、日志洪峰和开关生命周期 | 记录为 Debug Example 门禁 |
| `PToolsInstrumentsTests` | — | Instruments 契约和报告结构检查 | 真机 trace、内存和长时间采样 | 记录为 Instruments 手工门禁 |

## 运行分层

1. `swift package test` 覆盖已有的七个契约 target。
2. Xcode Simulator Debug/Release 覆盖 UIKit、列表、导航、媒体和权限编译入口。
3. 真实宿主和真机覆盖系统弹窗、PhotoKit、Keychain、Socket、WebKit、Debug 和 Instruments。
4. 没有独立 target 的领域不得被报告为“自动化通过”；只能标记为静态、宿主或真机门禁。

## 维护规则

- 新增领域 target 前，必须有至少一个非空、可重复的行为契约测试。
- target 重命名必须先在本文件增加兼容映射，再更新 `Package.swift` 和迁移文档。
- 质量脚本 `Scripts/validate_test_matrix.sh` 校验领域清单、现有目录和兼容映射。
- 测试 target 不改变发布模块的 CocoaPods/SwiftPM parity。

