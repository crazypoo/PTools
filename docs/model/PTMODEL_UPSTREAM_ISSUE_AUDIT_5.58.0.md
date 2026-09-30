# PTModel Upstream Issue Audit 5.58.0

## 审计范围

本次只审计会影响 PTools PTModel 公共契约的上游行为：Codable 互操作、重复键、数字
精度、Unicode surrogate、missing/null、Foundation bridge、SmartCodable/KakaJSON
legacy 边界和 Swift 6 Sendable 边界。没有把第三方内部实现复制进 Core。

## 结论

| 项目 | 结论 | 处理 |
| --- | --- | --- |
| JSON duplicate key | 已定义 | `PTDuplicateKeyPolicy` + 回归测试 |
| exact number lexeme | 已定义 | `PTJSONNumber` 保留原始字面量 |
| surrogate pair | 已定义 | 成对校验，孤立 surrogate 返回类型化错误 |
| Foundation Bool / NSNumber | 已定义 | 先检查精确 Bool 类型，再处理 NSNumber |
| missing/null/invalid | 已定义 | `PTFieldRecovery` + `PTPresence` |
| legacy non-Sendable model | 已隔离 | `@MainActor` legacy decoder |
| macro / CocoaPods | 已定义 | SwiftPM macro，Pods 手写 Schema fallback |
| unsafe runtime metadata | 不采用 | stable hash，不使用 Mirror/ABI metadata |

**Design Change Needed = 0（针对本审计范围）。**

这不表示第三方库没有其他 issue，也不等于已经完成真实依赖版本的差分测试；外部
fixture、真机、TSan 和 Archive 仍由宿主工程质量门禁负责。
