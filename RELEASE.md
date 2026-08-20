# PooTools 发布流程

## 版本号

当前版本号需要保持一致：

- `PooTools.podspec` 的 `s.version`
- Git tag（格式：`v<version>`）
- `CHANGELOG.md` 对应版本章节

本轮发布目标为 `4.5.14`。`Package.swift` 和 Xcode 工程只维护平台与 Swift
语言契约，不重复维护产品版本号。

`Package.swift` 与 Xcode 工程不单独维护产品版本号，避免三套构建入口产生漂移。

## 发布前检查

```bash
bash Scripts/validate_build_entries.sh
bash Scripts/validate_release.sh
bash Scripts/validate_quality_scans.sh
git diff --check
pod lib lint PooTools.podspec --allow-warnings --skip-tests
xcodebuild -workspace PooTools.xcworkspace -scheme PooTools -destination 'generic/platform=iOS Simulator' -configuration Release CODE_SIGNING_ALLOWED=NO build
```

随后在 Xcode 中使用 `PooTools-Example` scheme 完成 iOS Simulator 构建，并确认 GitHub Actions 的 Quality 检查通过。

## 发布步骤

1. 更新 `PooTools.podspec`、`Podfile.lock`、`CHANGELOG.md` 和本文件中的当前版本信息。
2. 完成发布前检查并提交版本变更。
3. 创建并推送版本标签：`git tag v<version> && git push origin v<version>`。
4. 在 GitHub Release 中引用对应的 `CHANGELOG.md` 章节。
5. 发布后验证 CocoaPods 与 Swift Package Manager 的安装入口。
