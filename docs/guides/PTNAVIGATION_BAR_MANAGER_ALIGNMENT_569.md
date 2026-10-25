# PTools 5.69.0 — PTNavigationBarManager 内容行对齐

## 中文

5.69.0 将 `PTNavigationBarManager` 的自定义容器改为使用真实 `UINavigationBar` 宿主的局部内容行。左侧按钮、标题和右侧按钮共享同一个 `contentRect`，不再用全局 `kNavBarHeight` 或当前页面猜测 Sheet 偏移。

现有公开调用方式不需要修改。`CGFloat.kNavBarHeight` 继续保留为兼容估算值；`kNavBarHeight_Total` 现在会优先读取活动场景的实时导航栏底部，无法解析场景或导航栈时自动回退旧公式。需要实时内容行高度时，可使用：

```swift
let height = PTNavigationBarManager.shared.currentNavigationContentHeight(in: navigationController)
```

如果页面有明确的目标 View 或多窗口场景，不要依赖全局属性作为唯一实时来源；应使用目标 View 所属导航栈的实时坐标转换：

```swift
let topInset = PTNavigationBarManager.shared.currentNavigationTopInset(
    in: view,
    navigationController: navigationController
)
```

如果页面已经使用 `safeAreaLayoutGuide`，不需要再叠加这个 inset，否则会产生二次偏移。

### 自定义内容行和渲染器切换

`PTNavigationBarManager` 现在区分两类几何证据：UIKit 公开布局信息得到的 `observed`，以及宿主 bounds/safe area 计算出的 `fallback`。安全区域本身不会再被伪装成系统实测内容行；UIKit 正在转场或返回零尺寸时会暂缓更新，保留上一份有效布局。

自定义横向容器和 iOS 27.1+ 的系统垂直导航栏按导航栈独立切换。切换过程中先撤销旧渲染器的交互和标题约束，再交给目标渲染器恢复导航项，避免两套导航栏同时可见或标题丢失。自定义背景层只负责视觉绘制，不参与点击和无障碍读取。

Example 目录中的 `navigation.duo-custom-nav-alignment-regression` 用于验证 More、搜索/标题视图、左右按钮、旋转和安全区变化。

### 展开恢复与状态栏避让

折叠/展开不再依赖旋转回调。每个 `UINavigationController` 都通过同一个幂等的 `reconcileNavigationBar(in:reason:)` 收敛当前可见控制器、渲染器所有权、导航项挂载和内容行几何。切换到系统垂直 Bar 时只隐藏并停用 PTools 自己的自定义容器；切回自定义 Bar 时只清理 PTools 创建的原生 wrapper，宿主自己设置的 `UIBarButtonItem` 会保留。

内容行会把当前 Window 的状态栏 frame 和 active reserved regions 转换到 `UINavigationBar` 局部坐标后再验证。背景可以延伸到状态栏，但左侧、标题、右侧和搜索输入必须共享同一条安全内容行；没有可用宿主尺寸时延后提交，不缓存零尺寸。

Demo 中的回归页展示 A1 合盖冷启动、A2 不旋转展开、A4 展开竖屏以及 A5/A6 重复尺寸变化的检查说明和 Scene-local frame 摘要。完整的 A1–A9 Duo 物理折叠验证仍需要真实可折叠设备，未连接设备时保持 `PENDING_DEVICE`。

旧的 `currentNavBarHeight()` 保持原有总高度语义，避免破坏旧项目。

### 紧凑行可用性、缓存和大标题顺序

内容行提交前会按宿主 bounds 和当前控件实测高度做可用性校验。1–2pt 的残留中间行、无法容纳按钮的行、与完整宽度状态栏排斥区重叠的行都会延后，不会写入 `lastAppliedContentRect` 或紧凑行缓存。Duo 侧边保留区只参与左右按钮避让，不会把纵向内容行切成几像素高。

Large Title 使用同一份不可变快照计算紧凑行和左右/标题布局。缓存只在宿主 bounds、安全区、排斥区和所需内容高度都匹配时复用；尺寸、分屏或导航栈上下文改变后自动失效。应用顺序保持为：绑定/挂载导航项 → 解析大标题状态 → 解析内容行 → 应用左右/标题约束，避免递归重建约束。

`PTOOLS_NAVIGATION_GEOMETRY_DEBUG=1` 额外输出 `requiredContentHeight`、`compactRowHeight`、缓存行、Large Title 高度、标题期望尺寸、压缩状态和状态栏/保留区交集，用来区分“高度不足”和“横向冲突”。

`PToolsNavigationTests` 覆盖 1pt 残留行、坏中间帧恢复、展开/收起/再展开、宿主尺寸失效、侧边保留区、非 44pt 合法行、完整状态栏遮挡，以及标题尺寸恢复、长标题压缩和非对称按钮旋转。

### DEBUG 几何诊断

如需在现场核对真实窗口坐标，可在 Debug Scheme 的环境变量中加入：

