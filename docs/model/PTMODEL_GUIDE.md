# PTModel 5.58.0 使用指南

> 5.60 Quick Start、CocoaPods Static Schema 和 legacy 迁移示例分别见 [`PTMODEL_NETWORK_QUICKSTART_5_60.md`](PTMODEL_NETWORK_QUICKSTART_5_60.md) 与 [`PTMODEL_LEGACY_CODABLE_COCOAPODS_5_60.md`](PTMODEL_LEGACY_CODABLE_COCOAPODS_5_60.md)。

## 5.60 Annotation map

| 场景 | API | 说明 |
| --- | --- | --- |
| 普通字段 | 无 annotation | 直接使用 `Codable` 属性 |
| key 映射 | `@PTKey` | 把 JSON key 映射到 Swift 属性 |
| 深路径 | `@PTPath` | 从嵌套 JSON 路径读取 |
| 必填 | `@PTRequired` | 缺失或无效时保留字段路径错误 |
| 默认值 | `@PTDefault` | 缺失值使用明确默认值 |
| 宽松集合 | `@PTLossy` | 忽略集合中无法解码的元素 |
| JSON String | `@PTStringified` | 只用于字段本身是 JSON 字符串的情况 |
| 忽略 | `@PTIgnore` | 不参与模型编码和解码 |
| Flatten | `@PTFlat` | 将嵌套对象字段展开到父对象 |
| Transform | `@PTTransform` | 使用显式值转换器 |
| Validate | `@PTValidate` | 在模型完成解码后执行约束校验 |
| 多态 | `@PTPolymorphic` | 根据 discriminator 选择具体类型 |
| Extras | `@PTExtras` | 收集未声明字段 |

普通 Nested Model、Nested Array 和 Nested Dictionary 不需要 annotation；只有 JSON 结构或兼容策略特殊时才增加 annotation。

## 目标

`PToolsModelCore` 是 iOS 17+ / Swift 6 的 Foundation-only 模型边界。它不依赖
SmartCodable、KakaJSON、UIKit 或运行时反射，现阶段与旧 Core 并存，方便逐步迁移。
SwiftPM 用户还可以通过 `PToolsModel` 使用 `@PTModel` / `@PTSubclass`；CocoaPods
使用 `ModelCore` 时采用同一套手写 `PTModelSchema`，不把 SwiftSyntax 带入业务 target。

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

## 字段恢复、诊断和校验

静态 Schema 可以把 missing、null、invalid 和 value 分开处理，避免把缺失字段
误判成默认值或把无效值静默吞掉：

```swift
let field = PTModelFieldDescriptor(name: "count", required: false)
let recovery = PTFieldRecovery<Int>(defaultValue: 0,
                                    missingPolicy: .useDefault,
                                    nullPolicy: .useDefault,
                                    invalidPolicy: .useDefault)
let count = try decoder.resolveField(Int.self,
                                    from: object,
                                    field: field,
                                    recovery: recovery)
```

`PTModelDiagnosticSink` 用于收集字段诊断；并发场景可使用
`PTModelDiagnosticStore` 的 `sink` 适配器。校验逻辑放入 `PTModelValidator`，不会
依赖全局可变日志状态。

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

## 静态 Schema、Patch 和迁移

不希望依赖运行时反射时，可以把字段策略写进静态 Schema：

```swift
struct Profile: Codable, Sendable, PTStaticModel {
    let id: Int
    let nickname: String?

    static let idField = PTModelFieldDescriptor(name: "id", required: true)
    static let nicknameField = PTModelFieldDescriptor(name: "nickname")

    static var ptSchema: PTModelSchema<Profile> {
        PTModelSchema(fields: [idField, nicknameField],
                      decode: { value, decoder in
                          try decoder.decode(Profile.self, from: value)
                      },
                      encode: { model, encoder in
                          try encoder.object(fields: [
                              (idField, encoder.jsonValue(model.id)),
                              (nicknameField, try encoder.optionalJSONValue(model.nickname))
                          ])
                      })
    }
}

let json = try PTStaticCodec.jsonValue(Profile(id: 1, nickname: nil))
```

`PTModelPatch`、`PTModelDiff`、`PTModelClone`、`PTModelConverter` 和
`PTModelMigrationChain` 都使用 `PTJSONValue`，因此可以在不跨 actor 传递 `Any`
的情况下完成更新、差异和版本迁移。Patch 中没有出现的字段保持不变，`null`
是显式清空，Diff 的对象键按字典序生成。

