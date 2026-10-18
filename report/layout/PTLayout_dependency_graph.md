# PTLayout 5.67 dependency graph

```text
PToolsConstraintLayout -> UIKit / Foundation
PToolsConstraintLayout -/-> SnapKit
PToolsConstraintLayout -/-> ptools / PToolsUIFoundation / PooToolsLayout
ptools -> PToolsConstraintLayout (controlled aggregate edge)
PTLayoutConsoleBridge -> PTNSLogConsole (aggregate-only conditional bridge)
```

The standalone product is intentionally independent. The aggregate target keeps the legacy SnapKit boundary for existing 5.x consumers.

中文：独立产品不依赖 SnapKit；聚合入口只保留受控的兼容边界。
Español: El producto independiente no depende de SnapKit; el agregado conserva solo el límite de compatibilidad controlado.
