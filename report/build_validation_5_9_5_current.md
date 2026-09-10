# PTools 5.9.5 当前验证记录

日期：2026-09-10

本记录对应当前工作树的兼容切片，不代表 5.9.x 全部路线图项目已经完成，也不创建新版本或 Git tag。

## 静态验证

- 修改后的 Swift 文件使用 iOS Simulator SDK 执行前端语法解析：通过。
- `swift package dump-package`：通过。
- `bash Scripts/validate_quality_scans.sh`：通过；仅保留现有 `zh-Hant` / `zh-Hans` 重复翻译提示。
- `git diff --check`：通过。
- 未新增 `as!`、`try!`、`nonisolated(unsafe)` 或未经登记的 `@unchecked Sendable`。
- 公开 API 报告已重新生成：`PUBLIC_API_5_9.json`、`report/public_api_5_9.json`、`report/public_api_5_9.md`。

## Xcode 验证

### Debug

执行了 `PooTools.xcworkspace` / `PooTools-Example` / `Debug` / iOS Simulator 构建，输出：

`build/xcode-5.9.5-type-fix-debug.log`

结果：被外部 `Pods/KituraContracts` 阻断，涉及 `BodyFormat.json` 的 Sendable 诊断和 `_iso8601Formatter` 的全局可变状态诊断。当前没有发现 `PooToolsSource` 编译错误。

### Release

执行了 `PooTools.xcworkspace` / `PooTools-Example` / `Release` / iOS Simulator 构建，输出：

`build/xcode-5.9.5-type-fix-release.log`

结果：被外部 `Pods/KituraContracts` 阻断，涉及 `BodyFormat.json` 的 Sendable 诊断和 `_iso8601Formatter` 的全局可变状态诊断。当前没有发现 `PooToolsSource` 编译错误。

## 范围说明

- 未修改 `Pods` 源码、第三方依赖版本、`Podfile.lock` 或 Xcode 工程配置。
- 未伪装外部依赖阻断为 PooTools 源码构建通过。
- 当前未更新产品版本号，也未创建 `5.9.6` 或其他新 tag。
- Core/Permission 独立 target、完整 Network Pipeline、CollectionView 全量协调器、Media/Diagnostics 解耦以及真实宿主/真机/Instruments 验收仍按路线图保留为未完成项。
