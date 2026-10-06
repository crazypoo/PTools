//
//  PTTabBarItemView.swift
//  PooTools
//
//  English: Isolate one tab item from the tab-bar container.
//  Español: Aísla un elemento de pestaña del contenedor de la barra.
//  中文：将单个标签栏项目从标签栏容器中独立出来。
//

import UIKit
import Lottie
import SnapKit
#if canImport(PToolsCore)
import PToolsCore
#endif

@MainActor
final public class PTTabBarItemView: UIControl {
    
    private let titleLabel = UILabel()
    private let contentContainerView = UIView()
    private let contentStackView = UIStackView()
    private var content: PTTabBarItemContent
    private let appearance: PTTabBarAppearance
    private let contentInsetsOverride: UIEdgeInsets?
    private let contentOffsetOverride: UIOffset?
    private var lastContentLayoutBounds: CGSize = .zero
    private var lastResolvedContentInsets: UIEdgeInsets = .zero
    private var lastResolvedContentOffset: UIOffset = .zero
    private var lastResolvedContentSize: CGSize = .zero
        
    public class func itemImageSize() -> CGFloat {
        let appearance = PTTabBarAppearance.legacyDefault
        let tab26ModeBottomSpacing = deviceInfo.isFaceIDCapable ? appearance.layout.tab26BottomSpacing : 0
        let safeAreaHeight: CGFloat = appearance.layout.tab26Mode ? tab26ModeBottomSpacing : 0
        let barHeight: CGFloat = appearance.layout.tab26Mode ? CGFloat.kTabbarHeight_Total : CGFloat.kTabbarHeight
        return PTTabBarLayoutEngine.itemImageSize(barHeight: barHeight,
                                                  safeAreaHeight: safeAreaHeight,
                                                  titleHeight: appearance.selectedFont.pointSize + 2,
                                                  appearance: appearance.layout)
    }

    // English: New instances calculate their icon size from the captured appearance snapshot.
    // Español: Las nuevas instancias calculan el tamaño del icono desde la instantánea capturada.
    // 中文：新实例使用捕获的外观快照计算图标尺寸。
    func itemImageSize() -> CGFloat {
        let layout = appearance.layout
        let tab26ModeBottomSpacing = deviceInfo.isFaceIDCapable ? layout.tab26BottomSpacing : 0
        let safeAreaHeight = layout.tab26Mode ? tab26ModeBottomSpacing : 0
        let barHeight = layout.tab26Mode ? CGFloat.kTabbarHeight_Total : CGFloat.kTabbarHeight
        return PTTabBarLayoutEngine.itemImageSize(barHeight: barHeight,
                                                  safeAreaHeight: safeAreaHeight,
                                                  titleHeight: appearance.selectedFont.pointSize + 2,
                                                  appearance: layout)
    }

    // English: Expose the real title label to the TabBar without exposing its storage publicly.
    // Español: Expone la etiqueta real al TabBar sin hacer pública su propiedad interna.
    // 中文：向 TabBar 暴露真实标题 Label，但不公开内部存储。
    var titleLabelForLayout: UILabel? {
        titleLabel.superview == contentStackView ? titleLabel : nil
    }

    // English: Resolve only the media/custom-content size insets; the title remains independently sized.
    // Español: Resuelve solo los insets del contenido multimedia/personalizado; el título conserva su tamaño independiente.
    // 中文：只解析媒体/自定义内容的尺寸内边距，标题仍由自身字体独立决定尺寸。
    private var resolvedContentInsets: UIEdgeInsets {
        PTTabBarLayoutEngine.safeContentInsets(
            contentInsetsOverride ?? appearance.layout.tabItemContentInsets
        )
    }

    // English: Resolve the complete content-group translation separately from its size.
    // Español: Resuelve por separado la traslación del grupo completo y su tamaño.
    // 中文：将整体内容组偏移与内容尺寸分开解析。
    private var resolvedContentOffset: UIOffset {
        PTTabBarLayoutEngine.safeContentOffset(
            contentOffsetOverride ?? appearance.layout.tabItemContentOffset
        )
    }

    // English: Resolve the actual content size once for constraints, badges and minimized mode.
    // Español: Resuelve una sola vez el tamaño real para las restricciones, los badges y el modo minimizado.
    // 中文：统一计算真实内容尺寸，供约束、角标和最小化模式共同使用。
    var resolvedContentSize: CGSize {
        PTTabBarLayoutEngine.contentSize(baseSize: itemImageSize(),
                                         insets: resolvedContentInsets)
    }
    
    public var imageContent: UIView {
        get {
            return content.view
        }
    }
    
    public var isSelectedItem = false {
        didSet {
            content.setSelected(isSelectedItem, animated: true)
            titleLabel.textColor = isSelectedItem ? appearance.selectedColor : appearance.normalColor
            PTUIAccessibility.applyDynamicType(to: titleLabel,
                                               font: isSelectedItem ? appearance.selectedFont : appearance.normalFont)
            accessibilityTraits = isSelectedItem ? [.button, .selected] : [.button]
            accessibilityLabel = titleLabel.text
        }
    }
    
