# SwiftDate 使用审计

版本：5.26.0  
范围：`PooToolsSource`、`Tests`、SwiftPM、CocoaPods

## 结论

本次审计确认 SwiftDate 只被用于旧日期语义和少量无效导入，没有必须保留的第三方运行时能力。替换后统一使用 `PToolsDate` 与 Foundation；旧的 SwiftDate 类型不作为 PTools 兼容 API 保留。

| 文件 | SwiftDate 能力 | PToolsDate 替代 | 状态 |
| --- | --- | --- | --- |
| `Category/Date+PTEX.swift` | `toFormat`、`toDate` | `PTZonedDate`、`PTDateParser` | 已迁移 |
| `Category/String+PTEX.swift` | `DateInRegion`、`Region`、比较、格式化 | `PTDateContext`、`PTZonedDate`、`PTDateParser` | 已迁移 |
| `Category/TimeInterval+PTEX.swift` | `Locales`、日期比较 | `PTDateContext`、`PTZonedDate` | 已迁移 |
| `Calendar/PTEventOnCalendar.swift` | `DateInRegion` 参数、日期组件 | `PTZonedDate` | 已迁移 |
| `HealthKit/PTHealthKit.swift` | `toDate`、`dateAtEndOf` | `Calendar.startOfDay` 和 `date(byAdding:)` | 已迁移 |
| `MessageKit/PTChatConfig.swift` | `Int.seconds` | `TimeInterval` | 已迁移 |
| `MessageKit/PTChatView.swift` | `toFormat` | `Date.dateFormat` | 已迁移 |
| `NetworkSpeedTest/PTNetworkSpeedTestFunction.swift` | `Date.toString` | `Date.dateFormat` | 已迁移 |
| `DebugCategory/HTTPURLResponse+PTEX.swift` | `String.toDate` | HTTP 日期格式解析 | 已迁移 |
| `DebugCrash/*`、`DebugNetwork/*`、`MessageKit/PTChatConfig.swift` | 未使用的导入 | 删除导入 | 已迁移 |

## 分类

- Formatting：固定协议格式由 `PTZonedDate.formatted(pattern:)` 处理，用户展示使用 Foundation `FormatStyle`。
- Parsing：`PTDateParser` 支持 ISO8601、单格式和显式多格式，默认严格失败。
- Region：由 `PTDateContext` 替代，明确绑定 `Calendar`、`TimeZone`、`Locale`。
- DateInRegion：由 `PTZonedDate` 替代，绝对 `Date` 在转换语境时保持不变。
- Math：由 `PTDateOffset` 和 `PTZonedDate.adding(_:)` 替代，遵循 Calendar/DST 规则。
- Relative、Components、Comparison、Boundary：由 `PTZonedDate` 的值类型 API 替代。

## 迁移规则

1. Unix timestamp 只转换为绝对 `Date`，不再手工叠加时区偏移。
2. 服务器解析使用 `.posixUTC` 或业务明确的 `PTDateContext`；UI 展示使用 `.autoupdatingCurrent`。
3. 新代码不使用 `Calendar.current`、`TimeZone.current` 作为隐式业务语境。
4. 不复制 SwiftDate 的 `Region`、`DateInRegion`、全局 `defaultRegion` 或 `Int.days` DSL。
