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

## 77.5 语义增强

### Missing / Null / Value

需要区分“字段未出现”和“字段明确为 null”时，使用 `PTPresence` 以及键控容器辅助方法：

```swift
struct UserPatch: Codable {
    let nickname: PTPresence<String>

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nickname = try container.decodePresence(String.self, forKey: .nickname)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nickname, forKey: .nickname)
    }

    private enum CodingKeys: String, CodingKey { case nickname }
}
```

`.missing` 会省略字段，`.null` 会输出 JSON `null`，`.value` 输出实际值。普通 Optional 的 nil 行为需要在字段编码处显式指定：

```swift
try container.encode(optionalValue, forKey: .nickname, nilStrategy: .null)
```

### 限制、路径和容错集合

```swift
let decoder = PTModelDecoder(
    limits: PTModelLimits(maxStringBytes: 64 * 1024,
                          maxCollectionCount: 1_000,
                          maxObjectKeyCount: 256,
                          maxNumberDigits: 128),
    coercionPolicy: PTValueCoercionPolicy(stringToNumber: true,
                                          numberToString: true,
                                          boolToInteger: false,
                                          yesNoToBool: false)
)

let path = try PTJSONPath.parse("$.items[0].name")
let name = try json.requiredValue(at: path)
let values = try decoder.decodeArray(String.self,
                                     from: jsonArray,
                                     strategy: .skipInvalid)
```

解析限制失败会抛出类型化 `PTModelError`，不会使用 `fatalError` 或 `precondition`。`PTLossyCollectionStrategy.preserveIndexAsNil` 应配合 `decodeOptionalArray` 使用。

### 字典、Set 和别名

```swift
let decoder = PTModelDecoder(dictionaryKeyStrategy: .losslessStringConvertible)
let values = try decoder.decodeDictionary(Int.self, String.self, from: object)

let encoder = PTModelEncoder(dictionaryKeyStrategy: .losslessStringConvertible)
let dictionaryJSON = try encoder.encode(dictionary: [1: "one"])
let setJSON = try encoder.encode(set: Set([3, 1, 2]))

let mapping = PTModelKeyMapping(decodeKeys: ["user_id", "uid"], encodeKey: "user_id")
let id = try decoder.decodeAliased(Int.self, from: object,
                                  mapping: mapping,
                                  conflictPolicy: .preferCanonical)
```

Set 的 JSON 表示是数组；编码结果使用 canonical JSON 字符串排序以保证可复现，但业务层不应依赖 Set 的语义顺序。

### Network 类型化响应

新请求管线可以保留原始 `Data`，按调用方选择 decoder：

```swift
let request = PTNetworkRequest(url: endpoint)
let (_, user) = try await PTNetworkExecutor.shared.execute(
    request,
    decoder: .ptModel(User.self)
)
```

`PTNetworkResponsePayload` 同时提供 `data`、`metadata`、`url` 和懒加载的 `string` / `utf8String`。旧 callback、SmartCodable 和 KakaJSON 入口不在本轮删除。

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
