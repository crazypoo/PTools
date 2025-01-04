//
//  PTProgressBar.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

@objc public enum PTProgressBarShowType:Int {
    case Vertical
    case Horizontal
}

@objc public enum PTProgressBarAnimationType:Int {
    case Normal
    case Reverse
}

@objcMembers
public class PTProgressBar: UIView {
    
    open var barColor:UIColor = UIColor.systemBlue {
        didSet {
            progressView.backgroundColor = barColor
        }
    }
    
    public var animationed:Bool {
        animationEnd
    }
    
    fileprivate var animationEnd:Bool = false
    fileprivate var isAnimating: Bool = false
    fileprivate var animator: UIViewPropertyAnimator!
    fileprivate var showType:PTProgressBarShowType!
    fileprivate lazy var progressView:UIView = {
        let view = UIView()
        view.backgroundColor = barColor
        return view
    }()
    
    public init(showType:PTProgressBarShowType) {
        super.init(frame: .zero)
        self.showType = showType
        
        addSubview(progressView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setProgressFrame() {
        switch showType {
        case .Vertical:
            progressView.frame.size.height = 0
            progressView.frame.size.width = frame.size.width
            progressView.frame.origin.y = bounds.origin.y + frame.size.height
        case .Horizontal:
            progressView.frame.size.height = frame.size.height
            progressView.frame.size.width = 0
        default:
            break
        }
    }
    
    public func animationProgress(duration:CGFloat,@PTClampedProperyWrapper(range:0...1) value:CGFloat) {
        setProgressFrame()
        let timing:UICubicTimingParameters = UICubicTimingParameters(animationCurve: .easeInOut)
        animator = UIViewPropertyAnimator(duration: TimeInterval(duration), timingParameters: timing)
        animator.addAnimations {
            switch self.showType {
            case .Vertical:
                self.progressView.frame.size.height -= (self.frame.size.height * value)
            case .Horizontal:
                self.progressView.frame.size.width += (self.frame.size.width * value)
            default:
                break
            }
        }
        animator.startAnimation()
    }
    
    public func startAnimation(type:PTProgressBarAnimationType,duration:CGFloat) {
        if isAnimating {
            return
        }
        
        switch type {
        case .Normal:
            animationGo(reverse: false, duration: duration)
        case .Reverse:
            animationGo(reverse: true, duration: duration)
        }
    }
    
    public func animationGo(reverse:Bool,duration:CGFloat) {
        setProgressFrame()
        var options:UIView.AnimationOptions = []
        if reverse {
            options = [.repeat,.autoreverse]
        } else {
            options = [.repeat]
        }
        animator = UIViewPropertyAnimator.runningPropertyAnimator(withDuration: TimeInterval(duration), delay: 0, options: [.curveEaseInOut], animations: {
            UIView.animate(withDuration: TimeInterval(duration), delay: 0, options: options) {
                switch self.showType {
                case .Vertical:
                    self.progressView.frame.size.height -= (self.frame.size.height)
                case .Horizontal:
                    self.progressView.frame.size.width += self.frame.size.width
                default:
                    break
                }
            }
        }, completion: { finish in
            self.animationEnd = true
        })
        isAnimating = true
        animator.startAnimation()
    }
    
    public func stopAnimation() {
        if !isAnimating {
            return
        }
        isAnimating = false
        animator.stopAnimation(true)
    }
    
    public func getProgress() ->CGFloat {
        switch showType {
        case .Vertical:
            return (progressView.frame.size.height / frame.size.height)
        case .Horizontal:
            return (progressView.frame.size.width / frame.size.width)
        default:
            return 0
        }
    }
}
