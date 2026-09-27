# Native HTTP Server 测试矩阵

## 已纳入 SwiftPM 测试目标

- request line 分片读取、origin-form、query 解码。
- Content-Length body 分片读取。
- chunked body 与 trailer。
- Content-Length / Transfer-Encoding 冲突。
- 重复 Content-Length。

## 需要在 Xcode Simulator/真机完成

| 领域 | 场景 |
| --- | --- |
| Router | exact、parameter、wildcard、priority、404、405、HEAD、OPTIONS |
| Connection | Keep-Alive、多请求顺序、HTTP/1.0、Connection close、idle timeout、最大请求数 |
| Static | index、MIME、HEAD、Range、ETag、304、symlink、路径穿越 |
| Upload | 1 MiB 内存阈值、临时文件、超限、断开清理、mkdir、rename、delete 开关 |
| Stream/SSE | chunked、事件字段、多行 data、取消、慢消费者、heartbeat |
| Compression | gzip 协商、文本、已压缩类型、小 body、文件流和 Range 不压缩 |
| Security | loopback/local network、Bearer、CORS、Host、TLS identity、Bonjour |
| Concurrency | 32/64 clients、JSON、文件、SSE、上传并发，Thread Sanitizer |

## 发布解释

SwiftPM parser tests 证明 framing 的纯值边界；它们不能替代 Xcode 的 Network.framework 链接、模拟器运行、
真实设备局域网权限、Bonjour、TLS 和慢客户端测试。未完成这些场景时，不创建正式 `5.28.0` tag。

