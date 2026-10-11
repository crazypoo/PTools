//
//  PTMediaBrowserBottom.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
#if canImport(PToolsUIFoundation)
import PToolsUIFoundation
#endif

let PageControlHeight:CGFloat = 20
let PageControlBottomSpace:CGFloat = 5
let MediaBrowserToolBarColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.4)
let BottomTopSpacing:CGFloat = 10
let BottomMoreHeight:CGFloat = 34
let BottomItemSpacing:CGFloat = 5
let ContentMoreSpacing:CGFloat = 10

class PTMediaBrowserBottom: UIView {
    
    var pageTabCallback:((_ index:Int)->Void)?
    var titleTapCallback:(() -> Void)?
    
    lazy var pageControlView:UIView = {
        switch viewConfig.pageControlOption {
        case .system:
            let view = UIPageControl()
            view.pageIndicatorTintColor = .lightGray
            view.currentPageIndicatorTintColor = .white
            view.addPageControlAction { [weak self] sender in
                self?.pageTabCallback?(sender.currentPage)
            }
            return view
        case .fill:
            let view = PTFilledPageControl()
            view.tintColor = .lightGray
            view.indicatorPadding = 8
            view.indicatorRadius = 4
            view.addPageControlAction { [weak self] sender in
                self?.pageTabCallback?(sender.currentPage)
            }
            return view
        case .pill:
            let view = PTPillPageControl()
            view.indicatorPadding = 8
            view.activeTint = .lightGray
            view.inactiveTint = .white
            view.addPageControlAction { [weak self] sender in
                self?.pageTabCallback?(sender.currentPage)
            }
            return view
        case .snake:
            let view = PTSnakePageControl()
            view.activeTint = .lightGray
            view.indicatorPadding = 8
            view.indicatorRadius = 4
            view.inactiveTint = .white
            view.addPageControlAction { [weak self] sender in
                self?.pageTabCallback?(sender.currentPage)
            }
            return view
        case .image:
            let view = PTImagePageControl()
            view.addPageControlAction { [weak self] sender in
                self?.pageTabCallback?(sender.currentPage)
            }
            return view
        case .scrolling:
            let view = PTScrollingPageControl()
            view.activeTint = .lightGray
            view.inactiveTint = .white
            view.addPageControlAction { [weak self] sender in
                self?.pageTabCallback?(sender.currentPage)
            }
            return view
        }
    }()
    
    lazy var moreActionButton:ConsoleMenuButton = {
        let view = ConsoleMenuButton()
        view.imageView?.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var titleLabel:UILabel = {
        let view = UILabel()
        view.isUserInteractionEnabled = true
        view.numberOfLines = 0
        view.addGestureRecognizer(UITapGestureRecognizer { [weak self] _ in
            self?.titleTapCallback?()
        })
        return view
    }()
    
    fileprivate var viewConfig = PTMediaBrowserConfig.share
    private var lastAdaptiveLayoutSignature: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if #available(iOS 26.0, *) {
            backgroundColor = .clear
        } else {
            backgroundColor = MediaBrowserToolBarColor
        }

        var subs = [UIView]()
        if viewConfig.pageControlShow {
            subs = [pageControlView, moreActionButton, titleLabel]
        } else {
            subs = [moreActionButton, titleLabel]
        }
        addSubviews(subs)
        if viewConfig.pageControlShow {
            pageControlView.snp.makeConstraints { make in
                make.left.equalTo(self.safeAreaLayoutGuide.snp.left).offset(PTAppBaseConfig.share.defaultViewSpace)
                make.right.equalTo(self.safeAreaLayoutGuide.snp.right).inset(PTAppBaseConfig.share.defaultViewSpace)
                make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).inset(PageControlBottomSpace)
                make.height.equalTo(PageControlHeight)
            }
        }
        
        moreActionButton.snp.makeConstraints { make in
            make.width.height.equalTo(BottomMoreHeight)
            make.right.equalTo(self.safeAreaLayoutGuide.snp.right).inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(BottomTopSpacing)
        }
        switch viewConfig.actionType {
        case .Empty:
            moreActionButton.isHidden = true
            titleLabel.snp.makeConstraints { make in
                make.left.equalTo(self.safeAreaLayoutGuide.snp.left).offset(PTAppBaseConfig.share.defaultViewSpace)
                make.right.equalTo(self.safeAreaLayoutGuide.snp.right).inset(PTAppBaseConfig.share.defaultViewSpace)
                if self.viewConfig.pageControlShow{
                    make.bottom.equalTo(self.pageControlView.snp.top).offset(-BottomItemSpacing)
                } else {
                    make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
                }
                make.top.equalTo(self.moreActionButton)
            }
        default:
            moreActionButton.isHidden = false
            titleLabel.snp.makeConstraints { make in
                make.left.equalTo(self.safeAreaLayoutGuide.snp.left).offset(PTAppBaseConfig.share.defaultViewSpace)
                if self.viewConfig.pageControlShow{
                    make.bottom.equalTo(self.pageControlView.snp.top).offset(-BottomItemSpacing)
                } else {
                    make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
                }
                make.top.equalTo(self.moreActionButton)
                make.right.equalTo(self.moreActionButton.snp.left).offset(-ContentMoreSpacing)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateAdaptiveHorizontalLayout()
    }

    // English: Keep bottom controls inside the visible horizontal pane while preserving the system bottom safe area.
    // Español: Mantiene los controles inferiores dentro del panel horizontal visible y conserva el área segura inferior.
    // 中文：让底部控件位于水平可视面板内，同时保留系统底部安全区。
    private func updateAdaptiveHorizontalLayout() {
        guard !bounds.isEmpty else { return }
        let region = PTAdaptiveVisibleRegionResolver.region(for: self)
        let horizontalRect = CGRect(x: region.visibleRect.minX,
                                    y: bounds.minY,
                                    width: region.visibleRect.width,
                                    height: bounds.height).intersection(bounds)
        let visibleRect = horizontalRect.isEmpty ? bounds : horizontalRect
        let signature = "\(region.signature)|\(visibleRect.integral)"
        guard signature != lastAdaptiveLayoutSignature else { return }
        lastAdaptiveLayoutSignature = signature

        let leadingInset = visibleRect.minX + PTAppBaseConfig.share.defaultViewSpace
        let trailingInset = max(0, bounds.width - visibleRect.maxX) + PTAppBaseConfig.share.defaultViewSpace
        if viewConfig.pageControlShow {
            pageControlView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(leadingInset)
                make.right.equalToSuperview().inset(trailingInset)
                make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).inset(PageControlBottomSpace)
                make.height.equalTo(PageControlHeight)
            }
        }

        moreActionButton.snp.remakeConstraints { make in
            make.width.height.equalTo(BottomMoreHeight)
            make.right.equalToSuperview().inset(trailingInset)
            make.top.equalToSuperview().inset(BottomTopSpacing)
        }

        titleLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(leadingInset)
            if viewConfig.pageControlShow {
                make.bottom.equalTo(pageControlView.snp.top).offset(-BottomItemSpacing)
            } else {
                make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
            }
            make.top.equalTo(moreActionButton)
            if viewConfig.actionType == .Empty || moreActionButton.isHidden {
                make.right.equalToSuperview().inset(trailingInset)
            } else {
                make.right.equalTo(moreActionButton.snp.left).offset(-ContentMoreSpacing)
            }
        }
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setLabelAtt(att:PTRichText) {
        titleLabel.attributedText = att.value
    }
}
