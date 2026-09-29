# PTModel Codable Interoperability Contract

5.58.0 固定以下互操作边界：

| 场景 | 当前行为 |
| --- | --- |
| 已有 `Codable` / `CodingKeys` | 交给 Foundation `JSONDecoder` / `JSONEncoder` |
| 自定义 `init(from:)` | 原样保留，PTModel 不覆盖 |
| 自定义 `encode(to:)` | 原样保留，PTModel 不覆盖 |
| Date | 通过 `PTDateDecodingStrategy` / `PTDateEncodingStrategy` 显式选择 |
| JSON Encoder formatting | 由 `PTModelEncoder` 的 pretty/sorted 配置控制 |
| typed context | 使用 `PTModelContext` 保存为 `PTJSONValue` |
| 宏 Schema | 5.58.x 后续阶段实现，当前不生成宏代码 |
| 混合 PTModel/Codable | 以 Codable 作为安全 fallback，不修改既有自定义实现 |

优先级在宏和静态 Schema进入前保持：

```text
手写 Codable
    ↓
PTModelDecoder / PTModelEncoder
    ↓
PTJSONValue / Foundation Bridge
```

PTModel 不通过运行时反射替换自定义 Codable 实现。
