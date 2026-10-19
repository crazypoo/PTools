# PTLayout opt-in migration manifest

<!-- English: Migrate only after an owner, rollback point, and runtime evidence are recorded. -->
<!-- Español: Migra solo después de registrar propietario, punto de rollback y evidencia runtime. -->
<!-- 中文：只有登记负责人、回滚点和运行时证据后才允许迁移。 -->

## Current status

`5.67.1` keeps the production tree on `.snp`. No high-risk Base, navigation, tab bar, collection, media, or editor module is migrated by this recovery change.

The standalone engine is available for opt-in consumers, but each consumer must have:

1. one ownership boundary;
2. a rollback commit or feature flag;
3. a matching SnapKit/PTLayout runtime fixture;
4. iOS Simulator Debug and Release evidence;
5. visual evidence and a host/device note.

## Fixed incident repro paths

| Path | Owner boundary | Update/remake risk | Status | Rollback |
| --- | --- | --- | --- | --- |
| `PTBaseTabBarViewController` accessory height | Tab bar accessory container | update / axis remake | paused | keep `.snp` |
| `PTFusionCell` | cell content container | reuse / dynamic height | paused | keep `.snp` |
| `HoshiTextField` | input control | floating placeholder | paused | keep `.snp` |
| `PTNavigationBarManager` | navigation bar content | safe area / transition | paused | keep `.snp` |
| `PTMediaBrowserController` | media toolbar | rotation / overlay | paused | keep `.snp` |
| `PTMediaLibCell` | picker cell | reuse / image request | paused | keep `.snp` |
| `PTVideoEditorToolsViewController` | editor controls | export / rotation | paused | keep `.snp` |

## Allowed first migrations

Only small standalone demos or new, isolated UIKit views may be added here. A migrated file must be appended to this table with its test name and evidence paths before review.

| Module/file | Runtime test | Visual evidence | Rollback point | Status |
| --- | --- | --- | --- | --- |
| None in 5.67.1 | — | — | — | opt-in only |

## Platform boundary

- iOS, tvOS, and visionOS: UIKit PTLayout runtime path.
- watchOS and macOS: no UIKit PTLayout target; validate only shared Foundation contracts where applicable.

中文：这个清单禁止把全仓字符串替换当成迁移完成标准。
Español: Este manifiesto prohíbe usar un reemplazo global de texto como criterio de migración completada.
