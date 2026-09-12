# PTools 5.10.x Debug 依赖图

## 目标图

```text
PToolsCore ───────┐
PToolsUIFoundation ─┼──> ptools / Core
PToolsPermissionCore ┘          ↑
                                │
                         PooToolsDEBUG
```

### SwiftPM

- `PToolsCore`、`PToolsUIFoundation`、`PToolsPermissionCore` 是独立基础 target。
- `ptools` 依赖三个基础 target 和 Core 既有第三方库。
- `PooToolsDEBUG` 依赖 `ptools`、Network、Share、SearchBar、PDF；不存在 `ptools → PooToolsDEBUG` 反向边。

### CocoaPods

- `PooTools/Core` 是 Core 的唯一基础 subspec。
- `PooTools/DEBUG` 依赖 `PooTools/Core`、Network、Share、SearchBar、PDF。
- Core 源文件不直接导入 Debug 文件夹，也不通过 Debug 类型完成条件编译耦合。

## 静态验证记录

最近一次依赖方向门禁结果：`pass_with_legacy_allowlist`，共 124 条内部边，2 条已登记的历史兼容边，0 条未登记违规边。

最近一次 Core source contract 结果：CocoaPods Core 目录、SwiftPM Core 目录、SwiftPM 分层 target 和 Xcode Core source membership 均通过。

`PToolsCore` 单独 SwiftPM 构建和 `PooTools-Example` Debug / Release 完整 Xcode 构建均已执行。SwiftPM macOS 构建不能替代 UIKit 目标的 iOS Simulator 构建；CocoaPods lint 和多 Scene 真机验证仍按发布前置条件执行。
