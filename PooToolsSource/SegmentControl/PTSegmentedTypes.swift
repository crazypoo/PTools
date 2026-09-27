// English: Native segmented and paging contracts for iOS 17+ and Swift 6.
// Español: Contratos nativos de segmentación y paginación para iOS 17+ y Swift 6.
// 中文：面向 iOS 17+ 与 Swift 6 的原生分段和分页契约。

import UIKit

#if canImport(ptools)
import ptools
#endif

/// English: The location of an image relative to a segment title.
/// Español: La posición de una imagen respecto al título del segmento.
/// 中文：图片相对于分段标题的位置。
@MainActor
public enum PTImagePlacement {
    case leading
    case trailing
    case top
    case bottom
}

/// English: A small badge rendered by the default segment cell.
/// Español: Una insignia pequeña renderizada por la celda de segmento predeterminada.
/// 中文：默认分段 Cell 使用的小徽标。
@MainActor
public struct PTSegmentBadge {
    public var text: String?
    public var backgroundColor: UIColor
    public var textColor: UIColor
    public var font: UIFont
    public var showsDotWhenEmpty: Bool

    public init(text: String? = nil,
                backgroundColor: UIColor = .systemRed,
                textColor: UIColor = .white,
                font: UIFont = .systemFont(ofSize: 11, weight: .semibold),
                showsDotWhenEmpty: Bool = true) {
        self.text = text
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.font = font
        self.showsDotWhenEmpty = showsDotWhenEmpty
    }
}

/// English: A custom segment view factory. The factory is main-actor isolated because it creates UIKit views.
/// Español: Una fábrica de vistas personalizada aislada en MainActor porque crea vistas UIKit.
/// 中文：自定义分段 View 工厂；由于创建 UIKit View，因此隔离在 MainActor。
@MainActor
public struct PTSegmentCustomContent {
    public let makeView: @MainActor () -> UIView

    public init(makeView: @escaping @MainActor () -> UIView) {
        self.makeView = makeView
    }
}

/// English: Content supported by the native segment renderer.
/// Español: Contenido compatible con el renderizador nativo de segmentos.
/// 中文：原生分段渲染器支持的内容类型。
@MainActor
public enum PTSegmentContent {
    case title(String)
    case attributed(NSAttributedString)
    case image(UIImage)
    case titleImage(title: String, image: UIImage, placement: PTImagePlacement = .leading)
    case imageSource(PTImageSource, placeholder: UIImage? = nil)
    case titleImageSource(title: String, source: PTImageSource, placement: PTImagePlacement = .leading, placeholder: UIImage? = nil)
    case custom(PTSegmentCustomContent)
}

/// English: A stable, value-driven segment item. Hashing intentionally uses only the stable identifier.
/// Español: Un elemento de segmento estable y basado en valores; el hash usa intencionadamente solo el identificador.
/// 中文：稳定的值驱动分段项；哈希值有意只使用稳定 ID。
@MainActor
public struct PTSegmentItem: @MainActor Identifiable, @MainActor Hashable {
    public let id: AnyHashable
    public var content: PTSegmentContent
    public var badge: PTSegmentBadge?
    public var accessibilityLabel: String?

    public init(id: AnyHashable,
                content: PTSegmentContent,
                badge: PTSegmentBadge? = nil,
                accessibilityLabel: String? = nil) {
        self.id = id
        self.content = content
        self.badge = badge
        self.accessibilityLabel = accessibilityLabel
    }

    public static func == (lhs: PTSegmentItem, rhs: PTSegmentItem) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func title(id: AnyHashable, _ title: String, badge: PTSegmentBadge? = nil) -> Self {
        Self(id: id, content: .title(title), badge: badge)
    }

    public static func image(id: AnyHashable, _ image: UIImage, badge: PTSegmentBadge? = nil) -> Self {
        Self(id: id, content: .image(image), badge: badge)
    }

