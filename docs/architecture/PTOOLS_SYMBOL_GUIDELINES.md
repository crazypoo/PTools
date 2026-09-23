# PToolsSymbols 设计规范

## 分层

- `PTSymbol`：只表达不可变符号名称，保持 `Sendable`，不持有 UIKit 对象。
- `PTSymbolCatalog`：提供生成目录、版本、别名和元数据。
- `PTSymbolResolver`：在 MainActor 上完成 UIKit 图像解析、变量值限制和安全失败。
- 语义命名空间：`Actions`、`Navigation`、`Media`、`Status` 只承载稳定的业务语义别名。
- `PTSymbolGen`：从标准化 JSON 生成稳定排序的 Swift 目录，不允许手工编辑生成文件。

## 目录变更

目录条目必须提供原始名称、Swift 名称、最低 iOS 版本、弃用/重命名信息和变量值能力。修改后必须
执行：

```text
bash Scripts/Symbols/update-symbols.sh
bash Scripts/Symbols/verify-generated-symbols.sh
bash Scripts/Symbols/symbol-diff.sh <old-catalog.json> <new-catalog.json> <report.md>
```

## 安全和性能

- 不在生产路径使用强制解包、`fatalError` 或隐式的系统名称假设。
- 缺失符号优先使用显式回退，无法回退时返回 `nil` 并记录节流诊断。
- 目录是值类型元数据；解析器不缓存 UIKit 图像，避免跨主题和 trait collection 复用错误对象。
- 动态名称必须保留在白名单文件或明确的运行时适配器内。
