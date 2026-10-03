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
    private var content: PTTabBarItemContent
    private let appearance: PTTabBarAppearance
        
    public class func itemImageSize() -> CGFloat {
        let tab26ModeBottomSpacing = deviceInfo.isFaceIDCapable ? PTAppBaseConfig.share.tab26BottomSpacing : 0
        let safeAreaHeight:CGFloat = PTAppBaseConfig.share.tab26Mode ? tab26ModeBottomSpacing : 0
        let barHeight:CGFloat = PTAppBaseConfig.share.tab26Mode ? CGFloat.kTabbarHeight_Total : CGFloat.kTabbarHeight
        let imageSize = barHeight - safeAreaHeight - PTAppBaseConfig.share.tabTopSpacing - PTAppBaseConfig.share.tabContentSpacing - (PTAppBaseConfig.share.tabSelectedFont.pointSize + 2) - PTAppBaseConfig.share.tabBottomSpacing
        return imageSize
    }

    // English: New instances calculate their icon size from the captured appearance snapshot.
    // Español: Las nuevas instancias calculan el tamaño del icono desde la instantánea capturada.
    // 中文：新实例使用捕获的外观快照计算图标尺寸。
    func itemImageSize() -> CGFloat {
        let layout = appearance.layout
        let tab26ModeBottomSpacing = deviceInfo.isFaceIDCapable ? layout.tab26BottomSpacing : 0
        let safeAreaHeight = layout.tab26Mode ? tab26ModeBottomSpacing : 0
        let barHeight = layout.tab26Mode ? CGFloat.kTabbarHeight_Total : CGFloat.kTabbarHeight
        return barHeight - safeAreaHeight - layout.tabTopSpacing - layout.tabContentSpacing - (layout.tabSelectedFont.pointSize + 2) - layout.tabBottomSpacing
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
        super.init(frame: .zero)
        setupUI(title: title)
    }

    // English: Capture the appearance snapshot before building the item hierarchy.
    // Español: Captura la instantánea de apariencia antes de construir la jerarquía del elemento.
    // 中文：在构建 TabBar 项目层级前固定外观快照。
    public init(content: PTTabBarItemContent,
                title: String,
                appearance: PTTabBarAppearance) {
        self.appearance = appearance
        self.content = content
        super.init(frame: .zero)
        setupUI(title: title)
    }
    
    public required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI(title: String) {
        
        var subViews = [UIView]()
        if !title.stringIsEmpty() {
            subViews = [titleLabel,content.view]
        } else {
            subViews = [content.view]
        }
        
        if !title.stringIsEmpty() {
            titleLabel.numberOfLines = 1
            titleLabel.text = title
            PTUIAccessibility.applyDynamicType(to: titleLabel,
                                               font: appearance.normalFont)
            titleLabel.textAlignment = .center
            titleLabel.textColor = appearance.normalColor
        }
        
        addSubviews(subViews)

        accessibilityTraits = [.button]
        accessibilityLabel = title
                
        content.view.snp.makeConstraints {
            if !title.stringIsEmpty() {
                $0.top.centerX.equalToSuperview()
            } else {
                $0.center.equalToSuperview()
            }
            $0.size.equalTo(itemImageSize())
        }
        
        if !title.stringIsEmpty() {
            titleLabel.snp.makeConstraints {
                $0.top.equalTo(content.view.snp.bottom).offset(appearance.layout.tabContentSpacing)
                $0.left.right.bottom.equalToSuperview()
            }
        }
        
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
        let hasTitle = !(titleLabel.text?.stringIsEmpty() ?? true)
        content.view.snp.remakeConstraints {
            if hasTitle {
                $0.top.centerX.equalToSuperview()
            } else {
                $0.center.equalToSuperview()
            }
            $0.size.equalTo(itemImageSize())
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