    public static func titleImage(id: AnyHashable,
                                  title: String,
                                  image: UIImage,
                                  placement: PTImagePlacement = .leading,
                                  badge: PTSegmentBadge? = nil) -> Self {
        Self(id: id, content: .titleImage(title: title, image: image, placement: placement), badge: badge)
    }
}

/// English: Segment distribution controls whether items use intrinsic or equal widths.
/// Español: La distribución controla si los elementos usan anchuras intrínsecas o iguales.
/// 中文：分段分布策略控制使用内容宽度还是等宽布局。
@MainActor
public enum PTSegmentDistribution {
    case intrinsic
    case equal
    case adaptive
}

/// English: Width policy for a segment indicator.
/// Español: Política de anchura para un indicador de segmento.
/// 中文：分段指示器的宽度策略。
@MainActor
public enum PTIndicatorWidthPolicy {
    case fixed(CGFloat)
    case content
    case item
}

/// English: Indicator placement inside the segmented view.
/// Español: Posición del indicador dentro de la vista segmentada.
/// 中文：指示器在分段 View 内的摆放位置。
@MainActor
public enum PTSegmentIndicatorPlacement {
    case top
    case center
    case bottom
    case custom(@MainActor (CGRect, CGRect) -> CGRect)
}

/// English: Appearance configuration for the default renderer.
/// Español: Configuración visual del renderizador predeterminado.
/// 中文：默认渲染器的外观配置。
@MainActor
public struct PTSegmentStyle {
    public var normalFont: UIFont
    public var selectedFont: UIFont
    public var normalColor: UIColor
    public var selectedColor: UIColor
    public var normalBackgroundColor: UIColor
    public var selectedBackgroundColor: UIColor
    public var itemInsets: UIEdgeInsets
    public var itemSpacing: CGFloat
    public var itemHeight: CGFloat
    public var itemWidths: [CGFloat]?
    public var distribution: PTSegmentDistribution
    public var imageSpacing: CGFloat
    public var selectedScale: CGFloat

    public init(normalFont: UIFont = .systemFont(ofSize: 15),
                selectedFont: UIFont = .systemFont(ofSize: 15, weight: .semibold),
                normalColor: UIColor = .secondaryLabel,
                selectedColor: UIColor = .label,
                normalBackgroundColor: UIColor = .clear,
                selectedBackgroundColor: UIColor = .clear,
                itemInsets: UIEdgeInsets = .init(top: 0, left: 14, bottom: 0, right: 14),
                itemSpacing: CGFloat = 0,
                itemHeight: CGFloat = 44,
                itemWidths: [CGFloat]? = nil,
                distribution: PTSegmentDistribution = .adaptive,
                imageSpacing: CGFloat = 6,
                selectedScale: CGFloat = 1) {
        self.normalFont = normalFont
        self.selectedFont = selectedFont
        self.normalColor = normalColor
        self.selectedColor = selectedColor
        self.normalBackgroundColor = normalBackgroundColor
        self.selectedBackgroundColor = selectedBackgroundColor
        self.itemInsets = itemInsets
        self.itemSpacing = itemSpacing
        self.itemHeight = itemHeight
        self.itemWidths = itemWidths
        self.distribution = distribution
        self.imageSpacing = imageSpacing
        self.selectedScale = selectedScale
    }
}

/// English: The source of a segment selection change.
/// Español: El origen de un cambio de selección de segmento.
/// 中文：分段选择变化的来源。
@MainActor
public enum PTSegmentSelectionOrigin {
    case tap
    case swipe
    case programmatic
    case restoration
}

/// English: Current selection state and a stable identifier for synchronization.
/// Español: Estado de selección actual e identificador estable para la sincronización.
/// 中文：当前选择状态以及用于同步的稳定 ID。
@MainActor
public struct PTSegmentSelectionState {
    public fileprivate(set) var selectedID: AnyHashable?
    public fileprivate(set) var selectedIndex: Int?

    public init(selectedID: AnyHashable? = nil, selectedIndex: Int? = nil) {
        self.selectedID = selectedID
        self.selectedIndex = selectedIndex
    }
}

