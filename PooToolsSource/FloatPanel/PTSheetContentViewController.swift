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

public class PTSheetContentViewController: PTBaseViewController {

    public private(set) var childViewController: UIViewController
    
    private var options: PTSheetOptions
    private(set) var size: CGFloat = 0
    private(set) var preferredHeight: CGFloat
    
    public var contentBackgroundColor: UIColor? {
        get { self.childContainerView.backgroundColor }
        set { self.childContainerView.backgroundColor = newValue }
    }

    private var _cornerCurve: Any? = nil
    
    public var cornerCurve: CALayerCornerCurve {
        get {
            return _cornerCurve as? CALayerCornerCurve ?? CALayerCornerCurve.circular }
        set {
            _cornerCurve = newValue
            self.updateCornerCurve()
        }
    }
    
    public var cornerRadius: CGFloat = 0 {
        didSet {
            self.updateCornerRadius()
        }
    }
    
    public var gripSize: CGSize = CGSize(width: 50, height: 6) {
        didSet {
            self.gripView.snp.updateConstraints { make in
                make.size.equalTo(self.gripSize)
            }
            self.gripView.layer.cornerRadius = self.gripSize.height / 2
        }
    }
    
    public var gripColor: UIColor? {
        get { return self.gripView.backgroundColor }
        set { self.gripView.backgroundColor = newValue }
    }
    
    public var pullBarBackgroundColor: UIColor? {
        get { return self.pullBarView.backgroundColor }
        set { self.pullBarView.backgroundColor = newValue }
    }
    public var treatPullBarAsClear: Bool = PTSheetViewController.treatPullBarAsClear {
        didSet {
            if self.isViewLoaded {
                self.updateCornerRadius()
            }
        }
    }
    
    var sheetContentViewPreferredHeightChanged:((_ oldHeight:CGFloat,_ newSize:CGFloat) -> Void)?
    var pullBarTappedAction:PTActionTask?
    
    public var contentWrapperView = UIView()
    public var contentView = UIView()
    public var childContainerView = UIView()
    public lazy var pullBarView:UIView = {
        let view = UIView()
        return view
    }()
    public lazy var gripView:UIView = {
        let view = UIView()
        return view
    }()
    private let overflowView = UIView()
    
    public init(childViewController: UIViewController, options: PTSheetOptions) {
        self.options = options
        self.childViewController = childViewController
        self.preferredHeight = 0
        super.init(nibName: nil, bundle: nil)
        
        if options.setIntrinsicHeightOnNavigationControllers, let navigationController = self.childViewController as? UINavigationController {
            navigationController.delegate = self
        }
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
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
    }
    
    func updateAfterLayout() {
        self.size = self.childViewController.view.bounds.height
    }
    
    func adjustForKeyboard(height: CGFloat) {
        self.updateChildViewControllerBottomConstraint(adjustment: -height)
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
        switch (self.options.transitionOverflowType) {
            case .view(view: let view):
                overflowView.backgroundColor = .clear
                overflowView.addSubview(view) 
            view.snp.makeConstraints({ make in
                make.edges.equalToSuperview()
            })
            case .automatic:
                overflowView.backgroundColor = self.childViewController.view.backgroundColor
            case .color(color: let color):
                overflowView.backgroundColor = color
            case .none:
                overflowView.backgroundColor = .clear
        }
    }
    
    private func updateNavigationControllerHeight() {
        // UINavigationControllers don't set intrinsic size, this is a workaround to fix that
        guard self.options.setIntrinsicHeightOnNavigationControllers, let _ = self.childViewController as? UINavigationController else { return }
    }
    
    func updatePreferredHeight() {
        self.updateNavigationControllerHeight()
        let width = self.view.bounds.width > 0 ? self.view.bounds.width : UIScreen.main.bounds.width
        let oldPreferredHeight = self.preferredHeight
        var fittingSize = UIView.layoutFittingCompressedSize;
        fittingSize.width = width;
        
        UIView.performWithoutAnimation {
            self.contentView.layoutSubviews()
        }
        
        self.preferredHeight = self.contentView.systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow).height
        UIView.performWithoutAnimation {
            self.contentView.layoutSubviews()
        }
        
        sheetContentViewPreferredHeightChanged?(oldPreferredHeight,self.preferredHeight)
    }
    
    private func updateChildViewControllerBottomConstraint(adjustment: CGFloat) {
        self.childViewController.view.snp.updateConstraints { make in
            make.bottom.equalToSuperview().inset(adjustment)
        }
    }
    
    private func setupChildViewController() {
        self.childViewController.willMove(toParent: self)
        self.addChild(self.childViewController)
        self.childContainerView.addSubview(self.childViewController.view)
        self.childViewController.view.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(0)
        }
        if self.options.shouldExtendBackground, self.options.pullBarHeight > 0 {
            self.childViewController.compatibleAdditionalSafeAreaInsets = UIEdgeInsets(top: self.options.pullBarHeight, left: 0, bottom: 0, right: 0)
        }
        
        self.childViewController.didMove(toParent: self)
        
        self.childContainerView.layer.masksToBounds = true
        self.childContainerView.layer.compatibleMaskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }

    private func setupContentView() {
        self.view.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }
        self.contentView.addSubview(self.contentWrapperView)
        self.contentWrapperView.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        
        self.contentWrapperView.layer.masksToBounds = true
        self.contentWrapperView.layer.compatibleMaskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
                
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
        // If they didn't specify pull bar options, they don't want a pull bar
        guard self.options.pullBarHeight > 0 else { return }
        self.pullBarView.isUserInteractionEnabled = true
        self.pullBarView.backgroundColor = self.pullBarBackgroundColor
        self.contentWrapperView.addSubview(self.pullBarView)
        self.pullBarView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(self.options.pullBarHeight)
        }
        
        self.gripView.backgroundColor = self.gripColor
        self.gripView.layer.cornerRadius = self.gripSize.height / 2
        self.gripView.layer.masksToBounds = true
        pullBarView.addSubview(self.gripView)
        self.gripView.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
            make.size.equalTo(self.gripSize)
        }
        
        self.pullBarView.isAccessibilityElement = true
        self.pullBarView.accessibilityIdentifier = "pull-bar"
        // This will be overriden whenever the sizes property is changed on SheetViewController
        self.pullBarView.accessibilityLabel = "Tap to Dismiss Presentation."
        self.pullBarView.accessibilityTraits = [.button]
        
        let tapGestureRecognizer = UITapGestureRecognizer.init { sender in
            self.pullBarTappedAction?()
        }
        self.pullBarView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func contentSizeDidChange() {
        self.updatePreferredHeight()
    }
}

extension PTSheetContentViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        navigationController.view.endEditing(true)
    }
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        self.updatePreferredHeight()
    }
}

#endif
