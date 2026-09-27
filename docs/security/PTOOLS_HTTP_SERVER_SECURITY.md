# PTools HTTP Server 安全边界

## 默认安全策略

- 默认只绑定 loopback；局域网访问必须显式使用 `.localNetwork`。
- 请求行、header 总量、header 数量、chunk 数和 body 大小均有限制。
- `Content-Length` 与 `Transfer-Encoding` 冲突、重复 Content-Length、非法 chunk 和 header folding 直接拒绝。
- 静态目录默认拒绝符号链接；最终解析路径必须位于 root 内。
- 文件门户固定在调用方传入的 sandbox root，不允许浏览整个 sandbox。
- 删除、创建目录和重命名默认关闭；上传扩展名可配置；Bearer token 为可选保护层。
- gzip 只处理协商成功的文本/JSON/SVG 类小响应，不压缩文件流、图片、视频和已有编码内容。
- Release 错误响应不返回堆栈、绝对路径、token 或请求正文。

## 调用方责任

- 为局域网服务配置 `NSLocalNetworkUsageDescription`，并在真实设备验证权限拒绝和 Settings 返回路径。
- 不把密码、Cookie、Authorization 或用户隐私写入业务日志和 SSE。
- 上传文件必须使用随机临时文件；不要把浏览器提交的文件名直接当作路径。
- TLS identity 必须来自宿主安全存储；不要为生产代码提供 trust-all 适配器。
- 如果需要长期运行的服务，调用方必须处理后台限制、前后台切换、Scene disconnect 和服务停止。

## 明确的非目标

该模块不是公网 HTTP server、反向代理或 WebDAV 服务；PTools 不提供 NAT 穿透、身份系统、账号管理或任意文件系统授权。