/// English: A single selection event shared by taps, swipes and restoration.
/// Español: Un único evento de selección compartido por toques, deslizamientos y restauración.
/// 中文：点击、滑动和恢复状态共用的选择事件。
@MainActor
public struct PTSegmentSelectionEvent {
    public let oldSelection: PTSegmentSelectionState
    public let newSelection: PTSegmentSelectionState
    public let origin: PTSegmentSelectionOrigin
}

/// English: Horizontal page direction used by indicator interpolation.
/// Español: Dirección horizontal usada por la interpolación del indicador.
/// 中文：指示器插值使用的水平页面方向。
@MainActor
public enum PTPageDirection {
    case forward
    case backward
    case none
}

/// English: Shared transition progress from one stable segment ID to another.
/// Español: Progreso de transición compartido entre dos identificadores estables.
/// 中文：两个稳定分段 ID 之间共用的过渡进度。
@MainActor
public struct PTSegmentTransition {
    public let fromID: AnyHashable
    public let toID: AnyHashable
    public let progress: CGFloat
    public let direction: PTPageDirection

    public init(fromID: AnyHashable,
                toID: AnyHashable,
                progress: CGFloat,
                direction: PTPageDirection) {
        self.fromID = fromID
        self.toID = toID
        self.progress = min(max(progress, 0), 1)
        self.direction = direction
    }
}

/// English: Context passed to every indicator before layout or transition updates.
/// Español: Contexto entregado a cada indicador antes de actualizar el diseño o la transición.
/// 中文：在布局或过渡更新前传递给每个指示器的上下文。
@MainActor
public struct PTSegmentIndicatorContext {
    public let bounds: CGRect
    public let itemFrames: [AnyHashable: CGRect]
    public let selectedID: AnyHashable?
    public let placement: PTSegmentIndicatorPlacement
    public let widthPolicy: PTIndicatorWidthPolicy

    public init(bounds: CGRect,
                itemFrames: [AnyHashable: CGRect],
                selectedID: AnyHashable?,
                placement: PTSegmentIndicatorPlacement = .bottom,
                widthPolicy: PTIndicatorWidthPolicy = .content) {
        self.bounds = bounds
        self.itemFrames = itemFrames
        self.selectedID = selectedID
        self.placement = placement
        self.widthPolicy = widthPolicy
    }
}

/// English: Pluggable indicator contract. Implementations own their view and never own selection state.
/// Español: Contrato de indicador extensible; cada implementación posee su vista, pero no el estado de selección.
/// 中文：可插拔指示器契约；实现只拥有自己的 View，不拥有选择状态。
@MainActor
public protocol PTSegmentIndicator: AnyObject {
    var view: UIView { get }
    func prepare(context: PTSegmentIndicatorContext)
    func update(transition: PTSegmentTransition)
    func select(item: PTSegmentSelectionState)
}

/// English: A page factory that can return any main-actor page implementation.
/// Español: Fábrica de páginas que puede devolver cualquier implementación aislada en MainActor.
/// 中文：可以返回任意 MainActor 页面实现的页面工厂。
@MainActor
public struct PTPageDescriptor {
    public let id: AnyHashable
    public let makePage: @MainActor () -> any PTPage

    public init(id: AnyHashable, makePage: @escaping @MainActor () -> any PTPage) {
        self.id = id
        self.makePage = makePage
    }

    public init(id: AnyHashable, viewController: @escaping @MainActor () -> UIViewController) {
        self.id = id
        self.makePage = { PTViewControllerPage(viewController: viewController()) }
    }

    public init(id: AnyHashable, view: @escaping @MainActor () -> UIView) {
        self.id = id
        self.makePage = { PTViewPage(view: view()) }
    }
}

/// English: Cache policy for lazy pages.
/// Español: Política de caché para páginas perezosas.
/// 中文：懒加载页面的缓存策略。
@MainActor
public enum PTPageCachePolicy {
    case keepAllLoaded
    case adjacent(radius: Int)
    case limit(Int)
    case discardOffscreen
}

