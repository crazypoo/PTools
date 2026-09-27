# GCDWebServer 使用审计

## 结论

5.28.0 的活动源码和依赖图不再使用 GCDWebServer 或 GCDWebUploader。历史 CocoaPods subspec
`PooTools/GCDWebServer` 仅保留一个无第三方依赖的兼容别名，并转发到 `PooTools/HTTPFilePortal`。

| 文件/入口 | 原能力 | 旧 API | 新入口 | 状态 |
| --- | --- | --- | --- | --- |
| `PooTools/PTFuncDetailViewController.swift` | 本地文件浏览与上传 | `GCDWebUploader` | `PTHTTPFilePortal` | ✅ 已迁移 |
| `PooTools.podspec` | CocoaPods 安装入口 | `GCDWebServer` / `WebUploader` | `HTTPServer` / `HTTPFilePortal` | ✅ 已移除依赖 |
| `PooTools/InputAll` | 全量安装 | `PooTools/GCDWebServer` | `PooTools/HTTPFilePortal` | ✅ 已迁移 |
| SwiftPM | HTTP Server product | 无 | `PToolsHTTPServer` | ✅ 新增 |
| SwiftPM | 浏览器文件门户 | 无 | `PToolsHTTPFilePortal` | ✅ 新增 |

## 兼容边界

- 旧 subspec 名称只为降低升级阻力，不提供第三方类型的 source-compatible clone。
- `GCDWebUploaderDelegate`、`GCDWebServerRequest` 和 `GCDWebServerResponse` 不再出现在生产 API。
- 调用方应迁移到 `PTHTTPServer`、`PTHTTPFilePortal`、`PTHTTPRequest` 和 `PTHTTPResponse`。
- 历史文档和 changelog 可以提及旧名称，但活动源码、Package.swift、podspec、Podfile.lock 和 Tests 不能再引入它。

## 审计命令

```bash
bash Scripts/validate_gcdwebserver_removal_5_28.sh
pod install --no-repo-update
swift package dump-package
```

