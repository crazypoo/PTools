# PTools 5.60 Network / Router 分层收口

> English: This document records the 5.60 implementation boundary for Network and Router.
>
> Español: Este documento registra los límites de implementación de Network y Router en 5.60.
>
> 中文：本文记录 5.60 版本 Network 与 Router 的实现边界。

## Network

`Network.swift` 保留配置、Session 和旧公开入口的兼容外观；新能力按职责落在以下文件：

- `Network+TypedRequest.swift`：Codable、PTModel、类型化上传和响应解析入口。
- `Network+LegacyCompatibility.swift`：旧 `Any`、KakaJSON 和 callback API 的转发层。
- `NetworkUploads.swift`：上传与下载的既有传输实现；后续新增上传能力应继续复用这里的执行器。
- `PTNetworkModelBridge.swift`：模型响应解码和 `modelPath` 错误语义。
- `PTNetworkResponseSelection.swift`：路径选择、路径缺失和路径类型不匹配。

新的响应路径错误必须保持三种语义：

| 情况 | 错误 |
| --- | --- |
| 路径不存在 | `modelPathNotFound` |
| 路径遍历遇到错误类型 | `modelPathTypeMismatch` |
| 已选中的值无法解码成 Model | `modelDecodeFailed` |

`PTNetworkResponseSelection` 不负责传输、缓存、重试或日志；传输层也不得反向依赖 UIKit 页面。

## Router

Router 的职责边界如下：

- `PTRouter.swift`：公开兼容入口、请求解析和旧行为保持。
- `PTRouterMatcher.swift`：URL / pattern 匹配和参数提取。
- `PTRouterResolver.swift`：路由配置到 ViewController 的解析。
- `PTRouterNavigator.swift`：`@MainActor` UI 跳转副作用。
- `PTRouterLegacyCompatibility.swift`：5.x 服务注册、服务获取和 `routeJump` 兼容入口。

旧 API 仍然保留，新的代码应优先使用解析后的类型化请求和 `@MainActor` 导航入口。Router Core 不得依赖 PhotoPicker、Media、业务页面或其他上层模块。

## 验证边界

- Swift 6 / iOS 17+ 源码通过 Xcode workspace Debug / Release 编译后，才能宣称源码构建通过。
- SwiftPM 测试若被外部 Kakapos 解析记录冲突阻断，应记录为环境阻断，不修改第三方版本或 `Package.resolved` 绕过。
- 真实宿主、真机、多 Scene、长会话和 Instruments 数据必须由可运行的宿主环境补齐；静态检查和 Simulator 编译不替代这些证据。