普通 `Codable` 模型继续保留 Foundation 的兼容行为；静态 Schema 可以使用
`PTModelEncoder.object(fields:)` 和 `optionalJSONValue(_:)` 进入字段级策略；SwiftPM
的 `@PTModel` 生成 Schema 也会沿用同一套 Optional 字段策略。`canonical: true` 会使用
Foundation-only 的 PTJSON 树编码路径，并对输出键排序；默认基准仍使用兼容编码路径。

## 流式数组

大数组可以使用 `PTModelStreamDecoder` 逐项消费，或使用
`PTModelStreamEncoder` 写入 `PTAsyncJSONByteSink` / `PTAsyncFileByteSink`：

```swift
let stream = PTModelStreamDecoder<Profile>(data: data)
for try await profile in stream {
    consume(profile)
}
```

流式入口只接受顶层数组，逐项检查取消并在单项失败时返回带索引的
`PTModelError.streamElementFailed`。它不会生成完整的 `PTJSONValue` 树；输入 `Data`
仍由调用方持有，若需要真正的网络分块，应让上层按块写入文件 sink 后再启动消费。

### 任意 Data 分块

网络或文件读取可以直接把任意大小的 `Data` 分块交给 `PTModelChunkStreamDecoder`；分块
边界不需要对齐 JSON token，取消会在每次读取前检查：

```swift
let chunks: AsyncStream<Data> = makeChunks()
let stream = PTModelChunkStreamDecoder<AsyncStream<Data>, Profile>(source: chunks)
for try await profile in stream {
    consume(profile)
}
```

它要求根值是数组，未知字段会被跳过，单项失败会包含数组索引；完整输入不会先拼成一份
大 `Data` 或完整对象树。生成 `PTStaticModel` 的普通对象还可以使用
`PTStaticCodec.encode`，在非 pretty-print 模式下直接写字段到 `PTJSONByteSink`。

## 默认值、诊断和兼容边界

需要动态默认值时使用 `PTDefaultValueProvider`，闭包只接收不可变 `PTModelContext`：

```swift
let recovery = PTFieldRecovery<Int>(
    provider: PTDefaultValueProvider { context in
        context.jsonValues["tenant"] == nil ? 0 : 1
    },
    missingPolicy: .useDefault,
    invalidPolicy: .useDefault
)
```

`PTDecodeTrace` 记录 missing、null、invalid、default 和 ignored 决策；需要长期保存时可以
使用 actor-backed `PTModelDiagnosticStore`。Core 不接收 UIKit、Combine 或第三方 model
codec；SmartCodable、KakaJSON 只通过显式 Legacy adapter 产品接入。

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

5.60.0 的完整实战入口见 [PTModel + Network Quick Start](PTMODEL_NETWORK_QUICKSTART_5_60.md)。普通 Nested Model、Response Envelope 和 JSON Stringified Model 的区别见
[Nested JSON 语义](PTMODEL_NETWORK_NESTED_JSON_5_60.md)。

包装响应不自动猜测 `data`、`result` 或 `payload`，请显式传入 `modelPath`：

```swift
let response = try await Network.requestPTModel(
    urlStr: endpoint,
    modelType: User.self,
    modelPath: "$.data"
)
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
- `lossy`：集合可以选择跳过无效项或替换为默认值；静态 Schema 还可以配置字段级恢复。

## 迁移边界

5.58.0 不修改 `PTBaseModel`、Network 旧入口或 SmartCodable/KakaJSON 依赖。新代码可先依赖
`PToolsModelCore`，确认行为后再迁移业务模型；旧模型继续通过原有 Core 路径运行。
Network 的 `PTNetworkResponseDecoder` 继续提供 `Sendable` 泛型路径；
`PTNetworkLegacyResponseDecoder` 明确标记为 MainActor 兼容层，让旧的引用模型不跨
transport actor 传播。

## 基准与迁移清单

`Scripts/PTModel/run_benchmarks.sh` 运行包内的 `PTModelBenchmark`，输出可复现的
JSON 编码/解码指标。`Scripts/PTModel/benchmark_models.swift` 是同一 runner 的
Swift 脚本入口，不维护第二套基准实现。

`Scripts/PTModel/migrate_smartcodable.swift` 和
`Scripts/PTModel/migrate_kakajson.swift` 只生成文件、行号和匹配类型的 JSON 清单，
不会自动改写源码。审阅清单后，将调用方迁移到 `PToolsModelCore`/`PToolsModel`，
或明确登记为 legacy adapter，再重新运行清单。
