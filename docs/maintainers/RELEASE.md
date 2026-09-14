# PooTools 发布流程

本文件只描述稳定流程，不写“当前版本”或“下一版本”这类容易过期的固定值。正式版本事实由
`PooTools.podspec`、同名 Git tag 和 `CHANGELOG.md` 共同验证；`Package.swift` 与 Xcode 工程
只维护 iOS 17+ / Swift 6+ 构建契约，不重复维护产品版本号。

## Version source of truth

1. 读取 `PooTools.podspec` 的 `s.version`。
2. 发布前确认同名 Git tag 不存在或明确是本次待创建 tag。
3. CHANGELOG 必须有对应正式发布章节；开发版本只放 `Unreleased`。
4. `Podfile.lock` 中 PooTools 的解析版本必须与 podspec 一致。
5. README 和长期架构文档不得硬编码未发布 tag。

## Preflight

```bash
bash Scripts/validate_docs.sh
bash Scripts/validate_document_versions.sh
bash Scripts/validate_build_entries.sh
bash Scripts/validate_core_source_contract.sh
bash Scripts/validate_quality_scans.sh
bash Scripts/validate_release.sh
git diff --check
```

必要时执行：

```bash
pod lib lint PooTools.podspec --allow-warnings --skip-tests
swift package dump-package
```

## Build matrix

必须覆盖：

- SwiftPM Debug / Release，iOS 17+。
- CocoaPods Core 与目标 subspec lint。
- `PooTools-Example` Xcode Debug / Release。
- `PooTools` Core Debug。
- iOS Simulator 与 Generic Device；若使用归档，再执行 Archive。

外部 Pods、签名、链接搜索路径、Metal toolchain 和二进制 framework 问题单独记录为阻断，不能
算作 PooTools 源码通过，也不能通过替换报告文字掩盖。

## Release steps

1. 在 podspec、CHANGELOG 和必要的 lockfile 中同步本次正式版本。
2. 执行文档、静态质量、依赖契约、SwiftPM、CocoaPods 和 Xcode 全部检查。
3. 确认 PooTools 源码 warning、并发诊断和关键运行时回归达到发布门槛。
4. 提交版本变更并创建不带 `v` 前缀的同名 tag：
   `git tag -a <version> -m "Release <version>"`。
5. 推送 tag，并在 GitHub Release 中引用对应 CHANGELOG 章节。
6. 发布后分别验证 CocoaPods、SwiftPM 和 Git tag 安装入口。

## Post-release

- 检查 tag 内的 `PooTools.podspec` 版本与 tag 相同。
- 检查 README 安装入口和 docs 链接。
- 记录构建、真机、真实宿主、性能和隐私结果到 `report/baselines/<version>/`。
- 将已发布版本从 CHANGELOG 的 Unreleased 移到正式章节。
- 不把临时构建产物、DerivedData、Pods 修改或密钥提交到仓库。

## Rollback

若 tag 已创建但发布验收失败：

1. 立即在 CHANGELOG 和发布记录中标记阻断原因。
2. 不覆盖已经推送的 tag；按仓库发布策略创建后续修复版本。
3. 修复代码、文档和报告后重新执行完整矩阵。
4. 发布后续版本前保留失败版本的 report，确保历史事实可追溯。
