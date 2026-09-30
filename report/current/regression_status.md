<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/report_current_summaries.rb
Source revision: 9e7888628a473d8c424ab2bd6259d8a1dc8a6b9e
Generated at: 2026-09-30T15:19:16Z
-->

# PTools 当前回归状态

本报告只记录当前基线和验证边界；静态通过不等于真机或真实宿主通过。

- 当前 podspec 版本：`5.58.0`
- 最新正式 Git tag：`5.57.4`
- 当前提交：`9e7888628a473d8c424ab2bd6259d8a1dc8a6b9e`
- 当前状态：`static_and_build_evidence_required`

## 发布前仍需人工确认

- [ ] PooTools-Example iOS Simulator Debug / Release
- [ ] CocoaPods Core 与目标 subspec lint
- [ ] 真机多 Scene、权限、媒体和导航回归
- [ ] PTInstruments CPU、内存、FPS、hitch 和长会话基线
- [ ] 至少一个真实宿主项目完成迁移回归

证据文件应放入 `report/baselines/<version>/`，不覆盖当前报告。
