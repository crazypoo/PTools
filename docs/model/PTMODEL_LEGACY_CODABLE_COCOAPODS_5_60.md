# CocoaPods / Legacy Model 迁移教程（5.60.0）

本教程面向只安装 CocoaPods `ModelCore` / `Model`，或仍在使用 SmartCodable、SmartCodable/Inherit、KakaJSON 的项目。目标是把模型边界逐步迁移到 PTools 的 Foundation-only `PTModelDecoder` / `PTModelEncoder`，同时保留旧入口，不假设 Swift Macro 在 CocoaPods target 中可用。

## 1. CocoaPods 中的 Codable 与静态 Schema

普通模型不需要宏：

```swift
struct User: Codable, Sendable {
    let id: Int
    let name: String
}

let user = try PTModelDecoder(policy: .compatible)
    .decode(User.self, from: data)
let jsonData = try PTModelEncoder().encode(user)
```

需要字段策略、静态诊断或不希望依赖运行时反射时，实现 `PTStaticModel`：

```swift
struct Profile: Codable, Sendable, PTStaticModel {
    let id: Int
    let nickname: String?

    static let idField = PTModelFieldDescriptor(name: "id", required: true)
    static let nicknameField = PTModelFieldDescriptor(name: "nickname")

    static var ptSchema: PTModelSchema<Profile> {
        PTModelSchema(
            fields: [idField, nicknameField],
            decode: { value, decoder in
                try decoder.decode(Profile.self, from: value)
            },
            encode: { model, encoder in
                try encoder.object(fields: [
                    (idField, encoder.jsonValue(model.id)),
                    (nicknameField, try encoder.optionalJSONValue(model.nickname))
                ])
            }
        )
    }
}
```

这个入口使用 `PTJSONValue`，不会把 `Any`、UIKit 对象或第三方 codec 带入并发核心。

## 2. SmartCodable 迁移

| SmartCodable 能力 | PTools 迁移方式 |
| --- | --- |
| 普通字段 | `Codable` + `PTModelDecoder` |
| key mapping | `CodingKeys`；SwiftPM 新代码可使用 `@PTKey` |
| nested object | 直接声明 `Profile`，不使用 `@PTStringified` |
| array / dictionary | `[Profile]`、`[String: Profile]` |
| default | `PTFieldRecovery` / `PTDefaultValueProvider`，或模型初始化默认值 |
| lossy array | `decodeArray(_:strategy:)` / `decodeOptionalArray` |
| JSON string | `PTStringifiedValue<Profile>` 或 SwiftPM `@PTStringified` |
| JSON → Model | `PTModelDecoder` |
| Model → JSON | `PTModelEncoder` |

SmartCodable 的运行时反射和每个版本的隐式容错不保证与 PTools 一一等价。迁移时要为缺失、null、invalid 分别选择策略，不要把所有失败静默替换成默认值。

## 3. SmartCodable/Inherit 迁移

继承模型先拆成值语义模型或静态 Schema：

```swift
struct Admin: Codable, Sendable {
    let id: Int
    let permissions: [String]
}
```

如果业务必须保留继承层级，继续在兼容模块中使用旧 adapter，并把跨 actor 传递的结果转换为不可变 DTO。PTools 的 `@PTSubclass` 是 SwiftPM 宏入口，不是 CocoaPods 的运行时继承替代品。

迁移顺序建议为：key mapping → default / lossy → nested → JSON string → inheritance → JSON 编解码。每一步都用固定 fixture 验证，不要直接用线上响应替代回归数据。

## 4. KakaJSON 迁移

KakaJSON 模型先保留在 `PTModelLegacyKakaJSON` 兼容边界，新的业务模型使用 `Codable` / `PTStaticModel`。以下能力通常可以直接迁移：

- `kj.model`：`PTModelDecoder.decode(_:from:)`
- `kj.JSON`：`PTModelEncoder.jsonValue`、`jsonData` 或 `jsonString`
- 字段映射：`CodingKeys` 或 `PTModelSchema` 字段描述
- nested / array：普通 Codable 类型声明

KakaJSON 的自定义 transformer、运行时类型推断、反射属性列表并不保证 1:1。无法等价表达的能力必须继续留在兼容 adapter，并记录迁移原因；不得把 KakaJSON 的 `Any` 结果直接交给新的 `PTNetworkExecutor`。

## 5. Network 响应路径

根模型：

```swift
let root = try await Network.requestPTModel(
    urlStr: endpoint,
    modelType: User.self
).model
```

包裹模型：

```swift
let envelope = try await Network.requestPTModel(
    urlStr: endpoint,
    modelType: User.self,
    modelPath: "$.data"
).model
```

列表：

```swift
let users = try await Network.requestPTModel(
    urlStr: endpoint,
    modelType: [User].self,
    modelPath: "$.data.list"
).model
```

PTools 不会自动猜测响应包裹字段。`modelPathNotFound` 表示路径不存在，`modelPathTypeMismatch` 表示路径遍历遇到错误容器，`modelDecodeFailed` 表示已选中值但模型字段失败；字段诊断会保留完整路径。

## 6. 迁移检查清单

- [ ] 新模型不再依赖第三方运行时反射。
- [ ] Nested object 没有误用 `@PTStringified`。
- [ ] `modelPath` 对包裹响应明确填写。
- [ ] JSON string、default、lossy 和 required 策略有 fixture 覆盖。
- [ ] 旧入口只停留在兼容层，并有替代 API 和移除版本。
- [ ] 动态 `Any` 没有跨 actor 进入 Network 核心。
- [ ] 真实宿主验证 root、`$.data`、list 和 deep path。
