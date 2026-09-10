# PTools 5.9.6 依赖供应链实施报告

日期：2026-09-10  
基线：`5.9.5` / `000f7cb0`  
范围：`PooTools.podspec` 的 `default_subspec`（Core）及其构建入口

## 已完成

### DEP-596-01：移除 branch 依赖

- `Package.swift` 中 AttributedString 固定为
  `d8a72a7e29e8699979b052b59659720087bc2ea0`。
- `Package.swift` 中 SocketRocket 固定为
  `fe86ec01176ea3365ffa2d04a2bb6dd7a9e6c01e`。
- `Scripts/validate_branch_dependencies.sh` 通过，未发现 `branch:`。

### DEP-596-02：Kitura 依赖评估

代码扫描确认 `SwiftJWT` 只在 `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` 直接使用。
BlueCryptor、BlueRSA、BlueECC、LoggerAPI、KituraContracts 是 Swift-JWT 的传递依赖。
因此本批次完成两项收敛：

1. 从 `Package.swift` 删除 PooTools 未直接使用的 Kitura/LoggerAPI 包声明。
2. 保留 Swift-JWT 和现有 JWT 行为，避免在 5.9.x 重新实现签名逻辑。

CryptoKit/Security 替换列入 6.0 迁移，不在本批次冒险改变 Apple API 请求认证。

### DEP-596-03：SmartCodable / KakaJSON 双栈评估

- SmartCodable 继续作为 Core 和 Network 的主要类型化模型入口。
- KakaJSON 继续作为旧模型/旧请求兼容入口，不允许新并发执行器接收动态 `Any` 结果。
- 不删除公开兼容 API，不在 5.9.x 强制移动 Serialization 模块。
- 6.0 的替换前置条件是完成调用点盘点、模型迁移和真实宿主回归。

### DEP-596-04：Bugly 二进制框架

当前 `Pods/Bugly/Bugly.framework/Bugly` 是旧 Mach-O framework，没有 XCFramework；其架构包含
armv7、i386、x86_64 和 arm64，但没有 arm64 Simulator slice。它不再适合 iOS 17+ 的 Example
Simulator 构建。

本批次采取兼容且可回退的处理：

- 从 `Podfile` 移除旧 Bugly Pod。
- 通过 `pod install --no-repo-update` 更新 `Podfile.lock`，只移除 Bugly 条目。
- `PooTools/AppDelegate.swift` 使用 `#if canImport(Bugly)`，没有 Bugly 时示例仍可编译；有兼容 XCFramework 时保留启动代码。
- 生产宿主若需要 Bugly，必须接入供应商提供的 XCFramework，并通过 Simulator 与通用 device archive 验证。

### DEP-596-05：依赖所有权

已补齐根目录 `DEPENDENCIES.md`，包括模块边界、使用原因、维护风险、替换路线和当前验证状态。

## 当前验证

| 检查 | 状态 | 说明 |
| --- | --- | --- |
| `pod install --no-repo-update` | PASS | Bugly 移除，其余依赖未主动升级 |
| branch 扫描 | PASS | 无浮动 branch |
| SwiftPM manifest | PASS | `swift package dump-package` |
| 依赖专项门禁 | PASS | `Scripts/validate_dependencies_5_9_6.sh` |
| Xcode Debug / Release | BLOCKED | 外部 KituraContracts Swift 6 诊断；详见 `report/build_validation_5_9_6.md` |

## 阻断与边界

- Swift-JWT 的传递依赖仍可能在 CocoaPods 工程中触发 KituraContracts 的 Swift 6 诊断；删除 Ptools
  的重复 SPM 声明不能消除 CocoaPods 的传递依赖，因此不能把该外部错误宣称为源码通过。
- 本报告不修改 Pods 源码，不升级第三方版本，不宣称真实宿主或真机验证完成。
