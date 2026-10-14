# SwiftPM / CocoaPods 跨 target 一致性说明

5.64.5 将 SwiftPM 独立 target 的隐式依赖改为显式边界，同时保留 CocoaPods 的公开 subspec 和旧调用方式。

## 依赖边界

- CocoaPods 的 `PooTools/Core` 是历史聚合 subspec；SwiftPM 的 `ptools`、`PToolsCore`、`PToolsUIFoundation` 等是独立 target。
- `PooToolsBanner` 中只需清理 UIKit 子视图的路径使用原生 `removeFromSuperview()`，避免为了一个基础操作拉入完整 Core 聚合模块。
- PageControl、Picker、Input、ImageEditor、VideoEditor、QRCodeScan 和 CheckUpdate 对 Core 或 Category 的使用必须在 SwiftPM 中有直接 `dependencies` 与 `import`。
- `PooToolsNetwork` / `PooToolsNetWork`、`PooToolsVideoCache` / `ptools` 是冻结的兼容名称映射，不能在业务项目中自行添加同名模块。

## 条件编译

`POOTOOLS_COCOAPODS` 仍用于保持 CocoaPods 兼容分支。新增或修改 `#if SWIFT_PACKAGE`、`#if canImport(...)`、`#if POOTOOLS_COCOAPODS` 时，同时运行：

```sh
python3 Scripts/CI/audit_spm_conditional_compilation.py
bash Scripts/validate_build_entries.sh
```

不得用全局 `import PooToolsAll` 或无依据的宏把源码从某个 target 隐藏掉。

## 发布前检查

```sh
bash Scripts/validate_release.sh --metadata-only 5.64.5
python3 Scripts/CI/validate_spm_release_gate.py --allow-not-run
```

`--allow-not-run` 只适合开发阶段审阅报告；正式发布必须去掉该参数，并提供 155 个 iOS product 的隔离 consumer Debug/Release 证据。CocoaPods lint、外部 Pod 编译错误和真实宿主视觉/运行时回归必须单独记录，不能被 SwiftPM 静态报告覆盖。
