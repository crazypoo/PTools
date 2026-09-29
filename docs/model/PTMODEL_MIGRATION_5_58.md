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

## 旧代码

旧的 `PTBaseModel`、`PTCodableModelProtocol`、SmartCodable 和 KakaJSON 入口在 5.58.0 保持不变。
不要在同一个迁移批次里同时替换 Network decoder、继承模型和 UI 模型；先为业务模型建立
输入/输出 fixture，再逐个切换。

## 当前不迁移的内容

`@PTModel` / `@PTSubclass` 宏、SmartCodable wrapper parity、KakaJSON dynamic model、
Network canonical decoder、streaming 和 Fast Path benchmark 按计划的后续 5.58.x/5.59.x
阶段实施。