/// English: Lifecycle events emitted by PTPageContainer.
/// Español: Eventos de ciclo de vida emitidos por PTPageContainer.
/// 中文：PTPageContainer 发出的生命周期事件。
@MainActor
public enum PTPageLifecycle {
    case willLoad
    case didLoad
    case willAppear
    case didAppear
    case willDisappear
    case didDisappear
    case didUnload
}

/// English: A page abstraction shared by views and view controllers.
/// Español: Abstracción de página compartida por vistas y controladores.
/// 中文：View 和 ViewController 共用的页面抽象。
@MainActor
public protocol PTPage: AnyObject {
    var pageView: UIView { get }
}

/// English: Optional scrolling capability discovered by the nested coordinator.
/// Español: Capacidad opcional de desplazamiento detectada por el coordinador anidado.
/// 中文：嵌套滚动协调器发现的可选滚动能力。
@MainActor
public protocol PTScrollablePage: PTPage {
    var pageScrollView: UIScrollView { get }
}

/// English: Optional lifecycle callback for custom pages.
/// Español: Callback opcional de ciclo de vida para páginas personalizadas.
/// 中文：自定义页面可选的生命周期回调。
@MainActor
public protocol PTPageLifecycleObserving: PTPage {
    func pageContainer(_ container: PTPageContainer, didChange lifecycle: PTPageLifecycle)
}

/// English: A safe UIView-backed page adapter.
/// Español: Adaptador seguro de página respaldado por UIView.
/// 中文：基于 UIView 的安全页面适配器。
@MainActor
public final class PTViewPage: PTPage {
    public let pageView: UIView

    public init(view: UIView) {
        self.pageView = view
    }
}

/// English: A UIViewController-backed page adapter that preserves containment.
/// Español: Adaptador respaldado por UIViewController que conserva el containment.
/// 中文：基于 UIViewController 的页面适配器，并正确维护控制器容器关系。
@MainActor
public final class PTViewControllerPage: PTPage, PTScrollablePage {
    public let viewController: UIViewController
    public var pageView: UIView { viewController.view }
    public var pageScrollView: UIScrollView {
        if let scrollView = viewController.view as? UIScrollView { return scrollView }
        return viewController.view.subviews.compactMap { $0 as? UIScrollView }.first ?? PTPageFallbackScrollView()
    }

    public init(viewController: UIViewController) {
        self.viewController = viewController
    }
}

@MainActor
private final class PTPageFallbackScrollView: UIScrollView {}

/// English: Ownership policy for navigation state when pages are embedded in a host.
/// Español: Política de propiedad del estado de navegación cuando las páginas están incrustadas en un host.
/// 中文：页面嵌入 Host 时的导航状态所有权策略。
@MainActor
public enum PTNavigationOwnership {
    case host
    case inherited
    case isolated
}

/// English: Embedding context used by paging hosts and child controllers.
/// Español: Contexto de integración usado por hosts de paginación y controladores hijos.
/// 中文：分页 Host 与子控制器使用的嵌入上下文。
@MainActor
public enum PTViewControllerEmbeddingContext {
    case host
    case embedded(ownership: PTNavigationOwnership = .inherited)
}

/// English: The child navigation preference accepted by a paging host.
/// Español: Preferencia de navegación del hijo aceptada por el host de paginación.
/// 中文：分页 Host 可接受的子页面导航偏好。
@MainActor
public struct PTNavigationBarPreference {
    public var isHidden: Bool?
    public var tintColor: UIColor?
    public var backgroundColor: UIColor?

    public init(isHidden: Bool? = nil,
                tintColor: UIColor? = nil,
                backgroundColor: UIColor? = nil) {
        self.isHidden = isHidden
        self.tintColor = tintColor
        self.backgroundColor = backgroundColor
    }
}

/// English: Host policy for accepting a selected child navigation preference.
/// Español: Política del host para aceptar la preferencia de navegación del hijo seleccionado.
/// 中文：Host 接受当前子页面导航偏好的策略。
@MainActor
public enum PTChildNavigationPolicy {
    case hostOnly
    case selectedChildPreference
    case isolatedChild
}
