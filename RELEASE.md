# PTools 发布清单

## 5.67.1

- [x] `VERSION`、podspec、CHANGELOG、README 和 PTLayout 版本化报告同步到 `5.67.1`。
- [x] PTools 自有普通 UIKit 约束迁移到 `ptLayout`；旧 SnapKit/ConstraintGroup、AppKit 和 PTLayout 内核边界有明确例外记录。
- [x] SwiftPM manifest、CocoaPods 工程和 PooTools-Example iOS Simulator Debug/Release 构建已验证；独立无 SnapKit consumer 与外部运行时继续执行最终矩阵。
- [x] 布局审计升级为 source SHA、target、owner、decision、exception、regression case 和 evidence 数据模型。
- [ ] F01–F56 外部 XCTest 宿主、SnapKit 运行时差异、同机性能、视觉/Duo/真机生命周期验证完成后，才可标记 `release_approved`。
- [ ] 未完成上述外部证据前，不创建或移动已发布版本的 tag。

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
