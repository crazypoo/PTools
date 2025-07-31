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
    
    public var showAnimator:Bool = false
    
    public var imageData:Any! {
        didSet {
            if showAnimator {
                PTGCDManager.gcdMain {
                    self.resetAnimator()
                }
            } else {
                effectView.isHidden = true
            }
            
            imageView.loadImage(contentData: imageData as Any, loadFinish:  { _, _,_ in
                if self.showAnimator {
                    self.removeAnimator()
                }
            })
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
        contentView.addSubviews([imageView,effectView])
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        effectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
        
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
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
        
        effectView.effect = nil
        effectView.isHidden = false
        let animator = UIViewPropertyAnimator(duration: 10, curve: .linear, animations: { [weak self] in
            self?.effectView.effect = self?.effect
        })
        animator.pausesOnCompletion = true
        animator.fractionComplete = 0.1
        self.animator = animator
        
        self.animator!.startAnimation()
    }
}
