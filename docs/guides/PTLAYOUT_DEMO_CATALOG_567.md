# PTLayout Lab 5.67.1 Demo Catalog

<!-- English: Stable IDs are the contract used by the Example catalog and UI automation. -->
<!-- Español: Los IDs estables son el contrato del catálogo Example y de la automatización UI. -->
<!-- 中文：稳定 ID 是 Example 目录和 UI 自动化使用的契约。 -->

The Example catalog exposes these ten stable routes:

1. `ui.layout.snapkit-compatibility` — equality, inequality, edges, size, center, priority and ratio.
2. `ui.layout.missing-superview-no-crash` — PTL001 and no accidental activation.
3. `ui.layout.size-only-without-parent` — standalone width/height success.
4. `ui.layout.cross-tree-error` — PTL002 without an Auto Layout exception.
5. `ui.layout.safe-remake` — failed replacement keeps the old group.
6. `ui.layout.update-mismatch` — update does not silently create a new constraint.
7. `ui.layout.safe-area-keyboard-rtl` — real UIKit guides and directional insets.
8. `ui.layout.profile-compare` — local counters, with no fabricated cross-engine timing.
9. `ui.layout.duo-adaptation` — container bounds and safe-area behavior for iPhone Duo-like sizes.
10. `ui.layout.lifecycle-reuse` — ownership, weak references and inspector behavior.

Each page is reachable through `PTFuncNameViewController` and the existing demo coordinator. When the standalone SwiftPM module is linked, the page runs PTLayout scenarios. When the Example is using only the legacy CocoaPods aggregate, the page remains visible and reports that the compatibility fallback is active rather than showing a blank route.

Chinese: 错误场景必须显示结构化结果，不能只依赖控制台。

Español: Los escenarios de error deben mostrar resultados estructurados y no depender solo de la consola.
