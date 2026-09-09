# PooTools 发布流程

## 版本号

当前版本号需要保持一致：

- `PooTools.podspec` 的 `s.version`
- Git tag（格式：`<version>`，不带 `v` 前缀）
- `CHANGELOG.md` 对应版本章节

当前仓库代码基线为 `5.8.9`，上一正式标签为 `5.7.9`；本轮发布目标为 `5.8.9`。
5.8.9 是当前 5.x 稳定基线；5.9.x 只在完成源码、依赖、Xcode 和宿主回归后再进入发布流程。
`Package.swift` 和 Xcode 工程只维护平台与 Swift 语言契约，不重复维护产品版本号。

5.x Core 分阶段治理任务记录在 [PTools_PRE_6_ROADMAP.md](PTools_PRE_6_ROADMAP.md)。每项任务完成后才
将对应条目标记为 `✅`；发布脚本会阻断当前版本章节中仍处于 `🚧`、`⬜` 或 `⛔`
状态的任务。

`Package.swift` 与 Xcode 工程不单独维护产品版本号，避免三套构建入口产生漂移。
兼容入口、唯一实现和 6.0.0 删除条件见 [MIGRATION_6.md](MIGRATION_6.md)。

## 发布前检查

```bash
bash Scripts/validate_build_entries.sh
bash Scripts/validate_core_source_contract.sh
bash Scripts/validate_release.sh
bash Scripts/validate_quality_scans.sh
git diff --check
pod lib lint PooTools.podspec --allow-warnings --skip-tests
xcodebuild -workspace PooTools.xcworkspace -scheme PooTools-Example -destination 'generic/platform=iOS Simulator' -configuration Release CODE_SIGNING_ALLOWED=NO build
```

随后在 Xcode 中使用 `PooTools-Example` scheme 完成 iOS Simulator 构建，并确认 GitHub Actions 的 Quality 检查通过。

如果 Xcode 构建仅因外部 Pods 的 Swift 6 并发诊断失败，必须记录为环境阻断，不能将该状态标记为源码警告通过，也不能创建版本 tag。

## 发布步骤

1. 更新 `PooTools.podspec`、`Podfile.lock`、`CHANGELOG.md` 和本文件中的当前版本信息。
2. 完成发布前检查并提交版本变更。
3. 创建并推送版本标签：`git tag -a <version> -m "Release <version>" && git push origin <version>`。
4. 在 GitHub Release 中引用对应的 `CHANGELOG.md` 章节。
5. 发布后验证 CocoaPods 与 Swift Package Manager 的安装入口。

5.8.9 的发布还必须满足：Core
源文件契约无漂移，质量扫描和版本元数据检查通过，并且 Xcode Debug/Release 不是由外部 Pods、Swift Package
依赖、磁盘空间、Metal 工具链或链接器问题阻断。未满足条件时只保留阻断记录，不创建新的 5.9.x 标签。
