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

## 7. SwiftPM 与 CocoaPods

- SwiftPM：可使用 `PToolsModel` 的 `@PTModel` / `@PTSubclass` 宏。
- CocoaPods：`ModelCore` / `Model` 保持 Foundation-only fallback；使用普通 `Codable`、`PTModelDecoder` 或手写 `PTStaticModel` Schema。
- `Network.requestPTModel` 的 `modelPath` 在两种集成方式中都保持显式、默认 `.root` 的契约。

## 8. 错误诊断

路径不存在会抛出 `PTNetworkDecodeError.modelPathNotFound`；选中的值无法解码会抛出 `modelPathTypeMismatch`，错误信息包含完整路径，例如 `$.data.list`。

---

English: Use an explicit JSON path for wrapped responses; the default root path is backward compatible.

Español: Usa una ruta JSON explícita para respuestas envueltas; la ruta raíz predeterminada mantiene la compatibilidad.
