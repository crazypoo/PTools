# 5.8.0 Build Validation

验证时间：2026-09-09（Asia/Shanghai）  
Xcode：`/Applications/Xcode-beta.app`（Xcode 27.0）  
目标：`PooTools-Example` / `generic/platform=iOS Simulator` / `arm64`  
代码签名：关闭  

## 结果

| 配置 | 结果 | 说明 |
| --- | --- | --- |
| Debug | ⛔ 阻断 | 外部 `Pods/KituraContracts` 在 Swift 6 并发诊断阶段失败 |
| Release | ⛔ 阻断 | 外部 `Pods/KituraContracts` 在 Swift 6 并发诊断阶段失败 |

## 外部阻断详情

- `Pods/KituraContracts/Sources/KituraContracts/BodyFormat.swift:60`：`BodyFormat.json` 使用的 `BodyFormat` 不是 `Sendable`。
- `Pods/KituraContracts/Sources/KituraContracts/CodableQuery/Extensions.swift:336`：`_iso8601Formatter` 是非隔离的全局可变状态。
- `Pods/KituraContracts/Sources/KituraContracts/Contracts.swift`：同时报告 `Sendable` 结构体字段、闭包和不可变解码字段相关警告。
- `Pods` 的 `Create Symlinks to Header Folders` 脚本阶段缺少输出文件，Xcode 报告每次都会执行的警告。

以上均属于外部 Pods 或工程脚本阶段，本批没有修改 Pods 源码、依赖版本或工程配置。

## PooTools 源码诊断

两份构建日志中没有匹配到 `PooToolsSource` 的 `error` 或 `warning` 诊断；但由于构建在外部 `KituraContracts` 阶段终止，不能据此宣称 PooTools 完整 Xcode 构建通过。

## 运行的检查

- `bash Scripts/validate_58_contracts.sh --check`：通过。
- `bash Scripts/validate_quality_scans.sh`：通过；本地化脚本仍报告 `zh-Hant` 与 `zh-Hans` 有 223/262 条翻译值相同，该项按现有策略只告警。
- `bash Scripts/validate_build_entries.sh`：通过。
- `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer bash Scripts/validate_xcode_source_warnings.sh`：被同一组外部 `KituraContracts` Swift 6 错误阻断；PooTools target 配置检查通过。
- `swift package dump-package`：通过。
- `git diff --check`：通过。

构建原始日志保存在本机临时目录：

- `/tmp/PTools-5.8.0-example-debug.log`
- `/tmp/PTools-5.8.0-example-release.log`
