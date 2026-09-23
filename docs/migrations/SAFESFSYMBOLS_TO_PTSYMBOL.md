# SafeSFSymbols 到 PToolsSymbols 迁移指南

## 推荐写法

```swift
import PToolsSymbols

let image = UIImage(ptSymbol: .checkmark)
let imageWithFallback = UIImage.pt_symbol(.person, fallback: .personCircle)
let dynamic = PTSymbol(rawValue: serverSymbolName)
let dynamicImage = UIImage(ptSymbol: dynamic)
```

`PTSymbol` 是 `RawRepresentable`、`Hashable`、`Codable`、`Sendable` 值类型；它不实现字符串字面量
协议，避免把任意字符串误当作静态目录项。运行时名称可使用 `PTSymbol(rawValue:)` 或
`PTSymbol.appending(_:)`。

## 迁移规则

1. 将 SafeSFSymbols 的静态链式符号替换为 `PTSymbol` 生成目录中的静态属性。
2. 需要新系统回退时，使用 `UIImage.pt_symbol(_:fallback:)`，不要使用 `!`。
3. 变量值统一传入 `UIImage(ptSymbol:variableValue:configuration:)`；值会被限制在 `0...1`。
4. 服务端或用户配置名称保留动态 raw value，但不要把它加入静态代码白名单之外的固定调用。
5. 跨 actor 传递 `PTSymbol`，不要传递 `UIImage` 或 UIKit 配置对象。

## 兼容入口

`UIImage(_ symbol: PTSymbol)`、点大小和字体权重初始化器继续保留，用于降低 5.x 迁移成本。新代码
优先使用可失败的 `UIImage(ptSymbol:)` 或带回退的 `UIImage.pt_symbol`。5.24.0 不删除既有 PTools
公开入口。
