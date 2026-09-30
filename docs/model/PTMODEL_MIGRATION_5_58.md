# PTModel 5.58.0 迁移说明

## 新代码

```swift
struct Profile: Codable {
    let id: Int
    let name: String
}

let profile = try Profile.pt.model(from: data)
let payload = try profile.pt.jsonData()
```

需要最小依赖时使用 SwiftPM `PToolsModelCore` 或 CocoaPods `PooTools/ModelCore`。

SwiftPM 新项目可选用 `PToolsModel` 的宏：

```swift
import PToolsModel

@PTModel
public struct Profile: Codable, Sendable {
    public let id: Int
    public let name: String
}
```

宏只生成静态 Schema 元数据，运行时仍由 `PToolsModelCore` 执行。CocoaPods 的
`Model` subspec 不引入 SwiftSyntax；使用方改为手写 `PTModelSchema`，这是一条
有意保留的 non-macro fallback。

## 旧代码

旧的 `PTBaseModel`、`PTCodableModelProtocol`、SmartCodable 和 KakaJSON 入口在 5.58.0 保持不变。
不要在同一个迁移批次里同时替换 Network decoder、继承模型和 UI 模型；先为业务模型建立
输入/输出 fixture，再逐个切换。

## 迁移顺序

1. 先为旧模型建立 JSON/Data/Foundation fixture，并用 `PTModelDecoder` 做只读对比。
2. 对需要字段恢复、Schema 版本或 Patch 的模型建立手写 Schema；不强行改写自定义
   `init(from:)` / `encode(to:)`。
3. SwiftPM 项目再逐个启用 `@PTModel` / `@PTSubclass`，CocoaPods 项目使用同一
   Schema 的手写版本。
4. Network 先迁移到 `PTNetworkResponseDecoder`；SmartCodable/KakaJSON 旧对象只在
   `PTNetworkLegacyResponseDecoder` 的 MainActor 兼容层中使用。
5. 大数组按 `PTModelStreamDecoder` / `PTModelStreamEncoder` 迁移，并用仓库内真实
   benchmark runner 记录结果后再调整性能门槛。

## 回滚

每个模型可以独立回滚到原有 Codable、`PTBaseModel`、SmartCodable 或 KakaJSON 入口；
新 Schema、Patch、Streaming API 不修改旧公开符号，也不要求一次性删除第三方依赖。
