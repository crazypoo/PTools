# PTools 路线图

> 当前代码基线：`5.11.14`（来自 `PooTools.podspec`）
>
> 当前最新正式 Git tag：`5.11.14`。

## 范围与约束

PTools 面向 iOS 17+ / Swift 6+。5.x 的主要治理范围是 `PooTools.podspec` 的
`default_subspec = Core` 及其直接扩展边界。公开 API、CocoaPods subspec、SwiftPM product
和第三方依赖在没有迁移证据前保持兼容。

长期规则：

- 当前架构写入 [`docs/architecture/ARCHITECTURE.md`](docs/architecture/ARCHITECTURE.md)。
- Debug 与 PTInstruments 设计写入 [`docs/architecture/DEBUG_AND_INSTRUMENTS.md`](docs/architecture/DEBUG_AND_INSTRUMENTS.md)。
- 发布流程写入 [`docs/maintainers/RELEASE.md`](docs/maintainers/RELEASE.md)。
- 测试方法和发布门槛写入 [`docs/maintainers/QUALITY.md`](docs/maintainers/QUALITY.md)。
- 单次扫描、构建和基准结果写入 `report/`，不混入长期架构文档。
- 新版本不再创建 `ARCHITECTURE_5_12.md`、`PERFORMANCE_BASELINE_5_12.md` 等版本化长期文档。

## 当前 5.11.x 稳定化

以下工作仍属于当前开发线，完成后是否产生新的 patch 版本由实际 bugfix 和发布需要决定：

- ✅ 文档目录重组完成，根目录只保留入口文档。
- ✅ 生成当前 Public API baseline，并由真实源码 revision 标记。
- ✅ 生成当前 CocoaPods / SwiftPM module graph，并检查 Core 边界。
- [ ] 完成 `PTInstruments` 在真实设备上的 CPU、内存、FPS、主线程卡顿和长会话测量。
- [ ] 完成 Debug 多 Scene、Scene disconnect、分屏、旋转和真实宿主回归。
- [ ] 完成 `PooTools-Example` 与至少一个真实宿主的迁移风险记录。
- [ ] 清理 6.0 deprecated inventory，逐项确认调用方、迁移说明和删除条件。
- [ ] 完成 Debug disabled/enabled 的开销对比，并把结果冻结到 `report/baselines/5.11/`。

已落地能力的实现事实维护在当前架构文档和发布记录中，不在路线图重复展开历史任务。

## 6.0 前置条件

### 模块和架构冻结

- [ ] 冻结 Core、UIFoundation、Permission、Network、Media、Debug 的模块图。
- [ ] 冻结公开 API baseline，并对每个变化完成人工批准。
- [ ] 冻结 legacy wrapper、拼写兼容入口和重复实现的删除清单。
- [ ] 确认 Core 不反向依赖 Debug、业务 UI 或宿主工程。
- [ ] 完成 CocoaPods、SwiftPM、Xcode 三套 source membership 与依赖方向检查。

### 迁移和发布冻结

- [ ] [`docs/migration/MIGRATION_6.md`](docs/migration/MIGRATION_6.md) 覆盖所有待删除入口。
- [ ] `PooTools-Example` 不再调用计划在 6.0 删除的入口。
- [ ] 至少一个真实宿主完成 Core、Network、Media、Navigation、Debug 的迁移演练。
- [ ] 完成 Debug / Release、Simulator、Generic Device、CocoaPods lint 和 SwiftPM 验证。
- [ ] 生产 Core 不隐式创建 Debug UI、采样器、DisplayLink、日志 sink 或诊断 observer。

## 6.0 计划

当上述冻结条件全部满足后：

1. 删除已经经过一个完整 5.x 兼容周期、且没有仓库或宿主调用方的 deprecated API。
2. 删除经过人工批准的拼写错误入口和重复实现，保留必要的兼容适配器。
3. 最终确认 Core、Permission、Network、Media、Debug 的边界和安装文档。
4. 更新 CocoaPods、SwiftPM、Xcode 和 README 的安装示例。
5. 发布 6.0 前完成完整质量矩阵、迁移说明和回滚准备。

## 延期能力

以下能力不作为当前 5.11.x 的发布阻断项：

- 完整 Time Profiler call tree。
- Allocations object graph。
- System / Metal Trace。
- Mach stack unwinding、符号化和 dSYM profiler pipeline。

这些能力会显著扩大运行时风险，只有在有明确产品需求和独立性能预算时再立项。

## 验收入口

```bash
bash Scripts/validate_docs.sh
bash Scripts/validate_document_versions.sh
bash Scripts/validate_build_entries.sh
bash Scripts/validate_quality_scans.sh
git diff --check
```

Xcode、真机、真实宿主和 Instruments 的结果必须分别记录；静态检查或单次编译不能替代运行时验收。
