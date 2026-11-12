<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: 3f9f7d5b604877bdb4a48d32a53944734c9c5072
Source version: 5.69.0
Source inputs digest: ed60290a1fc9bcf9c6196aef2f4a5f386a8a93a84f766fa6d58cfb4cb854f084
Generator version: 1
Generator: Scripts/report_current_summaries.rb
Generated at: 2026-11-12T02:17:28Z
-->

# PTools 当前回归状态

本报告只记录当前基线和验证边界；静态通过不等于真机或真实宿主通过。

- 当前 podspec 版本：`5.69.0`
- 最新正式 Git tag：`5.67.3`
- 当前提交：`3f9f7d5b604877bdb4a48d32a53944734c9c5072`
- 当前状态：`static_and_build_evidence_required`

## 发布前仍需人工确认

- [ ] PooTools-Example iOS Simulator Debug / Release
- [ ] CocoaPods Core 与目标 subspec lint
- [ ] 真机多 Scene、权限、媒体和导航回归
- [ ] PTInstruments CPU、内存、FPS、hitch 和长会话基线
- [ ] 至少一个真实宿主项目完成迁移回归

证据文件应放入 `report/baselines/<version>/`，不覆盖当前报告。
