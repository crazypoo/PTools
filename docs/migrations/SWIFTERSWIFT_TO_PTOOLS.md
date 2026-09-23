# SwifterSwift 到 PTools 的迁移指南

适用版本：PTools 5.23.0，最低 iOS 17，Swift 6。

## 迁移原则

- 业务代码优先使用 PTools canonical API 或 Foundation/UIKit 原生 API。
- 不复制整套 SwifterSwift 扩展；只迁移实际使用且能改善安全性或复杂度的能力。
- UIKit 扩展在主线程使用，Foundation/Swift 集合扩展不强行标记 `@MainActor`。
- 旧公开入口保持可用；本轮只在 PTools 内部收口，不删除既有业务符号。

## 常用替换

旧：

```swift
array.filterDuplicates { $0.id }
```

新：

```swift
array.removingDuplicates { $0.id }
```

旧：

```swift
view.addSubviews([titleLabel, imageView])
view.removeSubviews()
```

新：

```swift
view.addSubviews(titleLabel, imageView)
view.removeAllSubviews()
```

旧：

```swift
dictionary.setValue(keys: ["user", "profile", "name"], newValue: "Jax")
```

新：

```swift
dictionary.setValue("Jax", at: ["user", "profile", "name"])
```

旧：

```swift
url.queryParameters
```

新：

```swift
url.queryValue(for: "page")
url.appendingQueryParameters(["page": "2"])
```

## 明确不迁移的能力

不加入 `unsafeString`、可选运算符、随机删除、frame sugar、标准库已有的 `all/any` 包装器和 GCD 并行 helper。Swift 6 并发场景使用 `TaskGroup`、`async let`、actor 或 `AsyncSequence`。

## 兼容说明

`filterDuplicates`、`handleFilter`、`allKeys`、`allValues` 和 `asJsonStr` 等旧 PTools 方法仍保留。`allKeys`/`allValues` 不再隐式打乱顺序；需要随机顺序时显式调用 `shuffledKeys()` / `shuffledValues()`。
