# PTools 发布清单

## 5.68.0

- [x] `VERSION`、`PooTools.podspec` 的 canonical version source、CHANGELOG、README 和迁移指南同步到 `5.68.0`。
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
