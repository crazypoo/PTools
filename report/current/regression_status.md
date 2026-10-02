<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: 26d9a4ef27a56e1b0f3e130443230a878e99abb0
Source version: 5.59.0
Source inputs digest: 6aaa6f6be0320ecf737bee8c48fe02589aa0bdf3bae9f182aa3b2d2a2870b184
Generator version: 1
Generator: Scripts/report_current_summaries.rb
Generated at: 2026-10-02T06:44:02Z
-->

# PTools 当前回归状态

本报告只记录当前基线和验证边界；静态通过不等于真机或真实宿主通过。

- 当前 podspec 版本：`5.59.0`
- 最新正式 Git tag：`5.59.0`
- 当前提交：`26d9a4ef27a56e1b0f3e130443230a878e99abb0`
- 当前状态：`static_and_build_evidence_required`

## 发布前仍需人工确认

- [ ] PooTools-Example iOS Simulator Debug / Release
- [ ] CocoaPods Core 与目标 subspec lint
- [ ] 真机多 Scene、权限、媒体和导航回归
- [ ] PTInstruments CPU、内存、FPS、hitch 和长会话基线
- [ ] 至少一个真实宿主项目完成迁移回归

证据文件应放入 `report/baselines/<version>/`，不覆盖当前报告。
