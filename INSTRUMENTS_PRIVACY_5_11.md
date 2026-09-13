# PTools 5.11.x PTInstruments 隐私边界

## 默认策略

- PTInstruments 只属于 `PooToolsDEBUG`，不会进入 Core 默认运行路径。
- Network body 默认不捕获；请求头、Cookie、Authorization、Token 和完整响应体不进入
  `.pttrace`。
- URL 导出前移除 query 和 fragment；metadata key 包含 authorization、cookie、token、password、
  secret、credential 或 body 时写入 `[REDACTED]`。
- 日志文本会再次处理 Bearer、token、access_token、refresh_token 和 Authorization 标记。
- Session metadata 仅包含 bundle、版本、系统、设备型号和屏幕刷新率，不采集用户内容。

## 两层脱敏

1. 事件进入 Session 前，Recorder 会对 Debug event、日志和网络摘要做一次脱敏。
2. `PTInstrumentTraceStore.save` 创建文档时再次执行 `PTInstrumentRedactor.redact`，防止内存中
   的兼容入口或未来 Collector 意外带入敏感字段。

这两层不能替代宿主自己的隐私审核。业务 metadata 应只传递诊断所需的枚举、计数、状态和
   脱敏标识，不应把用户输入、完整 URL 参数或业务响应直接放入 trace。

## 高成本 / 高敏感能力

开启长时间录制、网络 body、更多日志保留量或更高采样频率前，宿主必须显式展示 Debug 开关，
并在测试环境控制归档分享范围。Signal handler、NSException handler 和崩溃退出路径不得执行
Swift actor、文件导出、UI 更新或日志 sink 回调。

## 发布检查

- 确认 Production Core 没有 `PTInstrumentRecorder.shared.start` 的隐式调用。
- 检查导出的 `.pttrace` 不含完整 query、Authorization、Cookie、Token、密码或响应正文。
- 检查 Debug disabled 时没有 DisplayLink、采样 Task、日志 sink 和通知 observer。
- 对真实宿主的归档、分享和删除流程进行人工验证；静态检查和 Simulator 构建不能替代隐私验收。
