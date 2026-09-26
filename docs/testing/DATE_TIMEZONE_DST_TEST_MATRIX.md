# 日期、时区和 DST 测试矩阵

适用版本：5.26.0。

| 领域 | 场景 | 预期 |
| --- | --- | --- |
| Timestamp | Unix seconds / milliseconds | 转换后表示同一个绝对时间点 |
| Calendar | Gregorian、ISO8601、用户当前日历 | 组件来自显式 context，不读取隐式全局状态 |
| Time zone | UTC、Asia/Shanghai、America/New_York | 格式化只改变显示，不改变 `Date` |
| DST | New York 2024-03-09 加一天 | 本地小时保持，绝对间隔为 23 小时 |
| DST | New York 2024-11-02 加一天 | 本地小时保持，绝对间隔为 25 小时 |
| Locale | en_US_POSIX 协议解析 | 固定数字格式，不受设备语言影响 |
| Parsing | 不存在日期，如 2024-02-30 | 返回 `PTDateParsingError.invalidDate` |
| Formatting | 用户可见日期和时间 | 使用显式 locale、calendar、timeZone |
| Boundaries | 日、周、月、年起止 | 使用 `DateInterval`，不手工拼接秒数 |
| Concurrency | 多任务并行读同一 date value | 无共享可变 formatter、无数据竞争 |

English: Device and simulator runs should cover at least UTC, Shanghai, New York, English, Chinese, and Spanish locales.

Español: Las ejecuciones en dispositivo y simulador deben cubrir al menos UTC, Shanghái, Nueva York y las regiones inglesa, china y española.

中文：设备和模拟器验证至少覆盖 UTC、上海、纽约，以及英文、中文、西班牙文区域设置。

