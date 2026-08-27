//
//  PTImageCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/10.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

open class PTImageCell: PTBaseNormalCell {
    public static let ID = "PTImageCell"

    public var showAnimator: Bool = false {
        didSet {
            guard oldValue != showAnimator else { return }
            if showAnimator, imageData != nil, !UIAccessibility.isReduceMotionEnabled {
                resetAnimator()
            } else {
                removeAnimator()
            }
        }
    }

    public var imageData: Any? {
        didSet {
            configureImage(imageData)
        }
    }
    
    private let effect = UIBlurEffect(style: .light)
    private let effectView = UIVisualEffectView(effect: nil)
    private var animator: UIViewPropertyAnimator?
    
    public lazy var imageView:UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubviews([imageView,effectView])
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        effectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        effectView.isHidden = true
    }

    private func configureImage(_ value: Any?) {
        imageView.cancelImageLoad()
        imageView.image = nil

        guard let value else {
            removeAnimator()
            return
        }

        if showAnimator, !UIAccessibility.isReduceMotionEnabled {
            resetAnimator()
        } else {
            removeAnimator()
        }

        imageView.loadImage(contentData: value, loadFinish: { [weak self] _ in
            guard let self, self.showAnimator else { return }
            self.removeAnimator()
        })
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        imageView.cancelImageLoad()
        imageView.image = nil
        imageData = nil
        showAnimator = false
        removeAnimator()
    }
    
    public func removeAnimator() {
        guard let animator else { return }
        if animator.state == .stopped {
            animator.finishAnimation(at: .current)
        } else {
            animator.stopAnimation(true)
        }
        self.animator = nil
        effectView.isHidden = true
    }
    
    public func resetAnimator() {
        removeAnimator()

        guard !UIAccessibility.isReduceMotionEnabled else { return }
        
        effectView.effect = nil
        effectView.isHidden = false
        let animator = UIViewPropertyAnimator(duration: 10, curve: .linear, animations: { [weak self] in
            self?.effectView.effect = self?.effect
        })
        animator.pausesOnCompletion = true
        animator.fractionComplete = 0.1
        self.animator = animator
        animator.startAnimation()
    }
}
