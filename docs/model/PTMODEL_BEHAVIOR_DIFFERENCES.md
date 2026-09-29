# PTModel 行为差异与回滚

## 5.58.0 已知差异

- PTModel 不读取 Swift 属性默认值；缺失非 Optional 字段仍由 Codable 决定是否报错。
- PTModel 不把 URL 字符串当成网络图片，不产生网络副作用。
- PTModel 不通过裸 `Any`、`Mirror` 或 Objective-C runtime 生成 Fast Path Schema。
- `PTPresence.missing` 在普通 Codable 合成编码中编码为 `null`；字段省略需要后续 Patch/Schema 入口。
- Foundation dictionary 中的 `Data` 使用 Base64 字符串桥接；模型字段的 Data strategy 由显式 API 控制。

## 回滚方式

业务模型迁移前继续使用 `PooTools/Core` 中的 `PTBaseModel`、SmartCodable 和 KakaJSON 入口。
新增的 `PToolsModelCore` / `PooTools/ModelCore` 是可选产品，不会替换旧依赖，也不会改变旧入口。