```text
PTOOLS_NAVIGATION_GEOMETRY_DEBUG=1
```

日志只输出导航栏、宿主、内容行以及左右/标题容器的 frame 和 `midY`，不输出业务图片、文本或用户数据。默认不开启。

### 平台边界

`PTNavigationBarManager` 和 `PTBaseNavControl` 使用 UIKit，仅适用于 iOS/iPadOS（以及宿主明确提供 UIKit 的 visionOS 场景）。watchOS 不提供对应导航栏宿主；visionOS、macOS 继续使用各自宿主的导航容器，不复用 iOS 的 frame 假设。纯值 `PTNavigationContentRowResolver` 只依赖 CoreGraphics，可作为跨平台几何测试边界。

## English

In 5.69.0, `PTNavigationBarManager` resolves a host-local content row from the actual `UINavigationBar`. The left items, title, and right items share one `contentRect`; the layout no longer relies on the global `kNavBarHeight` value or on guessing the current sheet controller.

Existing public call sites remain source-compatible. `kNavBarHeight` remains a legacy estimate, while `kNavBarHeight_Total` now prefers the active scene's measured navigation-bar bottom and falls back to the legacy formula when no matching stack is available. Use `currentNavigationContentHeight(in:)` when a live embedded navigation content height is required. `currentNavBarHeight()` keeps its historical total-height meaning.

For multi-window content or a view with a known host, do not use the global property as the only real-time source. Use `currentNavigationTopInset(in:navigationController:)` with the target view. If the page already uses `safeAreaLayoutGuide`, do not add the inset a second time.

### Custom content rows and renderer ownership

`PTNavigationBarManager` now distinguishes `observed` geometry obtained from public UIKit layout information from a host-local `fallback` derived from bounds and safe area. A safe-area rectangle is never presented as an observed system row. During a zero-size or transitional layout pass, the resolver defers the update and preserves the last valid row.

The custom horizontal container and the iOS 27.1+ system vertical navigation bar switch ownership per navigation stack. The old renderer is first unbound, then the target renderer restores its navigation items, preventing duplicate interaction surfaces or a lost title. The custom background remains visual-only and is hidden from hit testing and accessibility.

Use the Example entry `navigation.duo-custom-nav-alignment-regression` to exercise More, title/search views, side buttons, rotation and safe-area changes.

### Unfold recovery and status-bar exclusion

Fold/unfold recovery no longer depends on a rotation callback. Each `UINavigationController` converges the visible controller, renderer ownership, navigation-item attachment and content-row geometry through the idempotent `reconcileNavigationBar(in:reason:)` path. Switching to the system vertical bar hides and disables only the PTools-owned custom container; switching back removes only PTools-created native wrappers and preserves host-owned `UIBarButtonItem` values.

The content row validates the current window's status-bar frame and active reserved regions after converting them into the local `UINavigationBar` coordinate space. The background may extend under the status bar, but leading, title, trailing and search content share one safe row. Invalid or zero-size host geometry is deferred instead of cached.

The Demo page documents A1 cold launch while closed, A2 unfold without rotation, A4 expanded portrait and A5/A6 repeated resize checks, and shows a scene-local frame summary. Full A1–A9 physical fold validation still requires a real foldable Duo device and remains `PENDING_DEVICE` when unavailable.

Set `PTOOLS_NAVIGATION_GEOMETRY_DEBUG=1` in a Debug scheme to log host-window frames and vertical centers. The diagnostic is disabled by default and does not log application content.

### Compact-row validity, cache and Large Title ordering

Before a row is committed, PTools validates it against the host bounds and the measured height required by the current controls. 1–2-point transitional rows, rows that cannot contain the controls, and rows intersecting a full-width status exclusion are deferred instead of being written to `lastAppliedContentRect` or the compact-row cache. Duo side rails remain horizontal collision inputs; they do not split the vertical row into a few pixels.

Large Title uses one immutable geometry snapshot for the compact row and the left/title/right layout. A cached row is reused only when host bounds, safe area, exclusions and required content height still match; resize, split view or stack changes invalidate it. The ordering remains bind/mount navigation items → resolve Large Title state → resolve the content row → apply item constraints, avoiding recursive constraint rebuilds.

With `PTOOLS_NAVIGATION_GEOMETRY_DEBUG=1`, diagnostics also include `requiredContentHeight`, `compactRowHeight`, cached row, Large Title height, desired title size, compression state, and status/reserved intersections so height failures can be separated from horizontal collisions.

`PToolsNavigationTests` covers thin transitional rows, cache recovery and invalidation, expand/collapse/expand, side rails, full status occlusion, legitimate non-44-point rows, and title preferred-size recovery under long/asymmetric content.

The UIKit manager is an iOS/iPadOS boundary. watchOS has no matching UIKit navigation-bar host; visionOS and macOS use their native host containers. The value-only resolver is the portable CoreGraphics boundary.

## Español

