# PTModel Nested JSON 语义（5.60.0）

## 三种输入必须分开理解

### A. Nested Object

```json
{
  "id": 1,
  "profile": { "nickname": "Jax" }
}
```

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

不需要额外 annotation。

### B. Response Envelope

```json
{
  "code": 200,
  "data": { "id": 1, "profile": { "nickname": "Jax" } }
}
```

显式选择模型根：

```swift
let response = try await Network.requestPTModel(
    urlStr: endpoint,
    modelType: User.self,
    modelPath: "$.data"
)
```

也可以声明完整 Envelope；两者不是同一层能力。

### C. JSON Stringified Model

```json
{
  "profile": "{\"nickname\":\"Jax\"}"
}
```

这里 `profile` 的 JSON 类型是 String，只有此情况才使用 `@PTStringified`。

## Annotation 选择表

| 需求 | 入口 |
| --- | --- |
| 普通字段 | 无 annotation |
| 改名 | `@PTKey` |
| 深层字段 | `@PTPath` |
| 默认值 | `@PTDefault` |
| 宽松数组 | `@PTLossy` |
| JSON String 内嵌 Model | `@PTStringified` |
| 忽略字段 | `@PTIgnore` |
| 展平对象 | `@PTFlat` |

普通 Nested Model 不应误用 `@PTStringified`；Response Envelope 也不应依赖自动猜测 `data`。

English: A nested object is decoded recursively; a response envelope needs an explicit model path; a JSON string needs `@PTStringified`.

Español: Un objeto anidado se decodifica recursivamente; un envelope necesita una ruta explícita; una cadena JSON necesita `@PTStringified`.
