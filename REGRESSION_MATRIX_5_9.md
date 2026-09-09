# PTools 5.9.x 回归矩阵

状态说明：静态检查可以在本仓库完成；Xcode、真机和真实宿主项目结果必须单独记录。

| 场景 | 覆盖范围 | 验证方式 | 状态 |
| --- | --- | --- | --- |
| Core API 差异 | Core public declarations | API JSON 比较 | 已建立 |
| Swift 6 并发 | Core 与扩展源码 | 并发报告、Xcode warning | 静态已建立 |
| 场景窗口 | 多 scene、无 key window | Example 人工回归 | 待运行 |
| Network 请求 | Codable、Body、上传、下载、取消 | Xcode + 网络夹具 | 待运行 |
| 图片加载 | 缩略图、GIF、iCloud、Cell 复用 | Example + 真机 | 待运行 |
| 媒体保存 | 图片、视频、权限、失败回调 | 真机相册 | 待运行 |
| VideoEditor | 成功、取消、失败、保存失败 | 真机 | 待运行 |
| CollectionView | skeleton、Diffable、分页、增量更新 | Example 人工回归 | 待运行 |
| Dynamic Type | 最大字体和布局溢出 | Example | 待运行 |
| Reduce Motion | 开启/关闭动画设置 | Example | 待运行 |
| Reduce Transparency | 系统透明度设置 | Example | 待运行 |
| SwiftPM | Debug/Release iOS 17 | Xcode | 受环境阻断 |
| CocoaPods | Core 与模块 lint | pod lib lint | 待运行 |
| 外部依赖 | Bugly、Kitura、Metal | 构建日志分类 | 已知阻断 |

## 发布规则

未完成项不能被写成“通过”。外部 Pods 阻断必须与 PooTools 源码 warning 分开报告。
