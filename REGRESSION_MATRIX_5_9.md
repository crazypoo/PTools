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
| 5.9.2 测试目标 | Core、UI、Network、List、Navigation、Media、Permission | SwiftPM iOS test targets | 已建立；入口受外部依赖阻断 |
| Collection 基准 | 1k/10k 全量、增量、快速更新、旋转、瀑布流、Photo 预取 | XCTest measure + Example | 基准已建立，UI/真机待运行 |
| Network 基准 | 100 并发、dedup、cache、retry、下载、取消 | XCTest 夹具 + 网络宿主 | dedup 基准已建立，其余待运行 |
| Media 基准 | 缩略图缓存、4K 降采样、复用、视频准备、内存警告 | XCTest 夹具 + Instruments | 夹具已建立，真机待运行 |
| Navigation harness | push/pop、interactive cancel、多 nav、host delegate、TabBar | XCTest + Example | 栈/入口已建立，转场待运行 |
| Dynamic Type | 最大字体和布局溢出 | Example | 待运行 |
| Reduce Motion | 开启/关闭动画设置 | Example | 待运行 |
| Reduce Transparency | 系统透明度设置 | Example | 待运行 |
| SwiftPM | Debug/Release iOS 17 | Xcode | 测试入口受 lottie 获取阻断 |
| CocoaPods | Core 与模块 lint | pod lib lint | 待运行 |
| 外部依赖 | Bugly、Kitura、Metal、lottie | 构建日志分类 | 已知阻断 |

## 发布规则

未完成项不能被写成“通过”。外部 Pods 阻断必须与 PooTools 源码 warning 分开报告。
