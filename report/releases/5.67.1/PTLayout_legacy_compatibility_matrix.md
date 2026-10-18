# PTLayout 5.67.1 legacy compatibility matrix

| Consumer | Boundary | Status |
|---|---|---|
| SwiftPM `ptools` | Existing public aggregation | source-compatible / build required |
| SwiftPM `PToolsUIFoundation` | `ConstraintGroup` and SnapKit adapter | explicit legacy exception |
| CocoaPods `PooTools/Core` | Aggregated historical API | source-compatible / build required |
| CocoaPods `PooTools/ConstraintLayout` | Native standalone layout | no SnapKit dependency |
| Existing `.snp` consumer | Public 5.x compatibility | retained for one compatibility cycle |

中文：旧入口保留，普通新增布局不得继续使用 `.snp`。
Español: Se conservan las entradas legacy, pero los nuevos layouts no deben añadir `.snp`.
