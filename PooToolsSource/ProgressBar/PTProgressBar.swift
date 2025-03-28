//
//  PTProgressBar.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

//
//  PTProgressBar.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

@objc public enum PTProgressBarShowType: Int {
    case Vertical
    case Horizontal
}

@objc public enum PTProgressBarAnimationType: Int {
    case Normal
    case Reverse
}

@objcMembers
public class PTProgressBar: UIView {
    
    open var barColor: UIColor = .systemBlue {
        didSet {
            progressView.backgroundColor = barColor
        }
    }

    public var animationed: Bool {
        return animationEnd
    }

    fileprivate var animationEnd: Bool = false
    fileprivate var isAnimating: Bool = false
    fileprivate var showType: PTProgressBarShowType!
    
    fileprivate lazy var progressView: UIView = {
        let view = UIView()
        view.backgroundColor = barColor
        return view
    }()
    
    // Constraints to update dynamically
    private var progressWidthConstraint: Constraint?
    private var progressHeightConstraint: Constraint?
    private var progressBottomConstraint: Constraint?

    public init(showType: PTProgressBarShowType) {
        super.init(frame: .zero)
        self.showType = showType
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(progressView)
        
        switch showType {
        case .Vertical:
            progressView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalToSuperview()
                progressHeightConstraint = make.height.equalTo(0).constraint
            }
        case .Horizontal:
            progressView.snp.makeConstraints { make in
                make.top.bottom.leading.equalToSuperview()
                progressWidthConstraint = make.width.equalTo(0).constraint
            }
        default:
            break
        }
    }

    public func animationProgress(duration: CGFloat, @PTClampedProperyWrapper(range: 0...1) value: CGFloat) {
        startAnimation(type: .Normal, duration: duration, value: value)
    }

    public func startAnimation(type: PTProgressBarAnimationType, duration: CGFloat, @PTClampedProperyWrapper(range: 0...1) value: CGFloat) {
        guard !isAnimating else { return }
        
        isAnimating = true
        animationEnd = false
        
        let animations = {
            switch self.showType {
            case .Vertical:
                self.progressHeightConstraint?.update(offset: self.bounds.height * value)
            case .Horizontal:
                self.progressWidthConstraint?.update(offset: self.bounds.width * value)
            default:
                break
            }
            self.layoutIfNeeded()
        }

        let options: UIView.AnimationOptions = (type == .Reverse) ? [.autoreverse] : []
        UIView.animate(withDuration: TimeInterval(duration), delay: 0, options: options, animations: animations) { _ in
            self.animationEnd = true
        }
    }

    public func stopAnimation() {
        guard isAnimating else { return }

        progressView.layer.removeAllAnimations()
        
        switch showType {
        case .Vertical:
            progressHeightConstraint?.update(offset: 0)
        case .Horizontal:
            progressWidthConstraint?.update(offset: 0)
        default:
            break
        }
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }

        isAnimating = false
        animationEnd = false
    }

    public func getProgress() -> CGFloat {
        switch showType {
        case .Vertical:
            return (progressHeightConstraint?.layoutConstraints.first?.constant ?? 0) / bounds.height
        case .Horizontal:
            return (progressWidthConstraint?.layoutConstraints.first?.constant ?? 0) / bounds.width
        default:
            return 0
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()

        // 根據 currentProgress 還原 constraint
        switch showType {
        case .Vertical:
            progressHeightConstraint?.update(offset: bounds.height * getProgress())
        case .Horizontal:
            progressWidthConstraint?.update(offset: bounds.width * getProgress())
        default:
            break
        }
    }
}
