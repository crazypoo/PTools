//
//  PTSheetContentViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/5.
//  Copyright © 2024 crazypoo. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
import SnapKit

@MainActor
public class PTSheetContentViewController: PTBaseViewController {

    public private(set) var childViewController: UIViewController
    
    private let options: PTSheetOptions
    private(set) var size: CGFloat = 0
    private(set) var preferredHeight: CGFloat
    private var originalChildSafeAreaInsets: UIEdgeInsets = .zero
    private var pullBarSafeAreaTop: CGFloat = 0
    private var keyboardSafeAreaBottom: CGFloat = 0
    private var lastLayoutBounds: CGSize = .zero
    private var configuredContentBackgroundColor: UIColor?
    
    public var contentBackgroundColor: UIColor? {
        get { configuredContentBackgroundColor }
        set {
            configuredContentBackgroundColor = newValue
            childContainerView.backgroundColor = newValue ?? .ptPresentationSurface
        }
    }

    // iOS 13+ 引入的平滑圆角特性
    private var _cornerCurve: Any? = nil
    public var cornerCurve: CALayerCornerCurve {
        get { (_cornerCurve as? CALayerCornerCurve) ?? .circular }
        set {
            _cornerCurve = newValue
            self.updateCornerCurve()
        }
    }
    
    public var cornerRadius: CGFloat = 0 {
        didSet { self.updateCornerRadius() }
    }
    
    public var gripSize: CGSize = CGSize(width: 50, height: 6) {
        didSet {
            self.updateGripConstraints()
        }
    }
    
    public var gripColor: UIColor? {
        get { self.gripView.backgroundColor }
        set { self.gripView.backgroundColor = newValue }
    }
    
    public var pullBarBackgroundColor: UIColor? {
        get { self.pullBarView.backgroundColor }
        set { self.pullBarView.backgroundColor = newValue }
    }
    
    public var treatPullBarAsClear: Bool = PTSheetViewController.treatPullBarAsClear {
        didSet {
            if self.isViewLoaded {
                self.updateCornerRadius()
            }
        }
    }
    
    // [优化] 移除了多余的参数标签，使闭包类型声明更符合 Swift 规范
    var sheetContentViewPreferredHeightChanged: ((CGFloat, CGFloat) -> Void)?
    var pullBarTappedAction: PTActionTask?
    
    public var contentWrapperView = UIView()
    public var contentView = UIView()
    public var childContainerView = UIView()
    
    public lazy var pullBarView: UIView = {
        let view = UIView()
        return view
    }()
    
    public lazy var gripView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let overflowView = UIView()
    private var contentTopConstraint: NSLayoutConstraint?
    private var navigationHeightConstraint: NSLayoutConstraint?
    private var gripWidthConstraint: NSLayoutConstraint?
    private var gripHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    
    public init(childViewController: UIViewController, options: PTSheetOptions) {
        self.options = options.normalized()
        self.childViewController = childViewController
        self.preferredHeight = 0
        super.init(nibName: nil, bundle: nil)
        self.originalChildSafeAreaInsets = childViewController.additionalSafeAreaInsets
        
        if self.options.setIntrinsicHeightOnNavigationControllers, let navigationController = self.childViewController as? UINavigationController {
            navigationController.delegate = self
        }
    }
    
    public required init?(coder: NSCoder) {
        // FloatPanel 只支持代码创建；从 storyboard 解码时安全返回失败，避免初始化阶段崩溃。
        return nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self,
                                                   name: UIContentSizeCategory.didChangeNotification,
                                                   object: nil)
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        childContainerView.backgroundColor = configuredContentBackgroundColor ?? .ptPresentationSurface
        self.setupContentView()
        self.setupChildContainerView()
        self.setupPullBarView()
        self.setupChildViewController()
        
        self.updatePreferredHeight()
        self.updateCornerCurve()
        self.updateCornerRadius()
        self.setupOverflowView()

        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.performWithoutAnimation {
            self.view.layoutIfNeeded()
        }
        self.updatePreferredHeight()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updatePreferredHeight()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateAfterLayout()

