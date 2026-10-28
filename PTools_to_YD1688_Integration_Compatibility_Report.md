# YD1688 → PTools 反哺实施兼容性报告

**日期**：2026-10-28  
**PTools 基线**：`fc0ba68f868e894d93bf04fc8f6cd366fd8d05d6` / `VERSION = 5.69.0`  
**实施范围**：R01–R09 反哺计划在 PTools 侧的增量落地  
**业务替换策略**：本轮只提供可选能力和兼容适配，不直接改写 YD1688 的生产调用、金额计算、购物车、下单、支付或数据库数据。

## 1. 实施结论

本轮已将 R01–R07 的公共能力落到 PTools，并完成 R08、R09 的边界核对：

| 条目 | 状态 | PTools 落点 | 兼容策略 |
| --- | --- | --- | --- |
| R01 分页状态机 | 已完成 | `PTPaginationMachine`、`PTPaginationConfiguration`、`PTPaginationRequestToken`、`PTSearchPaginationAdapter` | 旧 `PTSearchPagination` API 保留；新 token 入口 opt-in |
| R02 加载代次控制 | 已完成 | `PTLoadGenerationCoordinator` / `PTGenerationGate` | `PTSearchTaskCoordinator` 增加代次门控，旧任务接口保留 |
| R03 SKU/规格选择 | 已完成 | 可选 SwiftPM 产品 `PToolsVariantCore`；CocoaPods 可选 subspec `VariantCore` | 不依赖 UIKit、YD 模型或商城 API；默认不接管业务订单链路 |
| R04 浮动输入 | 已完成 | `PTFloatingPlaseholderTextField` 的活动状态、高度回调、实际富文本高度、尾部操作动态更新 | 旧配置与旧回调保留；新回调和尾部操作方法 opt-in |
| R05 群头像拼图 | 已完成 | `PTGroupAvatarComposer` | UIKit 条件编译；空输入和数量上限安全处理 |
| R06 Vision 矩形检测 | 已完成 | `PTVisionRectangleDetection` | UIKit/Vision 条件编译；异步检测、边界裁切和取消显式返回错误 |
| R07 图片双预算预处理 | 已完成 | `PTMediaImagePreprocessor` | 复用 `PTImageDownsampler`；尺寸和编码字节预算显式选择 |
| R08 Tag/Chip | 已核对 | 现有 `PTTagLabelScrollView`、`PTTagLayoutModel` 与标签布局能力 | 未新增重复控件；后续仅在真实缺口出现时扩展 |
| R09 SQLite/iCloud 合并 | 仅研究 | 未把 YD 的 FMDB/iCloud 文件同步搬入 PTools | 不新增生产同步 API；现有 `PTDatabase` actor/事务/备份能力保持独立 |

## 2. Core-first 与模块边界

- R01、R02、R03 的核心算法只使用 Foundation 和 Sendable 值类型，适合在 Swift 6 strict concurrency 下独立编译。
- R03 的 `PTVariantConflictPolicy` 显式区分 `.keepLatestSelection` 与 `.rejectNewSelection`，YD1688 可以先用 fixture 对照，确认后再选择兼容策略。
- R04 复用 PTools 已有 `PTFloatingPlaseholderTextField`、`PTInputAppearance`、`PTRichText` 和图片加载入口，没有复制 YD 的同名输入控件。
- R05、R06、R07 复用 PTools 的 UIKit、Vision、ImageIO 和 `PTImageDownsampler` 边界；业务上传服务仍由 YD1688 管理。
- `PToolsVariantCore` 是独立可选 SwiftPM product；`PToolsCore` 默认产品不因此引入商城算法。
- CocoaPods 提供可选 `VariantCore` subspec；未把它加入默认聚合入口，以避免现有消费者产生隐式依赖变化。

## 3. YD1688 接入建议

### 3.1 推荐顺序

