# PTools 模块结账清单

这是 5.19.x 的单页结账索引。完整模块事实由自动生成的 package/dependency parity 报告维护；
本清单只记录每个模块在发布前必须确认的契约，不复制实现细节。

## 发布前每个模块必须满足

| 检查项 | 事实来源 | 通过条件 |
| --- | --- | --- |
| Package parity | [`PACKAGE_MATRIX.md`](../architecture/PACKAGE_MATRIX.md) | 每个模块有 A-F 状态和 6.0 处理 |
| Direct dependencies | [`DEPENDENCY_MATRIX.md`](../architecture/DEPENDENCY_MATRIX.md) | 直接依赖、第三方和可移除项已记录 |
| Public API | [`api-baseline/`](../../api-baseline/README.md) | 删除和 breaking signature 有明确结果 |
| Concurrency | `Scripts/validate_quality_scans.sh` | 无新增业务级不安全边界 |
| Build contract | `Scripts/validate_build_entries.sh` | iOS 17+ / Swift 6+ 三套入口一致 |
| Domain validation | [`TEST_MATRIX.md`](TEST_MATRIX.md) | 自动化、宿主、真机和 Instruments 缺口真实标记 |
| Documentation | README / ROADMAP / CHANGELOG / migration | 入口、迁移和发布事实一致 |

## 领域分组

| 分组 | 主要模块 | 责任 |
| --- | --- | --- |
| Core / Foundation | `PToolsCore`、`PToolsUIFoundation`、`ptools` | 值类型、UIKit 基座、场景和调度契约 |
| Navigation / Collection | Base、Router、Tabbar、Collection、Search | 页面生命周期、导航样式、稳定列表身份 |
| Network / Security / Socket | Network、Security、SocketKit | 取消、重试、认证、密钥和连接生命周期 |
| Media / Permission | PhotoPicker、ImagePicker、Media、Permission | 系统对象边界、快照、取消和授权结果 |
| UI Components | Alert、Button、Picker、ScrollBanner、PageControl | 动态颜色、布局、复用和无障碍 |
| Debug / Instruments | LocalConsole、Debug、PTInstruments | 可逆开关、日志隐私、多 Scene 和性能采样 |

## 6.0 入口

5.x 只通过 canonical API 和 deprecated wrapper 过渡；错误拼写、动态 `Any` 入口和兼容宏的删除条件
统一记录在 [`MIGRATION_6.md`](../migration/MIGRATION_6.md)。模块清单通过后才允许冻结公共 API。

