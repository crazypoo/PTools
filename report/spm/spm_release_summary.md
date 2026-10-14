# PTools 5.64.5 SwiftPM 跨 target 修复报告

生成日期：2026-10-14  
基线提交：`93b291c1`（报告同时包含当前工作区修复）

## 静态覆盖

- SwiftPM targets：179
- SwiftPM products：155
- 已归属 Swift 源文件：1229
- 依赖环：0
- 源码归属异常：0
- 高置信度跨 target finding：964 条，当前 open：0
- 条件编译分支：2596
- 资源声明/源码读取记录：76

## 已落地修复

- Banner 的两个轻量子视图清理操作改用 UIKit 原生 `removeFromSuperview()`，没有为简单操作扩大依赖。
- Segmented、MediaViewer、VideoEditor、MessageKit、Guide、ScrollBanner、SignView 补齐 SwiftPM 下的直接 `ptools` import。
- ImageEditor、Input、PageControl、Picker、QRCodeScan、VideoEditor 补齐 `PToolsCore` 的直接依赖和 import。
- CheckUpdate 补齐 `ptools` 的直接依赖和 `appfont` 所需 import。
- Package.swift、Podfile.lock、Pods/Manifest.lock、README、ROADMAP、CHANGELOG 已同步到 5.64.5。

## 构建证据和阻断

- `swift package dump-package`：通过。
- `Scripts/validate_quality_scans.sh`：通过；公共 API 基线与 5.64.4 对比为 0 删除、0 新增，既有 5.x 合约检查通过。
- 全量 `PooTools-Example` Debug iOS Simulator 构建：通过；最终日志为 `/tmp/PTools-5.64.5-debug-final.log`，末尾为 `** BUILD SUCCEEDED **`。
- 全量 `PooTools-Example` Release iOS Simulator 构建：通过；最终日志为 `/tmp/PTools-5.64.5-release-final.log`，末尾为 `** BUILD SUCCEEDED **`。
- 155 个 product 的逐个隔离 consumer Debug/Release 构建：当前仓库没有独立 iOS consumer host，矩阵保留 `not_run`，不伪装为通过。
- `validate_spm_release_gate.py` 默认门禁会因 155 个 `not_run` 项目阻断；本轮仅使用 `--allow-not-run` 验证报告完整性。
- CocoaPods lint：依赖本机 CocoaPods/Ruby/ffi 环境，和 SwiftPM 报告分开记录。

## 复现命令

```sh
python3 Scripts/CI/audit_spm_target_graph.py
python3 Scripts/CI/audit_spm_symbol_ownership.py
python3 Scripts/CI/audit_spm_conditional_compilation.py
python3 Scripts/CI/audit_spm_resources.py
python3 Scripts/CI/generate_spm_consumer_fixtures.py
bash Scripts/CI/build_spm_consumer_matrix.sh --require-build
```

正式发布前必须提供 iOS consumer host，执行不带 `--allow-not-run` 的 `validate_spm_release_gate.py`，并逐项补齐 `report/spm/spm_product_matrix.csv` 的 Debug/Release 证据。
