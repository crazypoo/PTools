# Simulator 构建基线（5.31.2）

## 环境

| 项目 | 基线 |
| --- | --- |
| 平台 | iOS 17+ / Swift 6+ |
| Xcode | 27.2（27B5019j） |
| Swift | 6.4 |
| CocoaPods | 1.16.2 |
| Ruby | 3.3.5 arm64 |
| Mac 架构 | arm64 |
| 可用 Simulator Runtime | iOS 27.0、27.1、27.2 |
| Workspace | `PooTools.xcworkspace` |
| Scheme | `PooTools-Example` |

## 修复前现象

Simulator 构建集中出现以下模块解析失败：

`CryptoSwift`、`Lottie`、`Harbeth`、`Kakapos`、`SwiftJWT`、`SmartCodable`、`Kingfisher`、`PocketSVG`、`KakaJSON`、`DeviceKit`、`Alamofire`、`SnapKit`。

修复前的工程状态：

- `PooTools_Example` Compile Sources 包含 972 个 `PooToolsSource/**` 库源码。
- `PooTools_Example` Debug/Release 自定义 `MODULE_NAME = PooTools`。
- Example 配置开启 `DEFINES_MODULE` 和 `ENABLE_MODULE_VERIFIER`。
- Example 配置使用 `PooTools/PooTools-Swift.h` 作为 Swift Generated Header。
- Project 和 Example 配置硬编码 `SDKROOT = iphoneos`。
- Example 依赖部分第三方模块时依赖 `PooTools/InputAll` 的传递可见性。

## 5.31.2 修复后契约

- `PooTools_Example` Compile Sources 与 `PooToolsSource/**` 的交集必须为 0。
- App 模块名由 `PRODUCT_MODULE_NAME` 和构建目标决定，不能固定为 `PooTools`。
- SDK 必须由 `xcodebuild` destination 选择，工程不能固定 `iphoneos`。
- Simulator 不得通过排除 arm64 绕过依赖解析。
- Example 直接导入的第三方模块必须在 Podfile 显式声明；不存在交付依赖的 Debug 工具必须可选。

## 验证入口

```text
Scripts/CI/check_example_source_ownership.rb
Scripts/CI/build_cocoapods_simulator.sh
Scripts/CI/build_cocoapods_device.sh
```

最终验收需要记录 Debug/Release Simulator 和 Generic Device 的完整 Xcode 构建结果。Pods 自身或工具链错误必须与 PooTools 源码错误分开记录。

## 5.31.2 实际验证结果

| 构建入口 | 架构/目标 | 结果 |
| --- | --- | --- |
| CocoaPods Simulator Debug | arm64 / iOS Simulator 27.2 | PASS |
| CocoaPods Simulator Release | arm64 / iOS Simulator 27.2 | PASS |
| CocoaPods Device Debug | arm64 / iOS 27.2 Generic Device | PASS |
| CocoaPods Device Release | arm64 / iOS 27.2 Generic Device | PASS |

构建命令均通过 `PooTools.xcworkspace` 的 `PooTools-Example` scheme 完成。期间只观察到外部 Pods 的弃用或构建脚本警告，未发现 PooTools 源码错误；本轮未修改 Pods 源码。
