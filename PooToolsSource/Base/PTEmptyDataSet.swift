//
//  PTEmptyDataSet.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/4/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import Foundation
import UIKit

private var kEmptyDataSetSource:UInt8 = 0
private var kEmptyDataSetDelegate:UInt8 = 0
private var kEmptyDataSetView:UInt8 = 0
private var kConfigureEmptyDataSetView:UInt8 = 0

class WeakObjectContainer: NSObject {
    weak var weakObject: AnyObject?
    init(with weakObject: Any?) {
        super.init()
        self.weakObject = weakObject as AnyObject?
    }
}

@MainActor // 🌟 保证 UI 操作绝对在主线程
extension UIScrollView: @retroactive UIGestureRecognizerDelegate {
    
    public var configureEmptyDataSetView: ((PTEmptyDataSetView) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &kConfigureEmptyDataSetView) as? (PTEmptyDataSetView) -> Void
        }
        set {
            objc_setAssociatedObject(self, &kConfigureEmptyDataSetView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            // 🌟 移除 Swizzling，直接手动触发一次校验
            reloadEmptyDataSet()
        }
    }
    
    // MARK: - Public Property
    
    public var emptyDataSetSource: PTEmptyDataSetSource? {
        get {
            let container = objc_getAssociatedObject(self, &kEmptyDataSetSource) as? WeakObjectContainer
            return container?.weakObject as? PTEmptyDataSetSource
        }
        set {
            if newValue == nil { self.invalidate() }
            objc_setAssociatedObject(self, &kEmptyDataSetSource, WeakObjectContainer(with: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            reloadEmptyDataSet() // 🌟 直接触发，不再依赖黑魔法
        }
    }
    
    public var emptyDataSetDelegate: PTEmptyDataSetDelegate? {
        get {
            let container = objc_getAssociatedObject(self, &kEmptyDataSetDelegate) as? WeakObjectContainer
            return container?.weakObject as? PTEmptyDataSetDelegate
        }
        set {
            if newValue == nil { self.invalidate() }
            objc_setAssociatedObject(self, &kEmptyDataSetDelegate, WeakObjectContainer(with: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            reloadEmptyDataSet()
        }
    }
    
    public var isEmptyDataSetVisible: Bool {
        if let view = objc_getAssociatedObject(self, &kEmptyDataSetView) as? PTEmptyDataSetView {
            return !view.isHidden
        }
        return false
    }
    
    // MARK: - Private Property
    
    public func emptyDataSetView(_ closure: @escaping (PTEmptyDataSetView) -> Void) {
        configureEmptyDataSetView = closure
    }
    
    private var emptyDataSetView: PTEmptyDataSetView? {
        get {
            if let view = objc_getAssociatedObject(self, &kEmptyDataSetView) as? PTEmptyDataSetView {
                return view
            } else {
                let view = PTEmptyDataSetView(frame: frame)
                view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                view.isHidden = true
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapContentView(_:)))
                tapGesture.delegate = self
                view.addGestureRecognizer(tapGesture)
                view.button.addTarget(self, action: #selector(didTapDataButton(_:)), for: .touchUpInside)

                objc_setAssociatedObject(self, &kEmptyDataSetView, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return view
            }
        }
        set {
            objc_setAssociatedObject(self, &kEmptyDataSetView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    internal var itemsCount: Int {
        var items = 0
        
        if let tableView = self as? UITableView {
            // 🌟 直接问 TableView 自身，无需经过 dataSource
            let sections = tableView.numberOfSections
            for i in 0 ..< sections {
                items += tableView.numberOfRows(inSection: i)
            }
        } else if let collectionView = self as? UICollectionView {
            // 🌟 直接问 CollectionView 自身，完美兼容 DiffableDataSource
            let sections = collectionView.numberOfSections
            for i in 0 ..< sections {
                items += collectionView.numberOfItems(inSection: i)
            }
        }
        return items
    }
    
    // MARK: - Data Source Getters
    private var titleLabelString: NSAttributedString? { emptyDataSetSource?.title(forEmptyDataSet: self) }
    private var detailLabelString: NSAttributedString? { emptyDataSetSource?.description(forEmptyDataSet: self) }
    private var image: UIImage? { emptyDataSetSource?.image(forEmptyDataSet: self) }
    private var imageAnimation: CAAnimation? { emptyDataSetSource?.imageAnimation(forEmptyDataSet: self) }
    private var imageTintColor: UIColor? { emptyDataSetSource?.imageTintColor(forEmptyDataSet: self) }
    private func buttonTitle(for state: UIControl.State) -> NSAttributedString? { emptyDataSetSource?.buttonTitle(forEmptyDataSet: self, for: state) }
    private func buttonImage(for state: UIControl.State) -> UIImage? { emptyDataSetSource?.buttonImage(forEmptyDataSet: self, for: state) }
    private func buttonBackgroundImage(for state: UIControl.State) -> UIImage? { emptyDataSetSource?.buttonBackgroundImage(forEmptyDataSet: self, for: state) }
    private var dataSetBackgroundColor: UIColor? { emptyDataSetSource?.backgroundColor(forEmptyDataSet: self) }
    private var customView: UIView? { emptyDataSetSource?.customView(forEmptyDataSet: self) }
    private var verticalOffset: CGFloat { emptyDataSetSource?.verticalOffset(forEmptyDataSet: self) ?? 0.0 }
    private var verticalSpace: CGFloat { emptyDataSetSource?.spaceHeight(forEmptyDataSet: self) ?? 11.0 }
    
    // MARK: - Delegate Getters & Events
    private var shouldFadeIn: Bool { emptyDataSetDelegate?.emptyDataSetShouldFadeIn(self) ?? true }
    private var shouldDisplay: Bool { emptyDataSetDelegate?.emptyDataSetShouldDisplay(self) ?? true }
    private var shouldBeForcedToDisplay: Bool { emptyDataSetDelegate?.emptyDataSetShouldBeForcedToDisplay(self) ?? false }
    private var isTouchAllowed: Bool { emptyDataSetDelegate?.emptyDataSetShouldAllowTouch(self) ?? true }
    private var isScrollAllowed: Bool { emptyDataSetDelegate?.emptyDataSetShouldAllowScroll(self) ?? false }
    private var isImageViewAnimateAllowed: Bool { emptyDataSetDelegate?.emptyDataSetShouldAnimateImageView(self) ?? true }
    
    private func willAppear() { emptyDataSetDelegate?.emptyDataSetWillAppear(self); emptyDataSetView?.willAppearHandle?() }
    private func didAppear() { emptyDataSetDelegate?.emptyDataSetDidAppear(self); emptyDataSetView?.didAppearHandle?() }
    private func willDisappear() { emptyDataSetDelegate?.emptyDataSetWillDisappear(self); emptyDataSetView?.willDisappearHandle?() }
    private func didDisappear() { emptyDataSetDelegate?.emptyDataSetDidDisappear(self); emptyDataSetView?.didDisappearHandle?() }
    
    @objc private func didTapContentView(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view else { return }
        emptyDataSetDelegate?.emptyDataSet(self, didTapView: view)
        emptyDataSetView?.didTapContentViewHandle?()
    }
    
    @objc private func didTapDataButton(_ sender: UIButton) {
        emptyDataSetDelegate?.emptyDataSet(self, didTapButton: sender)
        emptyDataSetView?.didTapDataButtonHandle?()
    }
    
    // MARK: - Reload APIs (Public)
    public func reloadEmptyDataSet() {
        guard (emptyDataSetSource != nil || configureEmptyDataSetView != nil) else { return }
        
        if (shouldDisplay && itemsCount == 0) || shouldBeForcedToDisplay {
            willAppear()
            if let view = emptyDataSetView {
                view.fadeInOnDisplay = shouldFadeIn
                
                if view.superview == nil {
                    if let cv = self as? UICollectionView {
                        cv.backgroundView = view // 👈 让 CollectionView 原生接管
                    } else if let tv = self as? UITableView {
                        tv.backgroundView = view // 👈 让 TableView 原生接管
                    } else {
                        // 普通的 UIScrollView 才使用 addSubview
                        addSubview(view)
                    }
                }
                
                view.prepareForReuse()
                
                if let customView = self.customView {
                    view.customView = customView
                } else {
                    let renderingMode: UIImage.RenderingMode = imageTintColor != nil ? .alwaysTemplate : .alwaysOriginal
                    view.verticalSpace = verticalSpace
                    
                    if let image = image {
                        view.imageView.image = image.withRenderingMode(renderingMode)
                        if let imageTintColor = imageTintColor {
                            view.imageView.tintColor = imageTintColor
                        }
                    }
                    
                    if let titleLabelString = titleLabelString { view.titleLabel.attributedText = titleLabelString }
                    if let detailLabelString = detailLabelString { view.detailLabel.attributedText = detailLabelString }
                    
                    if let buttonImage = buttonImage(for: .normal) {
                        view.button.setImage(buttonImage, for: .normal)
                        view.button.setImage(self.buttonImage(for: .highlighted), for: .highlighted)
                    } else if let buttonTitle = buttonTitle(for: .normal) {
                        view.button.setAttributedTitle(buttonTitle, for: .normal)
                        view.button.setAttributedTitle(self.buttonTitle(for: .highlighted), for: .highlighted)
                        view.button.setBackgroundImage(self.buttonBackgroundImage(for: .normal), for: .normal)
                        view.button.setBackgroundImage(self.buttonBackgroundImage(for: .highlighted), for: .highlighted)
                    }
                }
                
                view.verticalOffset = verticalOffset
                view.backgroundColor = dataSetBackgroundColor
                view.isHidden = false
                view.clipsToBounds = true
                view.isUserInteractionEnabled = isTouchAllowed
                self.isScrollEnabled = isScrollAllowed
                
                if self.isImageViewAnimateAllowed, let animation = imageAnimation {
                    view.imageView.layer.add(animation, forKey: nil)
                } else {
                    view.imageView.layer.removeAllAnimations()
                }
                
                configureEmptyDataSetView?(view)
                view.setupConstraints()
                view.layoutIfNeeded()
            }
            didAppear()
        } else if isEmptyDataSetVisible {
            invalidate()
        }
    }
    
    private func invalidate() {
        willDisappear()
        if let view = emptyDataSetView {
            view.prepareForReuse()
            view.isHidden = true
        }
        self.isScrollEnabled = true
        didDisappear()
    }
}