        let boundsSize = self.view.bounds.size
        guard boundsSize.width > 0, boundsSize.height > 0, boundsSize != self.lastLayoutBounds else { return }
        self.lastLayoutBounds = boundsSize
        self.updatePreferredHeight()
    }
    
    // MARK: - Methods
    
    func updateAfterLayout() {
        self.size = self.childViewController.view.bounds.height
    }
    
    func adjustForKeyboard(height: CGFloat) {
        self.keyboardSafeAreaBottom = height.isFinite ? max(0, height) : 0
        self.applyChildSafeAreaInsets()
    }

    private func updateCornerCurve() {
        self.contentWrapperView.layer.cornerCurve = self.cornerCurve
        self.childContainerView.layer.cornerCurve = self.cornerCurve
    }

    private func updateCornerRadius() {
        self.contentWrapperView.layer.cornerRadius = self.treatPullBarAsClear ? 0 : self.cornerRadius
        self.childContainerView.layer.cornerRadius = self.treatPullBarAsClear ? self.cornerRadius : 0
    }
    
    private func setupOverflowView() {
        // [优化] 去掉 switch 条件的多余括号
        switch self.options.transitionOverflowType {
        case .view(let view):
            overflowView.backgroundColor = .clear
            overflowView.addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        case .automatic:
            overflowView.backgroundColor = self.childViewController.view.backgroundColor
        case .color(let color):
            overflowView.backgroundColor = color
        case .none:
            overflowView.backgroundColor = .clear
        }
    }
    
    private func updateNavigationControllerHeight() {
        guard self.options.setIntrinsicHeightOnNavigationControllers,
              let navigationController = self.childViewController as? UINavigationController,
              self.isViewLoaded,
              let visibleViewController = navigationController.visibleViewController,
              let visibleView = visibleViewController.viewIfLoaded else { return }

        let width = max(self.childContainerView.bounds.width, self.view.bounds.width)
        guard width > 0 else { return }

        self.navigationHeightConstraint?.isActive = false
        self.contentTopConstraint?.isActive = false

        var fittingSize = UIView.layoutFittingCompressedSize
        fittingSize.width = width
        let fittedHeight = visibleView.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        ).height
        let navigationBarHeight = navigationController.navigationBar.isHidden ? 0 : navigationController.navigationBar.bounds.height
        let toolbarHeight = navigationController.toolbar.isHidden ? 0 : navigationController.toolbar.bounds.height
        let preferredHeight = navigationController.preferredContentSize.height
        let measuredHeight = max(0, preferredHeight > 0 ? preferredHeight : fittedHeight + navigationBarHeight + toolbarHeight)

        if let navigationHeightConstraint {
            navigationHeightConstraint.constant = measuredHeight
        } else {
            let constraint = navigationController.view.heightAnchor.constraint(equalToConstant: measuredHeight)
            constraint.isActive = true
            self.navigationHeightConstraint = constraint
        }

        self.navigationHeightConstraint?.isActive = true
        self.contentTopConstraint?.isActive = true
    }
    
    func updatePreferredHeight() {
        guard self.isViewLoaded else { return }
        self.updateNavigationControllerHeight()
        let width = max(self.view.bounds.width, self.contentView.bounds.width)
        guard width > 0 else { return }
        let oldPreferredHeight = self.preferredHeight
        var fittingSize = UIView.layoutFittingCompressedSize
        fittingSize.width = width

        self.contentTopConstraint?.isActive = false
        UIView.performWithoutAnimation {
            self.view.layoutIfNeeded()
            let measuredHeight = self.contentView.systemLayoutSizeFitting(
                fittingSize,
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .defaultLow
            ).height
            self.preferredHeight = measuredHeight.isFinite ? max(0, measuredHeight) : 0
        }
        self.contentTopConstraint?.isActive = true
        self.view.layoutIfNeeded()

        let scale = max(self.view.window?.screen.scale ?? self.traitCollection.displayScale, 1)
        let tolerance = 1 / scale
        if abs(oldPreferredHeight - self.preferredHeight) >= tolerance {
            self.sheetContentViewPreferredHeightChanged?(oldPreferredHeight, self.preferredHeight)
        }
    }
    
    private func setupChildViewController() {
        self.addChild(self.childViewController)
        guard let childView = self.childViewController.view else { return }
        self.childContainerView.addSubview(childView)

        childView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childView.leadingAnchor.constraint(equalTo: self.childContainerView.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: self.childContainerView.trailingAnchor),
            childView.topAnchor.constraint(equalTo: self.childContainerView.topAnchor),
            childView.bottomAnchor.constraint(equalTo: self.childContainerView.bottomAnchor)
        ])

        self.pullBarSafeAreaTop = self.options.shouldExtendBackground ? self.options.pullBarHeight : 0
        self.applyChildSafeAreaInsets()
        self.childViewController.didMove(toParent: self)
        
        self.childContainerView.layer.masksToBounds = true
        self.childContainerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }

    private func setupContentView() {
        self.view.addSubview(self.contentView)
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        let contentTopConstraint = self.contentView.topAnchor.constraint(equalTo: self.view.topAnchor)
        self.contentTopConstraint = contentTopConstraint
        NSLayoutConstraint.activate([
            contentTopConstraint,
            self.contentView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.contentView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        self.contentView.addSubview(self.contentWrapperView)
        self.contentWrapperView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.contentWrapperView.layer.masksToBounds = true
        self.contentWrapperView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
                
        self.contentView.addSubview(overflowView)
        overflowView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.contentView.snp.bottom).offset(1)
            make.height.equalTo(200)
        }
    }
    
    private func setupChildContainerView() {
        self.contentWrapperView.addSubview(self.childContainerView)
        self.childContainerView.snp.makeConstraints { make in
            if self.options.shouldExtendBackground {
                make.top.equalToSuperview()
            } else {
                make.top.equalToSuperview().inset(self.options.pullBarHeight)
            }
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    private func setupPullBarView() {
        guard self.options.pullBarHeight > 0 else { return }
        
        self.pullBarView.isUserInteractionEnabled = true
        self.pullBarView.backgroundColor = self.pullBarBackgroundColor
        self.contentWrapperView.addSubview(self.pullBarView)
        
        self.pullBarView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(self.options.pullBarHeight)
        }
        
        self.gripView.backgroundColor = self.gripColor
        self.gripView.layer.cornerRadius = max(0, self.gripSize.height) / 2
        self.gripView.layer.masksToBounds = true
        pullBarView.addSubview(self.gripView)

        self.gripView.translatesAutoresizingMaskIntoConstraints = false
        let gripWidthConstraint = self.gripView.widthAnchor.constraint(equalToConstant: max(0, self.gripSize.width))
        let gripHeightConstraint = self.gripView.heightAnchor.constraint(equalToConstant: max(0, self.gripSize.height))
        self.gripWidthConstraint = gripWidthConstraint
        self.gripHeightConstraint = gripHeightConstraint
        NSLayoutConstraint.activate([
            self.gripView.centerXAnchor.constraint(equalTo: self.pullBarView.centerXAnchor),
            self.gripView.centerYAnchor.constraint(equalTo: self.pullBarView.centerYAnchor),
            gripWidthConstraint,
            gripHeightConstraint
        ])
        
        self.pullBarView.isAccessibilityElement = true
        self.pullBarView.accessibilityIdentifier = "pull-bar"
        self.pullBarView.accessibilityLabel = "PT Sheet dismiss".localized()
        self.pullBarView.accessibilityTraits = [.button]
        
        // [修复核心漏洞] 必须使用 [weak self] 防止强引用循环！
        let tapGestureRecognizer = UITapGestureRecognizer { [weak self] _ in
            self?.pullBarTappedAction?()
        }
        self.pullBarView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func contentSizeDidChange() {
        self.updatePreferredHeight()
    }

    private func updateGripConstraints() {
        guard self.isViewLoaded, self.gripView.superview != nil else { return }
        self.gripWidthConstraint?.constant = max(0, self.gripSize.width)
        self.gripHeightConstraint?.constant = max(0, self.gripSize.height)
        self.gripView.layer.cornerRadius = max(0, self.gripSize.height) / 2
    }

    private func applyChildSafeAreaInsets() {
        var insets = self.originalChildSafeAreaInsets
        insets.top += self.pullBarSafeAreaTop
        insets.bottom += self.keyboardSafeAreaBottom
        self.childViewController.additionalSafeAreaInsets = insets
    }

    public override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        self.updatePreferredHeight()
    }
}

// MARK: - UINavigationControllerDelegate
extension PTSheetContentViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        navigationController.view.endEditing(true)
    }
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        self.updatePreferredHeight()
    }
}

#endif // os(iOS) || os(tvOS) || os(watchOS)
