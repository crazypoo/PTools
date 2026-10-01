# DebugNetwork Example Fixture

Example 验收使用本地或 mock 服务覆盖以下请求，不依赖真实账号和敏感数据：

| 场景 | 验证 |
| --- | --- |
| GET JSON / POST JSON / form | method、headers、body preview、status |
| upload / download | bounded body、进度和 cancellation 边界 |
| redirect | redirect chain 和 metrics |
| 404 / 500 / timeout / cancel | typed error 与 exactly-once finalize |
| large response / chunked / gzip | memory/disk budget 与 preview |
| cache hit / retry metadata | 只显示业务事件，不参与决策 |
| secret headers / secret query | UI、cURL、HAR、Text 均不泄露 |

建议在 Example 中打开 LocalConsole 的 Network 开关，逐项确认 Capture、Timeline、Filter、Privacy、Export 和 burst UI 更新；真实宿主还需补充后台 URLSession、WKWebView、WebSocket 和 Network.framework 检查。
