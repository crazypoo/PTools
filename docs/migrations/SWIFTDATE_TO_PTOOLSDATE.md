# SwiftDate → PToolsDate 迁移指南

> 适用版本：5.26.0；最低系统：iOS 17；语言模式：Swift 6。

## 目标

5.26.0 将 Core 日期能力收敛到 Foundation-only 的 `PToolsDate`，移除 SwiftDate 运行时依赖。`Date` 仍表示绝对时间点；时区、日历和区域设置通过不可变的 `PTDateContext` 显式携带。

English: `Date` remains an instant; `PTDateContext` carries calendar, time zone, and locale explicitly.

Español: `Date` sigue representando un instante; `PTDateContext` transporta calendario, zona horaria y región de forma explícita.

## 常用替换

| SwiftDate | PToolsDate |
| --- | --- |
| `DateInRegion(date, region: ...)` | `date.zoned(in: PTDateContext(...))` |
| `region.timeZone` | `context.timeZone` |
| `date.year`, `date.month` | `zoned.year`, `zoned.month` |
| `date.toFormat("yyyy-MM-dd")` | `zoned.formatted(pattern: "yyyy-MM-dd")` |
| `date.toDate()` | 直接使用 `Date` 或 `zoned.date` |
| `date.dateAtStartOf(.day)` | `zoned.startOfDay` |
| `date.dateAtEndOf(.day)` | `zoned.dayInterval?.end` |
| `date + 3.days` | `zoned.adding(.days(3))` |
| Unix seconds | `Date.fromTimestamp(value, unit: .seconds)` |
| Unix milliseconds | `Date.fromTimestamp(value, unit: .milliseconds)` |

## 解析和格式化

机器协议使用固定的 `PTDateContext.posixUTC`，用户界面使用 `.autoupdatingCurrent`。不要用当前设备时区解释服务器时间，也不要通过给 Unix timestamp 额外加时区秒数来“修正”显示。

```swift
let serverDate = try PTDateParser.parse(
    "2026-09-26 12:30:00",
    strategy: .pattern("yyyy-MM-dd HH:mm:ss"),
    context: .posixUTC
)

let title = serverDate.zoned(in: .autoupdatingCurrent)
    .formatted(date: .long, time: .shortened)
```

## API 兼容边界

- Core 内部不再导入 SwiftDate，也不跨 actor 传递 SwiftDate 类型。
- 旧业务调用方应在边界处转换成 `Date`、`PTZonedDate` 或 `PTDateComponentsView`。
- `DateFormatter` 只在固定 pattern 的兼容入口内按调用创建，避免全局可变 formatter 的线程安全问题。
- 新的解析调用必须明确策略；失败通过 `PTDateParsingError` 处理，不能用 `try!`。

