# PTools 5.7.9 架构重构前基线

生成日期：2026-09-09（Asia/Shanghai）
代码基线：`d044b657a8db4e94052916cd7ffc9b0f5b749594`
版本基线：`PooTools.podspec = 5.7.9`，上一正式 Tag 为 `5.7.8`
平台契约：iOS 17.0+ / Swift 6.0

## 统计口径

- SPM 产品和 Target：来自 `swift package dump-package`，包含 `PooToolsAll` 聚合产品。
- Core 目录：来自 `PooTools.podspec` 的 `default_subspec = "Core"` 源文件声明。
- Core 第三方依赖：统计 SwiftPM `ptools` Target 的直接外部依赖，不把内部 Target 计入。
- umbrella 依赖：统计 SwiftPM Target 中直接声明 `ptools` 的 Target 数量。
- 并发、单例、弃用和大文件：扫描整个 `PooToolsSource`；数量是源码匹配/声明数量，不代表风险数量。
- 大文件阈值：Swift 文件超过 1000 行。

## 当前指标

| 指标 | 数值 | 来源/说明 |
| --- | ---: | --- |
| SPM products | 82 | `swift package dump-package` |
| SPM targets | 81 | `swift package dump-package` |
| Core directories | 28 | Podspec Core source contract |
| Core direct third-party dependencies | 18 | `ptools` Target dependencies |
| Targets directly depending on `ptools` | 78 | SPM target dependency graph |
| `@unchecked Sendable` occurrences | 75 | `PooToolsSource` scan |
| `nonisolated(unsafe)` occurrences | 0 | `PooToolsSource` scan |
| `static let/var share/shared` declarations | 92 | `PooToolsSource` scan |
| Swift files over 1000 LOC | 21 | `PooToolsSource` line count |
| Deprecated annotations | 64 | `PooToolsSource` scan |
| SwiftPM branch dependencies | 2 | `AttributedString/master`, `SocketRocket/spm-support` |

## 5.8.x 重点风险入口

1. `ptools` 仍被 78 个 Target 直接依赖，Core 与高层能力的依赖方向需要先从图谱入手，不能直接移动文件。
2. Core 仍携带 18 个直接第三方依赖；后续应先区分真正的 Core 依赖和兼容层依赖，再设预算。
3. `PTCollectionView.swift`、`Network.swift`、`PTBaseViewController.swift` 等大文件仍是职责拆分候选，但 5.7.9 不修改其内部结构。
4. `@unchecked Sendable`、全局 `share/shared` 和现有弃用入口需要建立 allowlist 与迁移清单，不能仅按数量机械删除。
5. 两个 branch dependency 会影响可复现构建，纳入 5.9.6 供应链治理，不在 5.7.9 擅自升级依赖。

## 可复核命令

```bash
swift package dump-package > /tmp/PTools-package-5.7.9.json
jq '{products: (.products | length), targets: (.targets | length)}' /tmp/PTools-package-5.7.9.json
rg -n 'branch:' Package.swift
rg -n '@unchecked Sendable|nonisolated\(unsafe\)' PooToolsSource
rg -n 'static (let|var) (share|shared)\b' PooToolsSource
find PooToolsSource -type f -name '*.swift' -exec wc -l {} +
```

这份报告只描述 5.7.9 的起点，不把静态数量当作完成标准；后续每个 5.8.x 阶段应重新生成报告并记录变化原因。

## 5.7.9 验证阻断

以下构建均使用 `/Applications/Xcode-beta.app`、iOS 17+ 目标、未签名构建和独立的临时 DerivedData；失败发生在外部 Pods，未修改 Pods 源码或依赖版本：

| 构建入口 | 结果 | 阻断位置 |
| --- | --- | --- |
| `PooTools` Debug / generic iOS Simulator | 阻断 | `Pods/KituraContracts/Sources/KituraContracts/BodyFormat.swift:60` 的 `BodyFormat.json` Swift 6 并发诊断；同时 `CodableQuery/Extensions.swift:336` 的 `_iso8601Formatter` 全局可变状态诊断 |
| `PooTools` Release / generic iOS Device | 阻断 | 同上 |
| `PooTools` Release / generic iOS Simulator | 阻断 | 同上 |
| `PooTools-Example` Debug / generic iOS Simulator | 阻断 | 同上 |
| `PooTools-Example` Release / generic iOS Simulator | 阻断 | 同上 |

另有 `SocketRocket`、`SwiftDate`、`SwifterSwift`、`Instructions` 及 Metal 工具链搜索路径警告；这些属于外部依赖或本机工具链问题，不计入 PooTools 源码警告。由于构建矩阵未通过，本轮不创建 `5.7.9` Git tag。

`pod lib lint PooTools.podspec --allow-warnings --skip-tests --platforms=ios --fail-fast` 同样未通过，失败原因是 lint 临时工程中多个外部 Pod 的 iOS Simulator deployment target 低于当前 Xcode 27 支持的最低版本（15.0）；该问题不属于 PooTools 源码，未通过修改 Podspec 或 Pods 源码规避。
