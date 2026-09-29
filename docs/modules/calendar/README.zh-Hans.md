---
module: "Calendar"
module_id: "calendar"
language: "zh-Hans"
status: "compatibility"
minimum_ios: "17.0"
swift: "6+"
swiftpm_product: "null"
cocoapods_subspec: "Calendar"
source: "manifest-only"
category: "compatibility"
last_reviewed: "2026-09-28"
canonical: false
canonical_source: "README.en.md"
product_version_source: "repository:VERSION"
document_schema_version: 1
---

# Calendar

## 1. 概览

Calendar 是 PTools 的 compatibility 模块。本指南由 canonical 模块 registry 生成，说明 iOS 17+ 与 Swift 6+ 下的稳定使用边界。

## 2. 要求

- 平台：iOS 17.0+
- Swift：6+
- 分类：`compatibility`
- 状态：`compatibility`

## 3. 安装

Swift Package Manager：

```swift
// This entry is CocoaPods-only; import the module exposed by the selected subspec.
```

CocoaPods：

```ruby
pod 'PooTools/Calendar'
```

## 4. 导入

```swift
// This entry is CocoaPods-only; import the module exposed by the selected subspec.
```

## 5. 快速开始

优先选择最小的 product 或 subspec。registry 中的名称是 `Calendar`，不要猜测没有发布的 product 或依赖。

## 6. 核心概念

公开边界优先使用值类型。registry 记录的直接依赖：None declared by the registry.。

## 7. 主要 API

只使用源码中稳定的公开符号。完整符号数据属于自动生成的 API 报告，不在手写指南中重复维护。

## 8. 常见场景

常见场景应保持在本模块分类内，不要复制其他 PTools 模块已经提供的 canonical 实现。

## 9. 高级用法

只有公开 API 提供 Provider 或策略时才注入；不要访问内部状态，也不要改变 UIKit 的私有所有权。

## 10. Swift 并发

UI 工作使用 `@MainActor`；共享值应遵守 `Sendable`；取消必须沿所属 `Task` 传播。

## 11. 生命周期

遵守模块的 start/stop、register/unregister 和 Scene 生命周期约定，不要让宿主控制器被不必要地长期持有。

## 12. 错误处理

显式处理公开错误。可恢复错误应交还宿主，权限和配置失败不能被静默吞掉。

## 13. 权限 / Entitlement / Info.plist

除非源码暴露平台权限、Entitlement、后台模式或 Info.plist key，否则本模块没有额外配置。

## 14. 模拟器行为

硬件、通知、后台、音频、相机或扩展宿主在模拟器中的行为可能不同；这些能力必须用真机验证。

## 15. 无障碍

UI 集成必须保留 Dynamic Type、VoiceOver、Reduce Motion、Reduce Transparency 和 RTL 行为。

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
