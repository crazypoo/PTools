# Popovers 使用审计

审计范围：`Package.swift`、`PooTools.podspec`、`Podfile.lock`、`PooToolsSource`、`Sources`、`Tests`。

## 结果

| 项目 | 结果 |
|---|---|
| `import Popovers` | 0 |
| 第三方 `Popovers` Pod 依赖 | 0 |
| `aheze/Popovers` URL | 0 |
| PTools 自有 `PTPopover` | 已新增 |
| `PopoverKit` | 保留为 `PooTools/Popover` 兼容别名 |

## 兼容说明

`PopoverKit` 仍保留，避免 CocoaPods 调用方立即修改 subspec；它不再下载或链接第三方 Popovers。新代码使用 `PooToolsPopover` / `PooTools/Popover`。

## 非第三方同名能力

`UIViewController+PTEX` 中的 UIKit `UIPopoverPresentationController` 入口继续保留。它是系统 API，不属于已移除的第三方运行时。

