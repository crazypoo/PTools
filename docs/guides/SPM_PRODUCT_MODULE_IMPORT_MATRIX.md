# PTools 5.65.8 SwiftPM Product / Module 矩阵

PTools 的 SwiftPM product 名称不总是等于 Swift `import` 名称。调用方应按实际 product 和 module 组合声明依赖，不要依赖 `PooToolsAll` 的传递可见性。

## 常用入口

| SwiftPM product | Swift import | 用途 |
| --- | --- | --- |
| `ptools` | `ptools` | 默认 Core 与 Category 聚合入口 |
| `PToolsCore` | `PToolsCore` | Foundation / UIKit Core 边界中的显式类型 |
| `PToolsUIFoundation` | `PToolsUIFoundation` | UI Foundation 与富文本基础能力 |
| `PToolsNetworkModelCore` | `PToolsNetworkModelCore` | 类型化 Network 响应、快照和模型解码契约 |
| `PToolsFontCatalogCore` | `PToolsFontCatalogCore` | Foundation-only 字体元数据、目录和 FontName 兼容入口 |
| `PToolsSymbols` | `PToolsSymbols` | SF Symbols 类型化解析 |
| `PooToolsNetwork` | `PooToolsNetWork` | 网络请求实现；product 名称保留历史拼写 |
| `PooToolsVideoCache` | `ptools` | 兼容聚合 product，实际模块由 Core 提供 |
| `PooToolsAll` | 不可直接 import | 聚合 product；请改为 import 实际使用的模块 |

## 组件消费规则

每个 target 都必须直接声明其源码使用的模块。例如：

```swift
// SwiftPM
import ptools
import PToolsCore
```

同时在 `Package.swift` 的 target `dependencies` 中声明 `ptools` 和 `PToolsCore`。不要因为 CocoaPods 的 `PooTools/Core` umbrella 能看到符号，就省略 SwiftPM 的直接依赖。

轻量 UIKit 操作优先使用 UIKit 原生 API；只有确实使用 PTools Category 时才添加 `ptools`。Feature 不应通过 `PooToolsAll` 反向扩大依赖，也不应复制同名 Category。

## 验证

```sh
python3 Scripts/CI/audit_spm_target_graph.py
python3 Scripts/CI/audit_spm_symbol_ownership.py
python3 Scripts/CI/audit_spm_conditional_compilation.py
python3 Scripts/CI/audit_spm_resources.py
python3 Scripts/CI/generate_spm_consumer_fixtures.py
```

`Tests/SPMConsumerFixtures/ProductImportMatrix.json` 和 `report/spm/spm_product_matrix.csv` 中的 `not_run` 不是通过。要获得真实证据，必须提供 iOS Xcode consumer host：

```sh
SPM_CONSUMER_FIXTURE_PROJECT=/absolute/path/Consumer.xcodeproj \
SPM_CONSUMER_SCHEME=Consumer \
bash Scripts/CI/build_spm_consumer_matrix.sh --require-build
```

当前仓库的 `PooTools-Example` 是 CocoaPods 宿主，不能代替逐 product 的隔离 consumer。
