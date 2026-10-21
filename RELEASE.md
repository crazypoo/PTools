# PTools 发布清单

## 5.69.0

- [x] `VERSION`、`PooTools.podspec` 的 canonical version source、CHANGELOG、README、ROADMAP 和 Podfile.lock 同步到 `5.69.0`。
- [x] PhotoPicker 拆分为页面协调、实例 Session、唯一选择 Store、Selection Policy、PhotoKit Album Repository、提交协调器和纯 UI View/Cell 边界。
- [x] 图片/视频混选、pending 选择、取消、编辑替换、相册变化、截图刷新和临时视频回收路径已完成代码级收敛。
- [x] 删除旧 `PTFetchImageOperation`，保留 `PTMediaRequestCoordinator`、`PTMediaSaveUI` 和公开 Manager/API 兼容入口。
- [x] SwiftPM manifest、`git diff --check`、PooTools-Example iOS Simulator Debug / Release 构建和 PhotoPicker 选择策略静态测试准备完成。
- [x] N00 首屏阶段补齐统一 `PTMediaPickerTrace` signpost；不记录媒体内容、字节或用户文件名。
- [x] N01 首屏采用有界批次并渐进建模；退出、切换相册和刷新使用 generation 取消过期任务。
- [x] N02 刷新先走边界快照，同边界的 PhotoKit 通知仅在必要时进入一次完整 fallback；无变化不重建、不提交 Grid。
- [x] N03/N04/N05 补齐多行 Row 替换与滚动锚点、公开异步视频大小校验、CIImage 保存 fallback 和临时副本失败/取消清理。
- [x] H01-H04 收敛选择投影、PhotoKit 变更事务、Snapshot generation 门禁和拍照自动选中的资源级 exactly-once 终态；新增 `PTMediaSelectionProjectionTests`。
- [x] P01：PhotoKit 事务按资源 ID 增量投影，旧模型稳定复用，新增资源和变化资源独立建模。
- [x] P02：Grid 提交状态区分 desired、scheduled、committed 和 in-flight，no-op、过期 completion、局部插入/删除/内容更新均有明确终态。
- [x] P03/P04：缩略图占位与 nil/错误/取消保护、拍摄资源有界可见性等待、超时清理和安全诊断已落地。
- [x] P05：实例级 `onFeedback` 与默认提示兼容路由、保存 operationID 及终态事件已落地。
- [x] P06：PhotoPicker 已迁移到 `cellInCollectionV2` / `configureCell` 单一路径，并保留 `PTCollectionView` 局部更新回退。
- [x] P07：新增 PhotoPicker 回归测试、Demo 双反馈入口、迁移文档和本轮源码验证记录。
- [ ] CocoaPods 独立 consumer、PhotoKit 真机/宿主回归、视觉回归和性能对照仍需完成后才创建正式 `5.69.0` tag。

## 5.68.0

- [x] `VERSION`、`PooTools.podspec` 的 canonical version source、CHANGELOG、README 和迁移指南同步到 `5.68.0`。
- [x] `PTCodeView` 外部文本/图片刷新、生命周期、无障碍和空尺寸绘制安全边界已实现，并登记 SwiftPM `PooToolsCodeView` 与 CocoaPods `CodeView` 的一致映射。
- [x] CodeView 独立 iOS 测试 target、三语模块文档和 Example 外部内容演示已补齐。
- [x] `PTBannerView` 已统一使用 `PTCollectionView` 的 viewport 分页、无限循环、拖动生命周期和自动轮播协调器；Banner 内部滚动条默认隐藏。
- [x] Debug / Release arm64 iOS Simulator Xcode 完整构建通过；构建使用 `/tmp` DerivedData，未在仓库留下 `xcresult`。
- [x] `git diff --check` 和 SwiftPM manifest 检查通过。
- [ ] SwiftPM/CocoaPods 独立 consumer、视觉回归、Instruments、`iphone26` 真机回归完成后，才允许创建正式 `5.68.0` tag。

## 5.67.1

- [x] `VERSION`、podspec 版本来源、CHANGELOG、README 和 PTLayout 文档同步到 `5.67.1`。
- [x] PTLayout P0 引擎修复、原子组激活、诊断缓存上限和真实安装计数已落地。
- [x] F01-F56 均有 XCTest 方法和机器可读执行映射；静态 fixture 不再被视为运行时通过。
- [x] Xcode iOS Simulator runtime XCTest 已通过：F01-F56 全部执行并通过；`.xcresult` 已在验证后清理，保留 JSON 和 CSV 摘要。
- [ ] 视觉截图、SPM/CocoaPods consumer 和 `iphone26` 真机验证完成后，才允许创建 `5.67.1` tag。

## 5.67.0

- [x] `VERSION`、`PooTools.podspec`、`CHANGELOG.md`、`README.md` 和 PTLayout 发布报告同步。
- [x] `PToolsConstraintLayout` 的 UIKit/Foundation 独立边界、CocoaPods `ConstraintLayout` subspec、SwiftPM product 和聚合入口已登记。
- [x] 56 个故障夹具、10 个 Demo ID、依赖方向、源码所有权、SnapKit 隔离和迁移覆盖静态门禁通过。
- [x] PooTools-Example iOS Simulator Debug / Release 构建通过。
- [ ] 完成外部 iOS 宿主运行时、视觉回归、性能对比和 watchOS/visionOS/macOS 宿主验证后再创建正式 `5.67.0` tag。

## 5.66.1

- [ ] `VERSION`、`PooTools.podspec`、`CHANGELOG.md`、`README.md` 和 `Podfile.lock` 同步。
- [ ] `PTSearchViewController` 清空输入框后恢复未筛选列表，搜索结果和显式清空行为回归通过。
- [ ] 完成 Xcode Simulator Debug/Release、CocoaPods lint 和宿主真机回归后再创建 `5.66.1` tag。
