<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: fd66ba388d2f4b8448b52d434ef02d2fdfd5d56e
Source version: 5.59.0
Source inputs digest: f65daecb5c4328289fea7efd63b8becda2567f98942e0f2f1c6937ded0182aa9
Generator version: 1
Generator: Scripts/report_current_summaries.rb
Generated at: 2026-10-01T14:20:09Z
-->

# PTools 当前回归状态

本报告只记录当前基线和验证边界；静态通过不等于真机或真实宿主通过。

- 当前 podspec 版本：`5.59.0`
- 最新正式 Git tag：`5.58.0`
- 当前提交：`fd66ba388d2f4b8448b52d434ef02d2fdfd5d56e`
- 当前状态：`static_and_build_evidence_required`

## 发布前仍需人工确认

- [ ] PooTools-Example iOS Simulator Debug / Release
- [ ] CocoaPods Core 与目标 subspec lint
- [ ] 真机多 Scene、权限、媒体和导航回归
- [ ] PTInstruments CPU、内存、FPS、hitch 和长会话基线
- [ ] 至少一个真实宿主项目完成迁移回归

证据文件应放入 `report/baselines/<version>/`，不覆盖当前报告。
