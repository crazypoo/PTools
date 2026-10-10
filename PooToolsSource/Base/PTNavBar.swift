//
//  PTNavBar.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2025/9/30.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

@MainActor
open class PTNavBar: PTNavigationBarContainer {
    
    fileprivate func navOffset() -> CGFloat {
        guard let current = PTUtils.getCurrentVC(), let sheet = current.sheetViewController else { return 0 }
        return sheet.options.useFullScreenMode ? 0 : max(0, sheet.options.pullBarHeight)
    }
    
    // ✅ 标记是否为普通的 View（不接管系统状态栏）
    public var isFakeNav: Bool = false {
        didSet {
            // 模式改变时，必须立刻重置外层容器的约束！
            updateTopBarContainerConstraints()
            
            // 触发内部按钮的重新布局
            if !leftContainer.arrangedSubviews.isEmpty {
                setLeftButtons(leftContainer.arrangedSubviews)
            }
            if !rightContainer.arrangedSubviews.isEmpty {
                setRightButtons(rightContainer.arrangedSubviews)
            }
        }
    }

    private struct WidthLayoutSignature: Equatable {
        let containerWidth: CGFloat
        let leftWidth: CGFloat
        let rightWidth: CGFloat
        let navigationSpacing: CGFloat
        let defaultSpace: CGFloat
    }

    private var lastWidthLayoutSignature: WidthLayoutSignature?
    
    fileprivate var titleViewMAxWidth: CGFloat = 0 {
        didSet {
            switch titleViewMode {
            case .auto:
                if let view = titleView {
                    let targetWidth = max(view.intrinsicContentSize.width, view.bounds.width)
                    view.snp.remakeConstraints { make in
                        make.centerX.centerY.equalToSuperview()
                        make.height.equalToSuperview()
                        make.width.equalTo(min(targetWidth, titleViewMAxWidth))
                    }
                }
            case .fixed(let width):
                if let view = titleView {
                    view.snp.remakeConstraints { make in
                        make.center.equalToSuperview()
                        make.width.equalTo(min(width, titleViewMAxWidth))
                        make.height.equalToSuperview()
                    }
                }
            default:
                break
            }
        }
    }
    
    public enum PTTitleViewMode: Sendable {
        case auto
        case fixed(CGFloat)
        case fill
    }

    public var titleViewMode: PTTitleViewMode = .fill {
        didSet {
            if let view = titleView { applyTitleViewConstraints(view) }
        }
    }

    public var titleView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
                        
            guard let newView = titleView else {
                // English: Hide the title container when no title view is installed.
                // Español: Oculta el contenedor cuando no hay una vista de título instalada.
                // 中文：没有标题视图时隐藏标题容器。
                titleContainer.isHidden = true
                return
            }
            
            // English: Keep the title container visible for the new title view.
            // Español: Mantiene visible el contenedor para la nueva vista de título.
            // 中文：为新的标题视图保持标题容器可见。
            titleContainer.isHidden = false

