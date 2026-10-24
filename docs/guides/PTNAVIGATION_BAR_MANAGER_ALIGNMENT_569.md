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

旧的 `currentNavBarHeight()` 保持原有总高度语义，避免破坏旧项目。

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

Set `PTOOLS_NAVIGATION_GEOMETRY_DEBUG=1` in a Debug scheme to log host-window frames and vertical centers. The diagnostic is disabled by default and does not log application content.

The UIKit manager is an iOS/iPadOS boundary. watchOS has no matching UIKit navigation-bar host; visionOS and macOS use their native host containers. The value-only resolver is the portable CoreGraphics boundary.

## Español

En 5.69.0, `PTNavigationBarManager` resuelve una fila de contenido local usando la `UINavigationBar` real del host. Los botones izquierdos, el título y los botones derechos comparten un único `contentRect`; el layout ya no depende de `kNavBarHeight` global ni de adivinar el Sheet actual.

Las llamadas públicas existentes siguen siendo compatibles. `kNavBarHeight` permanece como estimación heredada, mientras `kNavBarHeight_Total` prioriza el borde inferior medido de la barra en la escena activa y vuelve a la fórmula heredada cuando no encuentra una pila coincidente. Usa `currentNavigationContentHeight(in:)` para obtener la altura viva del contenido integrado. `currentNavBarHeight()` conserva su semántica histórica de altura total.

Para contenido en varias escenas o con un host conocido, no uses la propiedad global como única fuente dinámica. Usa `currentNavigationTopInset(in:navigationController:)` con la vista destino. Si la página ya usa `safeAreaLayoutGuide`, no sumes el inset otra vez.

### Fila personalizada y propiedad del renderizador

`PTNavigationBarManager` distingue la geometría `observed` obtenida de información pública de UIKit y el `fallback` local calculado con bounds y área segura. El área segura nunca se presenta como una fila observada del sistema. Durante un layout de tamaño cero o de transición, el resolver aplaza la actualización y conserva la última fila válida.

El contenedor horizontal personalizado y la barra vertical del sistema en iOS 27.1+ cambian de propietario por pila de navegación. Primero se desliga el renderizador anterior y después el nuevo restaura sus elementos, evitando dos superficies interactivas o la pérdida del título. El fondo personalizado solo dibuja y no participa en los toques ni en VoiceOver.

Usa la entrada `navigation.duo-custom-nav-alignment-regression` del Example para probar More, los títulos/búsquedas, los botones laterales, la rotación y el área segura.

Para diagnosticar un dispositivo real, añade `PTOOLS_NAVIGATION_GEOMETRY_DEBUG=1` al esquema Debug. El diagnóstico está desactivado por defecto y no registra contenido de la aplicación.

El gestor UIKit es un límite de iOS/iPadOS. watchOS no tiene un host equivalente de barra de navegación UIKit; visionOS y macOS usan sus contenedores nativos. El resolver de valores basado en CoreGraphics es el límite portable.
