<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: 260ebd36bb21c8cf640a52fdccfe5fd0ff1fc907
Source version: 5.60.0
Source inputs digest: 87af7314bbf35c8c04c3e91f7a8e18b55acd7ba0262c77f66db3182dae74a6b0
Generator version: 1
Generator: Scripts/report_current_summaries.rb
Generated at: 2026-10-02T14:08:37Z
-->

# PTools 当前回归状态

本报告只记录当前基线和验证边界；静态通过不等于真机或真实宿主通过。

- 当前 podspec 版本：`5.60.0`
- 最新正式 Git tag：`5.59.0`
- 当前提交：`260ebd36bb21c8cf640a52fdccfe5fd0ff1fc907`
- 当前状态：`static_and_build_evidence_required`

## 发布前仍需人工确认

- [ ] PooTools-Example iOS Simulator Debug / Release
- [ ] CocoaPods Core 与目标 subspec lint
- [ ] 真机多 Scene、权限、媒体和导航回归
- [ ] PTInstruments CPU、内存、FPS、hitch 和长会话基线
- [ ] 至少一个真实宿主项目完成迁移回归

证据文件应放入 `report/baselines/<version>/`，不覆盖当前报告。
