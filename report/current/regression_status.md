<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/report_current_summaries.rb
Source revision: c873550f2d347ba97088f840f8d4655ac652afcd
Generated at: 2026-09-20T08:52:27Z
-->

# PTools 当前回归状态

本报告只记录当前基线和验证边界；静态通过不等于真机或真实宿主通过。

- 当前 podspec 版本：`5.16.0`
- 最新正式 Git tag：`5.15.0`
- 当前提交：`c873550f2d347ba97088f840f8d4655ac652afcd`
- 当前状态：`static_and_build_evidence_required`

## 发布前仍需人工确认

- [ ] PooTools-Example iOS Simulator Debug / Release
- [ ] CocoaPods Core 与目标 subspec lint
- [ ] 真机多 Scene、权限、媒体和导航回归
- [ ] PTInstruments CPU、内存、FPS、hitch 和长会话基线
- [ ] 至少一个真实宿主项目完成迁移回归

证据文件应放入 `report/baselines/<version>/`，不覆盖当前报告。