    public init(content: PTTabBarItemContent, title: String) {
        self.appearance = .legacyDefault
        self.content = content
        self.contentInsetsOverride = nil
        self.contentOffsetOverride = nil
        super.init(frame: .zero)
        setupUI(title: title)
    }

    // English: Capture the appearance snapshot before building the item hierarchy.
    // Español: Captura la instantánea de apariencia antes de construir la jerarquía del elemento.
    // 中文：在构建 TabBar 项目层级前固定外观快照。
    public init(content: PTTabBarItemContent,
                title: String,
                appearance: PTTabBarAppearance,
                contentInsets: UIEdgeInsets? = nil,
                contentOffset: UIOffset? = nil) {
        self.appearance = appearance
        self.content = content
        self.contentInsetsOverride = contentInsets
        self.contentOffsetOverride = contentOffset
        super.init(frame: .zero)
        setupUI(title: title)
    }
    
    public required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI(title: String) {
        contentContainerView.backgroundColor = .clear
        contentStackView.axis = .vertical
        contentStackView.alignment = .center
        contentStackView.distribution = .fill
        contentStackView.spacing = appearance.layout.tabContentSpacing
        contentContainerView.addSubview(contentStackView)
        addSubview(contentContainerView)

        if !title.stringIsEmpty() {
            titleLabel.numberOfLines = 1
            titleLabel.text = title
            PTUIAccessibility.applyDynamicType(to: titleLabel,
                                               font: appearance.normalFont)
            titleLabel.textAlignment = .center
            titleLabel.textColor = appearance.normalColor
            contentStackView.addArrangedSubview(titleLabel)
        }
        contentStackView.insertArrangedSubview(content.view, at: 0)

        accessibilityTraits = [.button]
        accessibilityLabel = title

        applyContentLayout(force: true)
        
        if appearance.layout.tabSelectedMetail {
            PTMainActorBridge.after(0.1) { [weak self] in
                self?.layoutMetailView()
            }
        }
    }
    
    private func layoutMetailView() {
        self.layoutSubviews()
    }
    
    // 🌟 新增方法：用于恢复 Icon 的初始布局
    public func restoreIconLayout() {
        if content.view.superview !== contentStackView {
            contentStackView.insertArrangedSubview(content.view, at: 0)
        }
        applyContentLayout(force: true)
    }

    // English: Detach only the content view when the selected tab enters minimized mode.
    // Español: Desvincula solo la vista de contenido cuando la pestaña seleccionada entra en modo minimizado.
    // 中文：选中 Tab 进入最小化模式时，只移出内容 View。
    func detachContentForMinimize() {
        contentStackView.removeArrangedSubview(content.view)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        applyContentLayout()
    }

    // English: Keep content padding and translation in one resolver used by setup and restoration.
    // Español: Mantiene el relleno y la traslación en un único resolvedor usado por setup y restauración.
    // 中文：让初始化和恢复布局共用同一个内容布局解析器。
    private func applyContentLayout(force: Bool = false) {
        let resolvedInsets = resolvedContentInsets
        let resolvedOffset = resolvedContentOffset
        let resolvedSize = resolvedContentSize
        guard force || lastContentLayoutBounds != bounds.size
                || lastResolvedContentInsets != resolvedInsets
                || lastResolvedContentOffset != resolvedOffset
                || lastResolvedContentSize != resolvedSize else { return }

        lastContentLayoutBounds = bounds.size
        lastResolvedContentInsets = resolvedInsets
        lastResolvedContentOffset = resolvedOffset
        lastResolvedContentSize = resolvedSize

        contentContainerView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        content.view.snp.remakeConstraints { make in
            make.size.equalTo(resolvedSize)
        }
        contentStackView.snp.remakeConstraints { make in
            make.centerX.equalToSuperview().offset(resolvedOffset.horizontal)
            make.centerY.equalToSuperview().offset(resolvedOffset.vertical)
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        // 如果点击到的子视图是我们的 ImageView，我们强行把响应者改成自己 (ContentView)
        
        if let findView = view as? PTTabBarItemView {
            if let badge = findView.imageContent.badge {
                return badge
            } else {
                return self
            }
        } else {
            if let findView = view {
                if let _ = findView as? LottieAnimationView {
                    return self
                }
                var findImageView:UIView?
                for subs in findView.subviews {
                    if let findSubs = subs as? UIImageView {
                        findImageView = findSubs
                        break
                    }
                }
                if let _ = findImageView {
                    return self
                } else {
                    return findView
                }
            } else {
                return view
            }
        }
    }
    
    // 这样你的 touchesBegan 就能正常工作了
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    }
}
