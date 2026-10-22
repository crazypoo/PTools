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

Set `PTOOLS_NAVIGATION_GEOMETRY_DEBUG=1` in a Debug scheme to log host-window frames and vertical centers. The diagnostic is disabled by default and does not log application content.

The UIKit manager is an iOS/iPadOS boundary. watchOS has no matching UIKit navigation-bar host; visionOS and macOS use their native host containers. The value-only resolver is the portable CoreGraphics boundary.

## Español

En 5.69.0, `PTNavigationBarManager` resuelve una fila de contenido local usando la `UINavigationBar` real del host. Los botones izquierdos, el título y los botones derechos comparten un único `contentRect`; el layout ya no depende de `kNavBarHeight` global ni de adivinar el Sheet actual.

Las llamadas públicas existentes siguen siendo compatibles. `kNavBarHeight` permanece como estimación heredada, mientras `kNavBarHeight_Total` prioriza el borde inferior medido de la barra en la escena activa y vuelve a la fórmula heredada cuando no encuentra una pila coincidente. Usa `currentNavigationContentHeight(in:)` para obtener la altura viva del contenido integrado. `currentNavBarHeight()` conserva su semántica histórica de altura total.

Para contenido en varias escenas o con un host conocido, no uses la propiedad global como única fuente dinámica. Usa `currentNavigationTopInset(in:navigationController:)` con la vista destino. Si la página ya usa `safeAreaLayoutGuide`, no sumes el inset otra vez.

Para diagnosticar un dispositivo real, añade `PTOOLS_NAVIGATION_GEOMETRY_DEBUG=1` al esquema Debug. El diagnóstico está desactivado por defecto y no registra contenido de la aplicación.

El gestor UIKit es un límite de iOS/iPadOS. watchOS no tiene un host equivalente de barra de navegación UIKit; visionOS y macOS usan sus contenedores nativos. El resolver de valores basado en CoreGraphics es el límite portable.