1. 先在 YD1688 的只读 fixture 中接入 R01/R02，比较请求次数、页码、数据顺序和刷新后的旧回包处理。
2. 用真实 SKU fixture 将 YD adapter 映射成 `PTVariantOption` / `PTVariant`，对比 `selected`、`optionStates`、`matchedVariant` 和 `priceRange`。
3. 只在上传调用方显式选择 `PTMediaImagePreprocessor.Configuration` 后，再评估 R07；不要默认改变现有 MIME、字段名、图片方向或质量策略。
4. R04、R05、R06 先在 demo 或孤立页面使用，不替换现有生产页面的布局和媒体回调。

### 3.2 不应直接接入的边界

- 不把 YD 的商品、购物车、订单、支付、全局配置、数据库模型或服务地址带入 PTools。
- 不让分页新 token 入口悄悄改变旧搜索 API 的计页语义。
- 不把 `PTVariantSelectionEngine` 自动连接到购物车调价、最小购买量或支付回调。
- 不把 Vision 检测结果当作业务成功结果；检测失败、取消和无矩形必须由业务层处理。
- 不把图片压缩失败解释为网络失败，也不由公共预处理器负责网络重试。

## 4. 平台兼容矩阵

| 能力 | iOS 17+ | macOS | watchOS | visionOS |
| --- | --- | --- | --- | --- |
| R01/R02 Foundation 核心 | 支持 | 支持 Foundation 入口 | 支持 Foundation 入口 | 支持 Foundation 入口 |
| R03 `PToolsVariantCore` | 支持 | 支持 | 支持 | 支持 |
| R04 浮动输入 UIKit | 支持 | 不提供 UIKit 输入适配 | 不提供 UIKit 输入适配 | 仅在 UIKit 可用边界使用 |
| R05 群头像 UIKit renderer | 支持 | 条件编译，不承诺 UIKit 入口 | 条件编译，不承诺 UIKit 入口 | 条件编译支持时可用 |
| R06 Vision 矩形检测 | 支持 | 需单独提供平台适配，当前不承诺 | 不承诺 | Vision/UIKit 可用边界支持 |
| R07 ImageIO/ImageDownsampler | 支持 | Foundation/ImageIO 核心可复用 | 需按目标平台 ImageIO 可用性验证 | 支持可用的 ImageIO 边界 |

Foundation-only 能力优先跨平台复用；UIKit、Vision 和媒体能力通过 `canImport` 条件编译，不伪造未验证的平台支持。

## 5. 验证记录

已完成：

- `swift package dump-package`
- `swift build --target PToolsCore`
- `swift build --target PToolsVariantCore`
- `swift build --target PToolsCoreTests`
- `git diff --check`
- PooTools CocoaPods aggregate 的 iOS Simulator Debug Xcode build；刷新 Pods 工程后通过。
- 新增分页、代次、规格选择、群头像和图片预处理契约测试源码。

当前阻断或尚未完成：

- 全量 `swift test --filter PTCoreContractTests` 仍会进入仓库已有的 macOS target 图谱，并在 `PooToolsSource/CheckBox/PTCheckBox.swift` 因 UIKit 依赖解析失败而中止；这不是 R01–R07 核心 target 的编译错误。
- 未在 YD1688 工作区执行业务 fixture 对照、真机视觉回归、Vision 相机输入回归或上传服务压测。
- 未宣称图片峰值内存和耗时的量化提升；需要在 YD1688 真实样本上记录基线与修改后值。

## 6. 生成物与依赖清理说明

- CocoaPods 生成的 `Pods/Pods.xcodeproj` 属于忽略的构建生成物，仅用于让 Xcode aggregate target 看到新增源码，不作为 PTools 源码提交。
- `Podfile.lock` 保留工作区原有修改；本轮仅因 podspec 变化更新 PTools 自身 checksum，未升级第三方依赖，CocoaPods 版本元数据恢复为原有值。
- 运行报告、DerivedData、临时 SPM consumer、xcresult 和测试索引不属于交付内容，验收结束前应清理并确认 `git status` 不出现它们。

## 7. 建议的回滚方式

每项新能力均可通过不调用新入口回到原实现。若 YD fixture 对照发现差异：

1. 保留 PTools 新 API 供继续诊断。
2. 将 YD adapter 指回旧分页、SKU 或图片路径。
3. 不回滚无关模块，也不修改生产订单和支付链路。

