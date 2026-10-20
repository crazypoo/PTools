---
module: "CodeView"
module_id: "code-view"
language: "zh-Hans"
status: "stable"
minimum_ios: "17.0"
swift: "6+"
swiftpm_product: "PooToolsCodeView"
cocoapods_subspec: "CodeView"
source: "PooToolsSource/CodeView"
category: "ui-leaf"
last_reviewed: "2026-10-20"
canonical: false
canonical_source: "README.en.md"
product_version_source: "repository:VERSION"
document_schema_version: 1
---

# CodeView

## 1. 概览

CodeView 是 PTools 的稳定 UI-leaf 模块。本指南由 canonical 模块 registry 生成，说明 iOS 17+ 与 Swift 6+ 下的稳定使用边界。

## 2. 要求

- 平台：iOS 17.0+
- Swift：6+
- 分类：`ui-leaf`
- 状态：`stable`
- 平台边界：该 UIKit 视图面向 iOS 提供；模块不暴露 watchOS 或 macOS UIKit target，也不声明 visionOS 支持。

## 3. 安装

Swift Package Manager：

```swift
import PooToolsCodeView
```

CocoaPods：

```ruby
pod 'PooTools/CodeView'
```

## 4. 导入

```swift
import PooToolsCodeView
```

## 5. 快速开始

SwiftPM 使用 `PooToolsCodeView`，CocoaPods 使用 `PooTools/CodeView`。模块支持本地生成、宿主提供文本和宿主提供图片三种显示来源。

## 6. 核心概念

模块只依赖 PTools Core 边界，不负责下载或解码远程媒体；网络工作由宿主完成，再把文本或图片交给控件显示。

## 7. 主要 API

本地生成使用 `PTCodeView(numberOfCodes:numberOfLines:changeTimes:)`；`changeTimes` 是以秒为单位的自动刷新间隔，传入 `0` 可关闭自动刷新。外部文本使用 `setCode(_:)`，图片使用 `setCodeImage(_:)`，程序化刷新使用 `requestRefresh()`。外部刷新通过 `onRefreshRequested` 回调，本地刷新通过 `codeBlock` 回调。

```swift
let codeView = PTCodeView(numberOfCodes: 4, numberOfLines: 3, changeTimes: 0)
codeView.setCode("SERVER-001")
codeView.onRefreshRequested = { view, reason in
    view.setCode("SERVER-002")
}
```

## 8. 常见场景

常见场景应保持在本模块分类内，不要复制其他 PTools 模块已经提供的 canonical 实现。

## 9. 高级用法

只有公开 API 提供 Provider 或策略时才注入；不要访问内部状态，也不要改变 UIKit 的私有所有权。

## 10. Swift 并发

UI 工作使用 `@MainActor`。`PTCodeRefreshReason` 遵守 `Sendable`，外部回调保持在控件所属 actor。控件离开 window 或应用进入后台时会取消自动刷新。

## 11. 生命周期

遵守模块的 start/stop、register/unregister 和 Scene 生命周期约定，不要让宿主控制器被不必要地长期持有。

## 12. 错误处理

显式处理公开错误。可恢复错误应交还宿主，权限和配置失败不能被静默吞掉。

## 13. 权限 / Entitlement / Info.plist

除非源码暴露平台权限、Entitlement、后台模式或 Info.plist key，否则本模块没有额外配置。

## 14. 模拟器行为

硬件、通知、后台、音频、相机或扩展宿主在模拟器中的行为可能不同；这些能力必须用真机验证。

## 15. 无障碍

控件提供名为“刷新验证码”的 VoiceOver 自定义操作，并让图片视图保持不可交互。验证码不适合播报时，宿主应提供合适的无障碍标签。

## 16. 性能

非 UI 工作不要放到主 actor。按照所属服务限制内存、缓存、媒体和网络资源。

## 17. 隐私与安全

不要记录 token、Cookie、凭据、隐私 payload 或完整用户输入；敏感数据使用类型化边界。

## 18. 与其他 PTools 模块集成

优先复用已有 PTools canonical service 和 adapter，不要再创建并行缓存、路由、权限或调度器。

## 19. 迁移

5.x 期间保留兼容包装器；新代码应使用当前 registry 文档中的 canonical 入口。

## 20. 问题排查

遇到异常时先检查模块选择、target membership、Scene context、权限、取消状态和生成报告，再修改源码。

## 21. 示例工程

参见 Example 工程和领域测试 registry 获取可执行覆盖。宿主专属 Entitlement 仍由宿主负责。

## 22. 相关文档

[文档索引](../../index/README.zh-Hans.md) · [架构](../../architecture/ARCHITECTURE.md) · [质量](../../maintainers/QUALITY.md)
