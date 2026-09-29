# PTModel 5.58.0 使用指南

## 目标

`PToolsModelCore` 是 iOS 17+ / Swift 6 的 Foundation-only 模型边界。它不依赖
SmartCodable、KakaJSON、UIKit 或运行时反射，现阶段与旧 Core 并存，方便逐步迁移。

## 一行式转换

```swift
struct User: Codable {
    let id: Int
    let name: String
}

let user = try User.pt.model(from: #"{"id":1,"name":"Jax"}"#)
let users = try User.pt.models(from: #"[{"id":1,"name":"Jax"}]"#)
let json = try user.pt.jsonString()
let data = try user.pt.jsonData()
let dictionary = try user.pt.dictionary()
```

## Foundation 输入

```swift
let user = try User.pt.model(from: [
    "id": 1,
    "name": "Jax"
] as [String: Any])
```

`Data`、JSON `String`、`NSDictionary`、`NSArray` 和 `PTJSONValue` 都可以作为输入。
Foundation 容器只在兼容桥接入口使用；核心 JSON 值始终使用 `PTJSONValue`。

## 严格程度

```swift
let decoder = PTModelDecoder(policy: .strict,
                             duplicateKeyPolicy: .reject,
                             limits: PTModelLimits(maxInputBytes: 4 * 1024 * 1024,
                                                   maxDepth: 64))
let user = try decoder.decode(User.self, from: data)
```

- `strict`：解析失败直接返回错误。
- `compatible`：保留 Codable 主路径，并对顶层基础类型提供安全容错转换。
- `lossy`：保留策略契约，集合丢弃和字段级恢复将在后续 5.58.x 阶段接入静态 Schema。

## 迁移边界

5.58.0 不修改 `PTBaseModel`、Network 旧入口或 SmartCodable/KakaJSON 依赖。新代码可先依赖
`PToolsModelCore`，确认行为后再迁移业务模型；旧模型继续通过原有 Core 路径运行。
