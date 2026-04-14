//
//  PTEmptyDataSetView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/4/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import Foundation
import UIKit
import SnapKit // 🌟 引入 SnapKit 替代繁琐的原生约束

@MainActor
public class PTEmptyDataSetView: UIView {
    
    // MARK: - UI Components
    
    internal lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        view.alpha = 0
        return view
    }()
    
    // 🌟 引入 StackView 作为核心布局容器，自动管理内部视图的显示、隐藏和间距
    internal lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 11 // 默认间距
        return stack
    }()
    
    internal lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        imageView.accessibilityIdentifier = "empty set background image"
        return imageView
    }()
    
    internal lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.font = UIFont.systemFont(ofSize: 27.0)
        label.textColor = UIColor(white: 0.6, alpha: 1.0)
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.accessibilityIdentifier = "empty set title"
        return label
    }()
    
    internal lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.font = UIFont.systemFont(ofSize: 17.0)
        label.textColor = UIColor(white: 0.6, alpha: 1.0)
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.accessibilityIdentifier = "empty set detail label"
        return label
    }()
    
    internal lazy var button: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        button.accessibilityIdentifier = "empty set button"
        return button
    }()
    
    // MARK: - Properties
    
    internal var customView: UIView? {
        willSet {
            customView?.removeFromSuperview()
        }
        didSet {
            if let customView = customView {
                self.addSubview(customView)
            }
        }
    }
    
    internal var fadeInOnDisplay = false
    internal var verticalOffset: CGFloat = 0
    internal var verticalSpace: CGFloat = 11 {
        didSet {
            stackView.spacing = verticalSpace
        }
    }
    
    // Callbacks
    internal var didTapContentViewHandle: (() -> Void)?
    internal var didTapDataButtonHandle: (() -> Void)?
    internal var willAppearHandle: (() -> Void)?
    internal var didAppearHandle: (() -> Void)?
    internal var willDisappearHandle: (() -> Void)?
    internal var didDisappearHandle: (() -> Void)?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupHierarchy() {
        addSubview(contentView)
        contentView.addSubview(stackView)
        
        // 按照从上到下的顺序添加到 StackView
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(detailLabel)
        stackView.addArrangedSubview(button)
    }
    
    // 🌟 修复原来在 didMoveToSuperview 里强制覆盖 frame 的错误做法，改用自动布局约束边缘
    override public func didMoveToSuperview() {
        guard let superview = superview else { return }
        
        self.snp.remakeConstraints { make in
            make.edges.equalTo(superview)
        }
        
        if fadeInOnDisplay {
            UIView.animate(withDuration: 0.25) {
                self.contentView.alpha = 1
            }
        } else {
            contentView.alpha = 1
        }
    }
    
    // MARK: - Lifecycle
    
    internal func prepareForReuse() {
        titleLabel.text = nil
        detailLabel.text = nil
        imageView.image = nil
        button.setImage(nil, for: .normal)
        button.setImage(nil, for: .highlighted)
        button.setAttributedTitle(nil, for: .normal)
        button.setAttributedTitle(nil, for: .highlighted)
        button.setBackgroundImage(nil, for: .normal)
        button.setBackgroundImage(nil, for: .highlighted)
        customView = nil
    }
    
    // MARK: - Layout (SnapKit + StackView 魔法)
    
    internal func setupConstraints() {
        // 1. 处理自定义 View 的情况
        if let customView = customView {
            contentView.isHidden = true
            
            customView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(verticalOffset)
                
                if customView.frame.height > 0 {
                    make.height.equalTo(customView.frame.height)
                } else {
                    make.height.lessThanOrEqualToSuperview()
                }
                
                if customView.frame.width > 0 {
                    make.width.equalTo(customView.frame.width)
                } else {
                    make.width.lessThanOrEqualToSuperview()
                }
            }
            return
        }
        
        // 2. 恢复默认的 ContentView
        contentView.isHidden = false
        contentView.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview().offset(verticalOffset)
        }
        
        let width = self.frame.width > 0 ? self.frame.width : UIScreen.main.bounds.width
        let padding = roundf(Float(width / 16.0))
        
        stackView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(CGFloat(padding))
        }
        
        // 3. 动态控制元素的显示和隐藏
        // UIStackView 会自动处理被隐藏视图的间距！这就是 StackView 的魅力！
        imageView.isHidden = imageView.image == nil
        titleLabel.isHidden = (titleLabel.attributedText?.length ?? 0) == 0
        detailLabel.isHidden = (detailLabel.attributedText?.length ?? 0) == 0
        
        let hasButtonTitle = (button.attributedTitle(for: .normal)?.length ?? 0) > 0
        let hasButtonImage = button.image(for: .normal) != nil
        button.isHidden = !(hasButtonTitle || hasButtonImage)
    }
}

@MainActor // 🌟 确保所有 UI 配置方法都在主线程执行
extension PTEmptyDataSetView {
    
    // MARK: - Data Source
    
    /// Asks the data source for the title of the dataset.
    @discardableResult
    public func titleLabelString(_ attributedString: NSAttributedString?) -> Self {
        titleLabel.attributedText = attributedString
        // 🌟 响应式优化：根据内容自动控制隐藏/显示，UIStackView 会自动适应！
        titleLabel.isHidden = (attributedString?.length ?? 0) == 0
        return self
    }
    
    /// Asks the data source for the description of the dataset.
    @discardableResult
    public func detailLabelString(_ attributedString: NSAttributedString?) -> Self {
        detailLabel.attributedText = attributedString
        detailLabel.isHidden = (attributedString?.length ?? 0) == 0
        return self
    }
    
