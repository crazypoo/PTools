# DebugNetwork 隐私与导出

默认隐私策略适用于列表事件、详情、复制、分享、Text、cURL 和 HAR：

- Header：`Authorization`、`Proxy-Authorization`、`Cookie`、`Set-Cookie`、`X-API-Key`。
- Query：`api_key`、`token`、`access_token`、`refresh_token`、`password`、`secret`、`session`、`code`。
- JSON：递归处理大小写不敏感的敏感 key，包括嵌套对象和数组。
- Body：只保留 bounded preview；绝不为了展示而无上限读取 `httpBodyStream`。

`PTNetworkRedactor` 以 `PTNetworkPrivacyPolicy` 和 `PTNetworkSensitiveKeyRegistry` 为唯一脱敏入口。raw 展示只能是当前会话内的显式选择，不写入导出文件和持久化存储。

导出前始终调用 `record.redacted()`。HAR 1.2 中无法可靠取得的字段省略或使用标准的 `-1`，不伪造服务器 IP、连接号或完整正文。
