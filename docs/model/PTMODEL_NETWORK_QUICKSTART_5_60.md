# PTModel + Network Quick Start（5.60.0）

适用范围：iOS 17+、Swift 6+。本指南只使用 PTools 已有的 `PToolsModelCore`、`PToolsModel` 和 Network 类型化入口。

## 1. JSON -> Model

```swift
struct User: Codable, Sendable {
    let id: Int
    let name: String
}

let user = try PTModelDecoder(policy: .compatible)
    .decode(User.self, from: data)
```

SwiftPM 可以使用宏：

```swift
@PTModel
struct User: Codable, Sendable {
    let id: Int
    let name: String
}
```

## 2. Model -> JSON

```swift
let jsonData = try PTModelEncoder().encode(user)
let jsonString = try user.pt.jsonString()
```

## 3. 嵌套 Model

普通 JSON Object 直接声明嵌套类型，不需要 `@PTPath` 或 `@PTStringified`：

```swift
@PTModel
struct Profile: Codable, Sendable {
    let nickname: String
}

@PTModel
struct User: Codable, Sendable {
    let id: Int
    let profile: Profile
}
```

对应 `{"id":1,"profile":{"nickname":"Jax"}}`。

数组和字典同样直接使用：

```swift
@PTModel
struct Group: Codable, Sendable {
    let members: [User]
    let owners: [String: User]
}
```

## 4. Network 根节点与响应包裹

根节点就是模型时，旧调用方式保持不变：

```swift
let response = try await Network.requestPTModel(
    urlStr: endpoint,
    modelType: User.self
)
let user = response.model
```

接口返回 `{ "code": 200, "data": { ... } }` 时，显式指定路径：

```swift
let response = try await Network.requestPTModel(
    urlStr: endpoint,
    modelType: User.self,
    modelPath: "$.data"
)
```

深层数组同样使用显式路径：

```swift
let response = try await Network.requestPTModel(
    urlStr: endpoint,
    modelType: [User].self,
    modelPath: "$.result.payload.list"
)
```

不会自动猜测 `data`、`result` 或 `payload`，避免同一 API 在不同服务端响应下产生不可预测行为。

## 5. Network Executor

```swift
let request = PTNetworkRequest(url: endpoint)
let (_, user) = try await PTNetworkExecutor.shared.execute(
    request,
    decoder: .ptModel(User.self, at: "$.data")
)
```

`PTNetworkResponsePayload` 始终保留原始 `Data`、URL 和响应元数据。

## 6. Nested Object 与 JSON String 的区别

Object：

```json
{"profile":{"nickname":"Jax"}}
```

直接声明 `profile: Profile`。

Stringified JSON：

```json
{"profile":"{\"nickname\":\"Jax\"}"}
```

只有第二种才使用：

```swift
@PTStringified
let profile: Profile?
```

## 7. Annotation 速查

| 场景 | SwiftPM API | 说明 |
| --- | --- | --- |
| 普通字段 | 无 annotation | 字段名与 JSON key 相同即可 |
| key 映射 | `@PTKey` | 外部 key 与 Swift 属性名不同 |
| 深路径 | `@PTPath` | 属性来自嵌套 JSON 路径 |
| 必填 | `@PTRequired` | 缺失或无效时保留明确错误 |
| 默认值 | `@PTDefault` | 缺失时使用声明的默认策略 |
| 宽松集合 | `@PTLossy` | 集合元素失败时按策略跳过或保留 nil |
| JSON String | `@PTStringified` | 仅用于“字段值本身是 JSON 字符串” |
| 忽略字段 | `@PTIgnored` | 计划中的旧名称 `@PTIgnore` 不是当前 canonical spelling |
| Flatten | `@PTFlat` | 把嵌套对象字段平铺到当前对象 |
| 转换 | `@PTTransform` | 使用明确的值转换器 |
| 校验 | `@PTValidate` | 在模型边界执行字段校验 |
| 多态 | `@PTPolymorphic` | 按 discriminator 选择具体模型 |
| Extras | `@PTExtras` | 保存未声明的 JSON 字段 |

普通 Nested Model 不需要 annotation：只有外部 key、路径、字符串化格式或特殊容错策略与默认 Codable 语义不同，才增加对应 annotation。

## 8. SwiftPM 与 CocoaPods

- SwiftPM：可使用 `PToolsModel` 的 `@PTModel` / `@PTSubclass` 宏。
- CocoaPods：`ModelCore` / `Model` 保持 Foundation-only fallback；使用普通 `Codable`、`PTModelDecoder` 或手写 `PTStaticModel` Schema。
- `Network.requestPTModel` 的 `modelPath` 在两种集成方式中都保持显式、默认 `.root` 的契约。

CocoaPods 不能使用 Swift Macro。请使用普通 `Codable`、`PTModelDecoder`，或参考 [CocoaPods / Legacy Model 教程](PTMODEL_LEGACY_CODABLE_COCOAPODS_5_60.md) 手写 `PTStaticModel` / `PTModelSchema`。

## 9. 错误诊断

路径不存在会抛出 `PTNetworkDecodeError.modelPathNotFound`；路径遍历过程中遇到错误容器类型才会抛出 `modelPathTypeMismatch`。路径已经选中、但目标 Model 或字段解码失败时会抛出 `modelDecodeFailed`，并保留完整诊断路径，例如 `$.data.id`。因此字段类型错误、缺失字段、`@PTRequired`、数值溢出和 nested field error 不会再被伪装成 path mismatch。

典型输出应至少包含：

```text
modelPath: $.data
field: $.data.id
expected: Int
actual: String
```

## 10. 网络执行与取消

```swift
let request = PTNetworkRequest(url: endpoint)
let (_, user) = try await PTNetworkExecutor.shared.execute(
    request,
    decoder: .ptModel(User.self, at: "$.data")
)
```

`PTNetworkResponsePayload` 负责保存不可变的 `Data`、URL 和响应元数据；旧 callback、SmartCodable 和 KakaJSON 入口仍是兼容层，不进入新的并发 transport 核心。

## 11. 常见错误

- 普通 object 写成 `@PTStringified`：会把 object 当作字符串解码，应该删除 annotation。
- 响应包裹却省略 `modelPath`：不会自动猜测 `data`、`result` 或 `payload`。
- CocoaPods 示例直接使用 `@PTModel`：请改用普通 Codable 或静态 Schema。
- 用动态 `Any` 把响应跨 actor 传递：在边界转换为 `PTJSONValue` 或明确的 `Sendable` 模型。
- 把 `modelPathTypeMismatch` 当成字段类型错误：字段解码错误应检查 `modelDecodeFailed` 的完整路径。

---

English: Use an explicit JSON path for wrapped responses; the default root path is backward compatible.

Español: Usa una ruta JSON explícita para respuestas envueltas; la ruta raíz predeterminada mantiene la compatibilidad.
