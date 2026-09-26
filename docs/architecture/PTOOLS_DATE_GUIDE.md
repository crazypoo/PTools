# PToolsDate 设计指南

## 分层

`PToolsDate` 只依赖 Foundation，位于 UIKit、Network 和 Debug 之前：

```text
Date / Calendar / TimeZone / Locale
                ↓
PTDateContext + PTZonedDate + PTDateParser
                ↓
Core compatibility extensions
                ↓
UIKit / Network / feature modules
```

English: The date layer is Foundation-only and safe to use from Swift 6 value-type boundaries.

Español: La capa de fechas solo depende de Foundation y puede usarse en límites de valores de Swift 6.

## 四条规则

1. **Instant is not presentation**：`Date` 不携带时区；显示时使用 `zoned(in:)`。
2. **Timestamp unit is explicit**：秒和毫秒必须通过 `PTTimestampUnit` 指明。
3. **Protocol input is fixed**：服务器字符串使用 `PTDateParser` + `.posixUTC`，不使用用户当前区域设置。
4. **Calendar math follows the calendar**：跨 DST、月份和日期边界使用 `PTZonedDate.adding(_:)`，固定时长才使用 `addingTimeInterval`。

## 并发边界

`PTDateContext`、`PTZonedDate`、`PTDateComponentsView`、`PTDateOffset` 和解析策略都是不可变 `Sendable` 值。格式化器按调用创建，不共享可变 `DateFormatter`。通知、UIKit 状态和宿主 UI 仍必须在 `MainActor` 处理。

## 性能

- 只在固定 pattern 或兼容旧 API 时创建 `DateFormatter`。
- 不把格式化字符串用于排序；排序直接比较 `Date` 或 `PTZonedDate`。
- 批量日志使用一次上下文和固定格式，避免每条记录重新推断区域设置。
- 不为单次日期计算引入缓存；只有 Instruments 证明格式化成为热点时才增加按值缓存。