    /// Asks the data source for the image of the dataset.
    @discardableResult
    public func image(_ image: UIImage?) -> Self {
        imageView.image = image
        imageView.isHidden = image == nil
        return self
    }
    
    /// Asks the data source for a tint color of the image dataset. Default is nil.
    @discardableResult
    public func imageTintColor(_ imageTintColor: UIColor?) -> Self {
        imageView.tintColor = imageTintColor
        return self
    }
    
    /// Asks the data source for the image animation of the dataset.
    @discardableResult
    public func imageAnimation(_ imageAnimation: CAAnimation?) -> Self {
        if let ani = imageAnimation {
            imageView.layer.add(ani, forKey: nil)
        }
        return self
    }
    
    /// Asks the data source for the title to be used for the specified button state.
    @discardableResult
    public func buttonTitle(_ buttonTitle: NSAttributedString?, for state: UIControl.State) -> Self {
        button.setAttributedTitle(buttonTitle, for: state)
        updateButtonVisibility()
        return self
    }
    
    /// Asks the data source for the image to be used for the specified button state.
    @discardableResult
    public func buttonImage(_ buttonImage: UIImage?, for state: UIControl.State) -> Self {
        button.setImage(buttonImage, for: state)
        updateButtonVisibility()
        return self
    }
    
    /// Asks the data source for a background image to be used for the specified button state.
    @discardableResult
    public func buttonBackgroundImage(_ buttonBackgroundImage: UIImage?, for state: UIControl.State) -> Self {
        button.setBackgroundImage(buttonBackgroundImage, for: state)
        return self
    }
    
    /// 统一更新按钮的显示状态
    private func updateButtonVisibility() {
        let hasTitle = (button.attributedTitle(for: .normal)?.length ?? 0) > 0
        let hasImage = button.image(for: .normal) != nil
        button.isHidden = !(hasTitle || hasImage)
    }
    
    /// Asks the data source for the background color of the dataset. Default is clear color.
    @discardableResult
    public func dataSetBackgroundColor(_ backgroundColor: UIColor?) -> Self {
        self.backgroundColor = backgroundColor
        return self
    }
    
    /// Asks the data source for a custom view to be displayed instead of the default views.
    @discardableResult
    public func customView(_ customView: UIView?) -> Self {
        self.customView = customView
        // 🌟 如果设置了自定义 View，自动隐藏默认的 StackView 容器
        self.contentView.isHidden = customView != nil
        return self
    }
    
    /// Asks the data source for a offset for vertical alignment of the content. Default is 0.
    @discardableResult
    public func verticalOffset(_ offset: CGFloat) -> Self {
        self.verticalOffset = offset
        // 如果想实时生效，可以在这里触发重新布局
        self.setNeedsUpdateConstraints()
        return self
    }
    
    /// Asks the data source for a vertical space between elements. Default is 11 pts.
    @discardableResult
    public func verticalSpace(_ space: CGFloat) -> Self {
        self.verticalSpace = space // 这个赋值会触发之前我们在 didSet 里写的 stackView.spacing 更新
        return self
    }
    
    // MARK: - Delegate & Events
    
    @discardableResult
    public func shouldFadeIn(_ bool: Bool) -> Self {
        fadeInOnDisplay = bool
        return self
    }
    
    @discardableResult
    public func shouldBeForcedToDisplay(_ bool: Bool) -> Self {
        isHidden = !bool
        return self
    }
    
    @discardableResult
    public func shouldDisplay(_ bool: Bool) -> Self {
        // 确保你的 UIScrollView extension 中有 itemsCount 属性
        if let superview = self.superview as? UIScrollView {
            isHidden = !(bool && superview.itemsCount == 0)
        }
        return self
    }
    
    @discardableResult
    public func isTouchAllowed(_ bool: Bool) -> Self {
        isUserInteractionEnabled = bool
        return self
    }
    
    @discardableResult
    public func isScrollAllowed(_ bool: Bool) -> Self {
        if let superview = superview as? UIScrollView {
            superview.isScrollEnabled = bool
        }
        return self
    }
    
    @discardableResult
    public func isImageViewAnimateAllowed(_ bool: Bool) -> Self {
        if !bool {
            imageView.layer.removeAllAnimations()
        }
        return self
    }
    
    // 🌟 语法优化：闭包统一使用 @MainActor () -> Void，保证调用安全，且去除了老旧的 (Void) 写法
    @discardableResult
    public func didTapContentView(_ closure: @escaping @MainActor () -> Void) -> Self {
        didTapContentViewHandle = closure
        return self
    }
    
    @discardableResult
    public func didTapDataButton(_ closure: @escaping @MainActor () -> Void) -> Self {
        didTapDataButtonHandle = closure
        return self
    }
    
    @discardableResult
    public func willAppear(_ closure: @escaping @MainActor () -> Void) -> Self {
        willAppearHandle = closure
        return self
    }
    
    @discardableResult
    public func didAppear(_ closure: @escaping @MainActor () -> Void) -> Self {
        didAppearHandle = closure
        return self
    }
    
    @discardableResult
    public func willDisappear(_ closure: @escaping @MainActor () -> Void) -> Self {
        willDisappearHandle = closure
        return self
    }
    
    @discardableResult
    public func didDisappear(_ closure: @escaping @MainActor () -> Void) -> Self {
        didDisappearHandle = closure
        return self
    }
}
