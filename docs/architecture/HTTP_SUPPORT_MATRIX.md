# PTools 5.28.0 HTTP 支持矩阵

| 主题 | 支持 | 说明 |
| --- | --- | --- |
| HTTP/1.1 | ✅ | 增量 parser、Keep-Alive、HEAD、chunked |
| HTTP/2 / HTTP/3 | ❌ | 不作为本地调试服务目标 |
| TLS | ✅ 可选 | `PTTLSIdentity` + Network.framework |
| Bonjour | ✅ 可选 | 通过 server configuration 发布服务 |
| Static / Range | ✅ | 单 Range、MIME、ETag、304 |
| Multipart | ⚠️ 兼容入口 | 当前 request body 先按大小落 Data/临时文件；后续可替换为真正 part-level streaming parser |
| SSE | ✅ | AsyncThrowingStream、chunked response、默认有界 newest buffer |
| gzip | ✅ | 原生 zlib；只压缩协商成功的文本类 Data/Text response |
| WebDAV / reverse proxy / NAT | ❌ | 明确非目标 |
| File Portal | ✅ 可选 | 与 server core 分离，危险操作默认关闭 |

本矩阵如标记为 `⚠️`，表示 API 已提供安全边界但仍需要真机和大文件集成回归，不能宣称已达到公网级 HTTP server 完整度。

