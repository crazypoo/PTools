# PTModel 5.58.0 Fixture / Compatibility Matrix

## Fixture 族

| Fixture | 输入 | 目标 | 当前边界 |
| --- | --- | --- | --- |
| Codable-only | JSON/Data | `PTModelDecoder` / `PTModelEncoder` | Core 主路径 |
| SmartCodable legacy | 旧引用模型 | `PTNetworkLegacyResponseDecoder.smartCodable` | MainActor 兼容层 |
| KakaJSON legacy | `PTBaseModel` / KakaJSON 模型 | `PTNetworkLegacyResponseDecoder.kakaJSON` | MainActor 兼容层 |
| Mixed app | Codable + legacy model | typed response + legacy adapter | 不让 legacy `Any` 进入 transport actor |
| PTModel-only | `PTStaticModel` / `@PTModel` | static schema / patch / migration | SwiftPM 宏；Pods 手写 fallback |

## 回归规则

每个 fixture 至少验证 JSON/Data 输入、模型输出、错误类型和取消/生命周期边界。
第三方 fixture 必须在宿主工程和实际依赖版本可用时执行；仅有 Core 编译通过不能
代替 SmartCodable/KakaJSON 行为等价性证明。

## 当前结果

- Codable-only、PTModel-only 的 Core contract 已有 XCTest 覆盖。
- legacy decoder 的边界已经类型化，但真实 SmartCodable/KakaJSON 类 fixture 仍需要
  CocoaPods/Example 宿主执行，不能在 macOS Foundation-only runner 中伪造通过。