            titleContainer.addSubview(newView)
            // English: Keep titleContainer constraints under calculateMaxWidth so the title stays centered in the full bar.
            // Español: Mantiene las restricciones de titleContainer en calculateMaxWidth para centrar el título en toda la barra.
            // 中文：将 titleContainer 的约束统一交给 calculateMaxWidth，保证标题相对整条导航栏居中。
            applyTitleViewConstraints(newView)
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        calculateMaxWidth()
    }
    
    private func setupUI() {
        [leftContainer, rightContainer].forEach {
            $0.spacing = PTAppBaseConfig.share.navBarButtonSpacing
        }
        
        // 初始化外层
        updateTopBarContainerConstraints()
        
        // 初始化内层
        updateContainerConstraints(leftContainer, isLeft: true)
        updateContainerConstraints(rightContainer, isLeft: false)
        
        titleContainer.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(leftContainer.snp.right).offset(PTAppBaseConfig.share.navContainerSpacing)
            make.right.lessThanOrEqualTo(rightContainer.snp.left).offset(-PTAppBaseConfig.share.navContainerSpacing)
            make.height.equalTo(34)
        }
    }
    
    // 🔥 核心逻辑 1：接管并重构父类 topBarContainer 的约束
    private func updateTopBarContainerConstraints() {
        // topBarContainer 是父类 PTNavigationBarContainer 里的属性
        topBarContainer.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            
            if isFakeNav {
                // 如果是假导航栏，完全贴紧边界，不需要 statusBar 偏移
                make.top.equalToSuperview()
                make.height.equalToSuperview() // 或者 equalTo(CGFloat.kNavBarHeight)
            } else {
                // English: Use the navigation host's local safe-area position and sheet pull distance.
                // Español: Usa la posición local del área segura del host y la distancia de la hoja.
                // 中文：使用导航宿主的局部安全区位置和 Sheet 拉手距离。
                let sheetOffset = navOffset()
                let hostTopInset = navigationHostTopInset
                make.top.equalToSuperview().offset(-sheetOffset)
                make.height.equalTo(hostTopInset + sheetOffset + CGFloat.kNavBarHeight)
            }
        }
    }

    // 🔥 核心逻辑 2：调整内部按钮组相对于 topBarContainer 的 Y 轴布局
    private func updateContainerConstraints(_ container: UIStackView, isLeft: Bool) {
        let widthTotal = stackTotalWidth(container)
        
        container.snp.remakeConstraints { make in
            if isLeft {
                make.left.equalToSuperview().offset(PTAppBaseConfig.share.defaultViewSpace)
            } else {
                make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            }
            
            if isFakeNav {
                // FakeNav 模式：绝对居中
                make.centerY.equalToSuperview()
                make.height.equalTo(CGFloat.kNavBarHeight)
            } else {
                // English: Keep button groups inside the local host geometry.
                // Español: Mantiene los grupos de botones dentro de la geometría local del host.
                // 中文：让按钮组始终落在当前宿主的局部几何区域内。
                make.top.equalToSuperview().inset(navigationHostTopInset + navOffset())
                make.bottom.equalToSuperview()
            }
            
            make.width.equalTo(widthTotal)
        }
    }

    private func applyTitleViewConstraints(_ view: UIView) {
        view.snp.remakeConstraints { make in
            switch titleViewMode {
            case .auto:
                let targetWidth = max(view.intrinsicContentSize.width, view.bounds.width)
                let width = min(targetWidth, titleViewMAxWidth)
                make.centerX.centerY.equalToSuperview()
                make.height.equalToSuperview()
                make.width.equalTo(width)
            case .fixed(let width):
                make.center.equalToSuperview()
                make.width.equalTo(min(width, titleViewMAxWidth))
                make.height.equalToSuperview()
            case .fill:
                make.edges.equalToSuperview()
            }
        }
    }

    // MARK: - Public API
    
    public func setLeftButtons(_ buttons: [UIView]) {
        leftContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard !buttons.isEmpty else {
            leftContainer.isHidden = true
            self.leftContainerWidth = 0
            updateContainerConstraints(leftContainer, isLeft: true)
            calculateMaxWidth()
            return
        }
        leftContainer.isHidden = false
        buttons.forEach { value in
            leftContainer.addArrangedSubview(value)
            if let switchV = value as? UISwitch {
                switchV.snp.makeConstraints { make in
                    make.size.equalTo(value.bounds.size.width > 0 ? value.bounds.size : CGSize(width: 51, height: 31))
                    make.centerY.equalToSuperview()
                }
            } else {
                value.snp.makeConstraints { make in
                    make.size.equalTo(value.bounds.size)
                    make.centerY.equalToSuperview()
                }
            }
        }
        self.leftContainerWidth = stackTotalWidth(leftContainer)
        updateContainerConstraints(leftContainer, isLeft: true)
        calculateMaxWidth()
    }
    
    public func setRightButtons(_ buttons: [UIView]) {
        rightContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard !buttons.isEmpty else {
            rightContainer.isHidden = true
            self.rightContainerWidth = 0
            updateContainerConstraints(rightContainer, isLeft: false)
            calculateMaxWidth()
            return
        }
        
        rightContainer.isHidden = false

        buttons.forEach { value in
            rightContainer.addArrangedSubview(value)
            if let switchV = value as? UISwitch {
                switchV.snp.makeConstraints { make in
                    make.size.equalTo(value.bounds.size.width > 0 ? value.bounds.size : CGSize(width: 51, height: 31))
                    make.centerY.equalToSuperview()
                }
            } else {
                value.snp.makeConstraints { make in
                    make.size.equalTo(value.bounds.size)
                    make.centerY.equalToSuperview()
                }
            }
        }
        self.rightContainerWidth = stackTotalWidth(rightContainer)
        updateContainerConstraints(rightContainer, isLeft: false)
        calculateMaxWidth()
    }
    
    private func stackTotalWidth(_ stack: UIStackView) -> CGFloat {
        var total: CGFloat = 0
        stack.arrangedSubviews.forEach {
            if $0 is UISwitch {
                total += $0.bounds.width > 0 ? $0.bounds.width : 51
            } else {
                total += $0.bounds.width > 0 ? $0.bounds.width : 34
            }
        }
        return total + CGFloat(max(0, stack.arrangedSubviews.count - 1)) * PTAppBaseConfig.share.navBarButtonSpacing
    }
    
    private func calculateMaxWidth() {
        let rightWidthTotal: CGFloat = stackTotalWidth(rightContainer)
        let leftWidthTotal: CGFloat = stackTotalWidth(leftContainer)

        let containerWidth = bounds.width > 0
            ? bounds.width
            : (superview?.bounds.width ?? window?.bounds.width ?? 0)
        let navigationSpacing = PTAppBaseConfig.share.navContainerSpacing
        let defaultSpace = PTAppBaseConfig.share.defaultViewSpace
        // English: Use the wider button group on both sides so a centered title never conflicts with an edge button.
        // Español: Usa el grupo de botones más ancho en ambos lados para que el título centrado nunca choque con un botón.
        // 中文：两侧都按较宽的按钮组计算，保证居中标题不会与边缘按钮产生约束冲突。
        let widestButtonGroup = max(leftWidthTotal, rightWidthTotal)
        let availableWidth = max(0, containerWidth - defaultSpace * 2 - navigationSpacing * 2 - widestButtonGroup * 2)
        let signature = WidthLayoutSignature(containerWidth: containerWidth,
                                              leftWidth: leftWidthTotal,
                                              rightWidth: rightWidthTotal,
                                              navigationSpacing: navigationSpacing,
                                              defaultSpace: defaultSpace)
        guard lastWidthLayoutSignature != signature else { return }
        lastWidthLayoutSignature = signature

        titleContainer.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(leftContainer.snp.right).offset(navigationSpacing)
            make.right.lessThanOrEqualTo(rightContainer.snp.left).offset(-navigationSpacing)
            // English: Give the title container an explicit width so Auto Layout cannot reuse an old ambiguous frame.
            // Español: Define un ancho explícito para que Auto Layout no reutilice un frame antiguo y ambiguo.
            // 中文：为标题容器设置明确宽度，避免 Auto Layout 复用旧的模糊 frame。
            make.width.equalTo(availableWidth)
            make.height.equalTo(34)
        }

        let newWidth = availableWidth
        if newWidth != titleViewMAxWidth {
            titleViewMAxWidth = newWidth
        }
    }
}
