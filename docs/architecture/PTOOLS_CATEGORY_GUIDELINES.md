# PTools Category 规范

## 适用范围

本规范覆盖 `PooToolsSource/Category` 以及由 Core 暴露给其他模块的基础扩展。目标平台为 iOS 17+，语言模式为 Swift 6。

## 设计规则

1. 优先使用 Swift 标准库、Foundation 和 UIKit 原生 API。
2. 新方法使用 Swift API Design Guidelines 命名，不新增 `getXxx`、`toXxx2`、`xxx_oc` 等别名。
3. 集合扩展保持顺序和失败语义明确；无效下标返回 nil 或安全忽略，不能强制解包。
4. Foundation/Swift 集合扩展不标记 `@MainActor`；UIKit 可变状态方法明确位于 `@MainActor`。
5. 通用同步闭包不无条件添加 `@Sendable`；只有跨并发域时才添加。
6. 不复制第三方扩展库的整套实现；确需参考时以行为、复杂度和边界测试为依据独立实现。

## 当前 canonical API

- 去重：`Sequence.removingDuplicates(by:)`
- 安全交换：`Array.safeSwap(from:to:)`
- 深层字典：`Dictionary.value(at:)` / `setValue(_:at:)`
- JSON：`jsonData(options:)` / `jsonString(options:)`
- URL query：`queryItems` / `queryValue(for:)` / `appendingQueryItems(_:)`
- UIKit 子视图：`addSubviews` / `removeAllSubviews`
- UIKit 响应链：`parentViewController` / `firstResponder()`

## 评审清单

- 是否已有标准库或 PTools 等价实现？
- 是否会和 Foundation、UIKit、常见第三方库产生方法歧义？
- 空集合、nil、非法下标和无效 URL 是否有明确结果？
- 是否引入隐藏的主线程要求或非 Sendable 状态？
- 是否提供最小行为验证和迁移说明？