En 5.69.0, `PTNavigationBarManager` resuelve una fila de contenido local usando la `UINavigationBar` real del host. Los botones izquierdos, el título y los botones derechos comparten un único `contentRect`; el layout ya no depende de `kNavBarHeight` global ni de adivinar el Sheet actual.

Las llamadas públicas existentes siguen siendo compatibles. `kNavBarHeight` permanece como estimación heredada, mientras `kNavBarHeight_Total` prioriza el borde inferior medido de la barra en la escena activa y vuelve a la fórmula heredada cuando no encuentra una pila coincidente. Usa `currentNavigationContentHeight(in:)` para obtener la altura viva del contenido integrado. `currentNavBarHeight()` conserva su semántica histórica de altura total.

Para contenido en varias escenas o con un host conocido, no uses la propiedad global como única fuente dinámica. Usa `currentNavigationTopInset(in:navigationController:)` con la vista destino. Si la página ya usa `safeAreaLayoutGuide`, no sumes el inset otra vez.

### Fila personalizada y propiedad del renderizador

`PTNavigationBarManager` distingue la geometría `observed` obtenida de información pública de UIKit y el `fallback` local calculado con bounds y área segura. El área segura nunca se presenta como una fila observada del sistema. Durante un layout de tamaño cero o de transición, el resolver aplaza la actualización y conserva la última fila válida.

El contenedor horizontal personalizado y la barra vertical del sistema en iOS 27.1+ cambian de propietario por pila de navegación. Primero se desliga el renderizador anterior y después el nuevo restaura sus elementos, evitando dos superficies interactivas o la pérdida del título. El fondo personalizado solo dibuja y no participa en los toques ni en VoiceOver.

Usa la entrada `navigation.duo-custom-nav-alignment-regression` del Example para probar More, los títulos/búsquedas, los botones laterales, la rotación y el área segura.

### Recuperación al desplegar y exclusión de la barra de estado

La recuperación al plegar/desplegar ya no depende de una callback de rotación. Cada `UINavigationController` reconcilia el controlador visible, la propiedad del renderizador, los elementos y la fila geométrica mediante `reconcileNavigationBar(in:reason:)`. Al usar la barra vertical del sistema solo se oculta y desactiva el contenedor personalizado de PTools; al volver al renderizador personalizado solo se eliminan los wrappers nativos creados por PTools y se conservan los `UIBarButtonItem` del host.

La fila de contenido valida el frame de la barra de estado y las regiones reservadas activas de la ventana después de convertirlas al sistema local de `UINavigationBar`. El fondo puede extenderse bajo la barra de estado, pero los controles izquierdo, título, derecho y búsqueda comparten una única fila segura. La geometría cero o inválida se aplaza y no se guarda.

La página Demo documenta las comprobaciones A1 de arranque en estado cerrado, A2 de despliegue sin rotación, A4 de retrato desplegado y A5/A6 de cambios repetidos, además de mostrar un resumen geométrico de la escena. La validación física A1–A9 sigue requiriendo un dispositivo Duo plegable real y permanece como `PENDING_DEVICE` si no está disponible.

Para diagnosticar un dispositivo real, añade `PTOOLS_NAVIGATION_GEOMETRY_DEBUG=1` al esquema Debug. El diagnóstico está desactivado por defecto y no registra contenido de la aplicación.

### Validez de la fila compacta, caché y orden del Large Title

Antes de guardar una fila, PTools la valida contra los bounds del host y la altura medida que necesitan los controles actuales. Las filas transitorias de 1–2 puntos, las que no pueden contener los controles y las que chocan con una exclusión de ancho completo se aplazan; no se escriben en `lastAppliedContentRect` ni en la caché compacta. Los raíles laterales del Duo solo participan en la colisión horizontal y no cortan la fila vertical.

Large Title usa una instantánea geométrica inmutable para la fila compacta y el layout izquierdo/título/derecho. La caché solo se reutiliza si coinciden bounds, área segura, exclusiones y altura requerida; un resize, split view o cambio de pila la invalida. El orden sigue siendo montar los elementos → resolver el estado Large Title → resolver la fila → aplicar restricciones, sin reconstrucciones recursivas.

Con `PTOOLS_NAVIGATION_GEOMETRY_DEBUG=1`, el diagnóstico incluye también `requiredContentHeight`, `compactRowHeight`, la fila guardada, la altura Large Title, el tamaño deseado del título, su compresión y las intersecciones de estado/reservas para separar fallos de altura de colisiones horizontales.

`PToolsNavigationTests` cubre filas finas de transición, recuperación e invalidación de caché, expandir/contraer/expandir, raíles laterales, oclusión completa de estado, filas válidas distintas de 44 puntos y recuperación del tamaño preferido del título.

El gestor UIKit es un límite de iOS/iPadOS. watchOS no tiene un host equivalente de barra de navegación UIKit; visionOS y macOS usan sus contenedores nativos. El resolver de valores basado en CoreGraphics es el límite portable.
