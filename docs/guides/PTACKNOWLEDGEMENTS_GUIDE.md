# PTAcknowledgements 5.66.0

## 模块边界

| 产品 | 依赖 | 用途 |
| --- | --- | --- |
| `PToolsAcknowledgementsCore` | Foundation | 模型、离线读取、查询、筛选、统计、原文、导出、actor Repository |
| `PToolsAcknowledgements` | Core + UIKit；PTools UIKit 可用时复用 `PTBaseViewController` | 列表、搜索、详情、复制和分享 |
| `pt-acknowledgements` | Core，macOS 构建主机 | 扫描 Package.resolved、Podfile.lock、checkout 和手工覆盖，生成清单 |

Core 是默认的最小数据边界，不引入 UIKit、SnapKit、网络请求或完整 `ptools`。UIKit 列表和详情页只消费 Core 值类型；在 PTools UIKit target 可用时，`PTAcknowledgementsViewController` 与 `PTAcknowledgementDetailViewController` 都显式继承 `PTBaseViewController`。

## 生成与验证

```sh
bash Scripts/pt_acknowledgements_build.sh
bash Scripts/validate_acknowledgements.sh .build/acknowledgements/PTAcknowledgements.json
```

Build Phase 可以通过 `PT_ACK_PACKAGE_RESOLVED`、`PT_ACK_PODFILE_LOCK`、`PT_ACK_OVERRIDES` 和 `DERIVED_FILE_DIR` 指定输入输出。生成器只读本地文件，不在 App 运行时扫描工程或访问网络。

Release/CI 应将 `--strict` 校验作为阻断门禁，并确认 JSON 已复制到正确的 App target bundle。Debug 可以使用 `review` / `unverified` 条目辅助开发，但不能把缺失原文当成“没有依赖”。

## 自定义 UI 与手工条目

调用方可以只导入 `PToolsAcknowledgementsCore`，将 `manifest.entries` 交给自己的 `PTCollectionView`、UITableView 或 SwiftUI 页面；也可以注入 `PTInMemoryAcknowledgementsDataSource`。手工条目必须提供可公开展示的完整许可证原文，并保持稳定 `id`、版本和来源。

```swift
let entry = PTAcknowledgement(
    id: "vendor.example-sdk",
    name: "Example SDK",
    version: "1.0.0",
    sourceManagers: [.manual],
    licenseExpression: "Commercial",
    licenseTexts: [PTLicenseDocument(fileName: "LICENSE", text: suppliedText)],
    verification: .review
)
let manifest = try PTAcknowledgementsProvider.make(entries: [entry])
```

## 平台与并发

Core 的值类型和 actor Repository 可在 Package.swift 声明的 Apple 平台边界中独立使用。UIKit 页面只在有 UIKit 的目标中编译，当前 UI 最低为 iOS 17；macOS、watchOS、visionOS 使用 Core 时不携带 UIKit。页面状态更新在 `@MainActor`，跨 actor 只传递不可变的 `Sendable` Manifest/Entry 快照。

## 安全和合规

许可证文本来自构建期本地输入；模块不上传源码、不保存令牌、不把远程 Markdown 伪装为法律原文。`PTAcknowledgements.report.json` 供 CI 审核，不应默认打进生产 App。最终许可证义务仍由项目开发者和法务确认。
