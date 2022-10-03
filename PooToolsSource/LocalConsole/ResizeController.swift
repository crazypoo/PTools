//
//  ResizeController.swift
//
//  Created by Duraid Abdul.
//  Copyright © 2021 Duraid Abdul. All rights reserved.
//

import UIKit

@available(iOSApplicationExtension, unavailable)
class ResizeController {
    
    public static let shared = ResizeController()
    
    lazy var platterView = PlatterView(frame: .zero)
    
    lazy var consoleCenterPoint = CGPoint(x: (UIScreen.main.nativeBounds.width / 2).rounded() / UIScreen.main.scale,
                                          y: (UIScreen.main.nativeBounds.height / 2).rounded() / UIScreen.main.scale
                                            + (UIScreen.hasRoundedCorners ? 0 : 24))
    
    lazy var terminalView = AppWindows?.viewWithTag(SystemLogViewTag) as! PTTerminal
    
    lazy var consoleOutlineView: UIView = {
        
        let consoleViewReference = AppWindows?.viewWithTag(SystemLogViewTag) as! PTTerminal
        
        let view = UIView()
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.randomColor.cgColor
        view.layer.cornerRadius = consoleViewReference.layer.cornerRadius + 6
        if #available(iOS 13.0, *) {
            view.layer.cornerCurve = .continuous
        }
        view.alpha = 0
        
        consoleViewReference.addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: consoleViewReference.leadingAnchor, constant: -6),
            view.trailingAnchor.constraint(equalTo: consoleViewReference.trailingAnchor, constant: 6),
            view.topAnchor.constraint(equalTo: consoleViewReference.topAnchor, constant: -6),
            view.bottomAnchor.constraint(equalTo: consoleViewReference.bottomAnchor, constant: 6)
        ])
        
        return view
    }()
    
    lazy var bottomGrabberPillView = UIView()
    
    lazy var bottomGrabber: UIView = {
        let view = UIView()
        AppWindows!.addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 116),
            view.heightAnchor.constraint(equalToConstant: 46),
            view.centerXAnchor.constraint(equalTo: consoleOutlineView.centerXAnchor),
            view.topAnchor.constraint(equalTo: consoleOutlineView.bottomAnchor, constant: -18)
        ])
        
        bottomGrabberPillView.frame = CGRect(x: 58 - 18, y: 25, width: 36, height: 5)
        bottomGrabberPillView.backgroundColor = .randomColor
        bottomGrabberPillView.alpha = 0.3
        bottomGrabberPillView.layer.cornerRadius = 2.5
        if #available(iOS 13.0, *) {
            bottomGrabberPillView.layer.cornerCurve = .continuous
        }
        view.addSubview(bottomGrabberPillView)
        
        let verticalPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(verticalPanner(recognizer:)))
        verticalPanGestureRecognizer.maximumNumberOfTouches = 1
        view.addGestureRecognizer(verticalPanGestureRecognizer)
        
        view.alpha = 0
        
        return view
    }()
    
    lazy var rightGrabberPillView = UIView()
    
    lazy var rightGrabber: UIView = {
        let view = UIView()
        AppWindows!.addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 46),
            view.heightAnchor.constraint(equalToConstant: 116),
            view.centerYAnchor.constraint(equalTo: consoleOutlineView.centerYAnchor),
            view.leftAnchor.constraint(equalTo: consoleOutlineView.rightAnchor, constant: -18)
        ])
        
        rightGrabberPillView.frame = CGRect(x: 25, y: 58 - 18, width: 5, height: 36)
        rightGrabberPillView.backgroundColor = .randomColor
        rightGrabberPillView.alpha = 0.3
        rightGrabberPillView.layer.cornerRadius = 2.5
        if #available(iOS 13.0, *) {
            rightGrabberPillView.layer.cornerCurve = .continuous
        }
        view.addSubview(rightGrabberPillView)
        
        let horizontalPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(horizontalPanner(recognizer:)))
        horizontalPanGestureRecognizer.maximumNumberOfTouches = 1
        view.addGestureRecognizer(horizontalPanGestureRecognizer)
        
        view.alpha = 0
        
        return view
    }()
        
    var isActive: Bool = false {
        didSet {
            guard isActive != oldValue else { return }
            
            // Initialize views outside of animation.
            _ = platterView
            _ = consoleOutlineView
            _ = bottomGrabber
            _ = rightGrabber
            
            // Ensure initial autolayout is performed unanimated.
            
            AppWindows!.bringSubviewToFront(terminalView)
            
            terminalView.menuButton.isHidden = isActive
            
            platterView.fontText.text = String.init(format: "%f", terminalView.fontSize!)
            platterView.FontSizeBlock = { (fontSize) in
                self.terminalView.fontSize = fontSize
            }

            if isActive {
                
                UIViewPropertyAnimator(duration: 0.75, dampingRatio: 1) {
                    
                    let textView = self.terminalView.systemText
                    
                    textView!.contentOffset.y = textView!.contentSize.height - textView!.bounds.size.height
                }.startAnimation()
                
                
                if #available(iOS 12.0, *) {
                    if terminalView.traitCollection.userInterfaceStyle == .light {
                        terminalView.layer.shadowOpacity = 0.25
                    }
                }
                
                // Ensure background color animates in right the first time.
                AppWindows!.backgroundColor = .clear
                
                UIViewPropertyAnimator(duration: 0.6, dampingRatio: 1) {
                    self.terminalView.center = self.consoleCenterPoint
                    
                    // Update grabbers (layout constraints)
                    AppWindows!.backgroundColor = .randomColor
                }.startAnimation()
                
                UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1) { [self] in
                    consoleOutlineView.alpha = 1
                }.startAnimation(afterDelay: 0.3)
                
                bottomGrabber.transform = .init(translationX: 0, y: -5)
                rightGrabber.transform = .init(translationX: -5, y: 0)
                
                UIViewPropertyAnimator(duration: 1, dampingRatio: 1) { [self] in
                    bottomGrabber.alpha = 1
                    rightGrabber.alpha = 1
                    
                    bottomGrabber.transform = .identity
                    rightGrabber.transform = .identity
                }.startAnimation(afterDelay: 0.3)
                                
                // Activate full screen button.
                consoleOutlineView.isUserInteractionEnabled = true
            } else {
                
                terminalView.layer.shadowOpacity = 0.5
                
                UIViewPropertyAnimator(duration: 0.6, dampingRatio: 1) {
                    self.terminalView.center = CGPoint.init(x: Double(self.terminalView.bounds.width)/2, y: Double(self.terminalView.bounds.height)/2 + Double(kStatusBarHeight))
//
//                    // Update grabbers (layout constraints)
                    AppWindows!.backgroundColor = .clear
                }.startAnimation()
                
                UIViewPropertyAnimator(duration: 0.2, dampingRatio: 1) { [self] in
                    consoleOutlineView.alpha = 0
                    
                    bottomGrabber.alpha = 0
                    rightGrabber.alpha = 0
                }.startAnimation()
                                
                // Deactivate full screen button.
                consoleOutlineView.isUserInteractionEnabled = false
            }
        }
    }
    
    var initialHeight = CGFloat.zero
    
    static let kMinConsoleHeight: CGFloat = systemLog_base_height
    static let kMaxConsoleHeight: CGFloat = 346
    
    @objc func verticalPanner(recognizer: UIPanGestureRecognizer) {
        
        let translation = recognizer.translation(in: bottomGrabber.superview)
        
        let minHeight = Self.kMinConsoleHeight
        let maxHeight = Self.kMaxConsoleHeight
        
        switch recognizer.state {
        case .began:
            initialHeight = terminalView.height
            
            UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1) { [self] in
                bottomGrabberPillView.alpha = 0.6
            }.startAnimation()
            
        case .changed:
            
            let resolvedHeight: CGFloat = {
                let initialEstimate = initialHeight + 2 * translation.y
                if initialEstimate <= maxHeight && initialEstimate > minHeight {
                    return initialEstimate
                } else if initialEstimate > maxHeight {
                    
                    var excess = initialEstimate - maxHeight
                    excess = 25 * log(1/25 * excess + 1)
                    
                    return maxHeight + excess
                } else {
                    var excess = minHeight - initialEstimate
                    excess = 7 * log(1/7 * excess + 1)
                    
                    return minHeight - excess
                }
            }()
            
            terminalView.bounds.size.height = resolvedHeight
            terminalView.center.y = consoleCenterPoint.y

        case .ended, .cancelled:
            UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.7) {
                if self.terminalView.bounds.size.height > maxHeight {
                    self.terminalView.bounds.size.height = maxHeight
                }
                if self.terminalView.bounds.size.height < minHeight {
                    self.terminalView.bounds.size.height = minHeight
                }
                
                self.terminalView.center.y = self.consoleCenterPoint.y
                
                // Animate autolayout updates.
                self.terminalView.layoutIfNeeded()
                AppWindows!.layoutIfNeeded()
            }.startAnimation()
            
            UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1) { [self] in
                bottomGrabberPillView.alpha = 0.3
            }.startAnimation()
            
        default: break
        }
    }
    
    var initialWidth = CGFloat.zero
    
    static let kMinConsoleWidth: CGFloat = systemLog_base_width
    static let kMaxConsoleWidth: CGFloat = kSCREEN_WIDTH - 56
    
    @objc func horizontalPanner(recognizer: UIPanGestureRecognizer) {
        
        let translation = recognizer.translation(in: bottomGrabber.superview)
        
        let minWidth = Self.kMinConsoleWidth
        let maxWidth = Self.kMaxConsoleWidth
        
        switch recognizer.state {
        case .began:
            initialWidth = terminalView.bounds.size.width
            
            UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1) { [self] in
                rightGrabberPillView.alpha = 0.6
            }.startAnimation()
            
        case .changed:
            
            let resolvedWidth: CGFloat = {
                let initialEstimate = initialWidth + 2 * translation.x
                if initialEstimate <= maxWidth && initialEstimate > minWidth {
                    return initialEstimate
                } else if initialEstimate > maxWidth {
                    
                    var excess = initialEstimate - maxWidth
                    excess = 25 * log(1/25 * excess + 1)
                    
                    return maxWidth + excess
                } else {
                    var excess = minWidth - initialEstimate
                    excess = 7 * log(1/7 * excess + 1)
                    
                    return minWidth - excess
                }
            }()
            
            terminalView.bounds.size.width = resolvedWidth
            terminalView.center.x = (UIScreen.main.nativeBounds.width * 1/2).rounded() / UIScreen.main.scale

        case .ended, .cancelled:
            
            UIViewPropertyAnimator(duration: 0.4, dampingRatio: 0.7) {
                if self.terminalView.bounds.size.width > maxWidth {
                    self.terminalView.bounds.size.width = maxWidth
                }
                if self.terminalView.bounds.size.width < minWidth {
                    self.terminalView.bounds.size.width = minWidth
                }
                
                self.terminalView.center.x = (UIScreen.main.nativeBounds.width * 1/2).rounded() / UIScreen.main.scale
                
                // Animate autolayout updates.
                self.terminalView.layoutIfNeeded()
                AppWindows!.layoutIfNeeded()
            }.startAnimation()
            
            UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1) { [self] in
                rightGrabberPillView.alpha = 0.3
            }.startAnimation()
            
        default: break
        }
    }
}

@available(iOSApplicationExtension, unavailable)
class PlatterView: UIView,UITextFieldDelegate {
    
    var FontSizeBlock:((_ text:CGFloat)->Void)?
    
    lazy var terminalView = AppWindows?.viewWithTag(SystemLogViewTag) as! PTTerminal

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.frame.size = UIScreen.portraitSize
        // Make sure bottom doesn't show on upwards pan.
        self.frame.size.height += 50
        self.frame.origin = possibleEndpoints[1]
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.125
        layer.shadowOffset = CGSize(width: 0, height: 0)
        
        layer.borderColor = UIColor.randomColor.cgColor
        layer.borderWidth = 1 / UIScreen.main.scale
        layer.cornerRadius = 30
        if #available(iOS 13.0, *) {
            layer.cornerCurve = .continuous
        }
        
        if #available(iOS 13.0, *) {
            let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
            blurView.layer.cornerRadius = 30
            blurView.layer.cornerCurve = .continuous
            blurView.clipsToBounds = true
            
            blurView.frame = bounds
            
            addSubview(blurView)
        }
        
        backgroundColor = .randomColor
        AppWindows!.addSubview(self)
        
        _ = backgroundButton
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(platterPanner(recognizer:)))
        panRecognizer.maximumNumberOfTouches = 1
        addGestureRecognizer(panRecognizer)
        
        let grabber = UIView()
        grabber.frame.size = CGSize(width: 36, height: 5)
        grabber.frame.origin.y = 10
        grabber.center.x = bounds.width / 2
        grabber.backgroundColor = .randomColor
        grabber.alpha = 0.1
        grabber.layer.cornerRadius = 2.5
        if #available(iOS 13.0, *) {
            grabber.layer.cornerCurve = .continuous
        }
        addSubview(grabber)
        
        let titleLabel = UILabel()
        titleLabel.text = "Resize Console"
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.sizeToFit()
        titleLabel.center.x = bounds.width / 2
        titleLabel.frame.origin.y = 28
        titleLabel.roundOriginToPixel()
        addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Use the grabbers to resize the console."
        subtitleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        subtitleLabel.sizeToFit()
        subtitleLabel.alpha = 0.5
        subtitleLabel.center.x = bounds.width / 2
        subtitleLabel.frame.origin.y = titleLabel.frame.maxY + 8
        subtitleLabel.roundOriginToPixel()
        addSubview(subtitleLabel)
        
        addSubview(resetButton)
        resetButton.center = CGPoint(x: UIScreen.portraitSize.width / 2 - 74,
                                     y: UIScreen.portraitSize.height - possibleEndpoints[0].y * 2)
        resetButton.roundOriginToPixel()
        
        addSubview(doneButton)
        doneButton.center = CGPoint(x: UIScreen.portraitSize.width / 2 + 74,
                                    y: UIScreen.portraitSize.height - possibleEndpoints[0].y * 2)
        doneButton.roundOriginToPixel()
        
        fontSizeTitle.text = "Font Size:"
        addSubview(fontSizeTitle)
        fontSizeTitle.snp.makeConstraints { make in
            make.left.equalTo(resetButton.snp.left)
            make.bottom.equalTo(doneButton.snp.top).offset(-30)
        }
        
        addSubview(fontText)
        fontText.snp.makeConstraints { make in
            make.left.equalTo(fontSizeTitle.snp.right)
            make.right.equalTo(doneButton.snp.right)
            make.centerY.equalTo(fontSizeTitle)
        }

    }
    
    lazy var backgroundButton: UIButton = {
        let backgroundButton = UIButton.init(type: .custom)
        backgroundButton.addActionHandlers { sender in
            ResizeController.shared.isActive = false
            self.dismiss()
        }
        backgroundButton.frame.size = CGSize(width: self.frame.size.width, height: possibleEndpoints[0].y + 30)
        AppWindows!.addSubview(backgroundButton)
        AppWindows!.sendSubviewToBack(backgroundButton)
        return backgroundButton
    }()
    
    lazy var doneButton: UIButton = {
        let button = UIButton(type: .custom)
        if #available(iOS 13.0, *) {
            button.backgroundColor = UIColor.systemBlue.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        }
        else
        {
            button.backgroundColor = .randomColor
        }
        
        button.setTitle("Done", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.frame.size = CGSize(width: 116, height: 52)
        button.layer.cornerRadius = 20
        if #available(iOS 13.0, *) {
            button.layer.cornerCurve = .continuous
        }
        
        button.addActionHandlers { sender in
            ResizeController.shared.isActive = false
            self.dismiss()
        }

        return button
    }()
    
    lazy var resetButton: UIButton = {
        let button = UIButton(type: .custom)
        if #available(iOS 13.0, *) {
            button.backgroundColor = UIColor(dynamicProvider: { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor(white: 1, alpha: 0.125)
                } else {
                    return UIColor(white: 0, alpha: 0.1)
                }
            })
        }
        else
        {
            button.backgroundColor = .randomColor
        }
        
        button.setTitle("Reset", for: .normal)
        button.setTitleColor(.randomColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.frame.size = CGSize(width: 116, height: 52)
        button.layer.cornerRadius = 20
        if #available(iOS 13.0, *) {
            button.layer.cornerCurve = .continuous
        }
        
        button.addActionHandlers { sender in
            // Resolves a text view frame animation bug that occurs when *decreasing* text view width.
            if self.terminalView.bounds.size.width > systemLog_base_width {
                self.terminalView.systemText!.frame.size.width = systemLog_base_width - borderLine * 4
            }
            
            UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1) {
                self.terminalView.bounds.size = CGSize.init(width: systemLog_base_width, height: systemLog_base_height)
                self.terminalView.center = ResizeController.shared.consoleCenterPoint
                self.terminalView.fontSize = LocalConsoleFontBaseSize
                AppWindows!.layoutIfNeeded()
            }.startAnimation()

        }
        
        return button
    }()
    
    lazy var fontSizeTitle : UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textColor = .black
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.sizeToFit()
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .left
        return label
    }()
    
    lazy var fontText : UITextField = {
        let slider = UITextField()
        slider.placeholder = "Min:\(LocalConsoleFontMin),Max:\(LocalConsoleFontMax)"
        slider.keyboardType = .decimalPad
        slider.delegate = self
        slider.viewCorner(radius: 5,borderWidth: 1, borderColor: .randomColor)
        return slider
    }()
    
    func reveal() {
        UIViewPropertyAnimator(duration: 0.6, dampingRatio: 1) {
            self.frame.origin = self.possibleEndpoints[0]
        }.startAnimation()
        
        backgroundButton.isHidden = false
    }
    
    func dismiss() {
        UIViewPropertyAnimator(duration: 0.6, dampingRatio: 1) {
            self.frame.origin = self.possibleEndpoints[1]
        }.startAnimation()
        
        backgroundButton.isHidden = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
            layer.borderColor = UIColor.randomColor.cgColor
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var possibleEndpoints = [CGPoint(x: 0, y: (UIScreen.hasRoundedCorners ? 44 : -8) + 63), CGPoint(x: 0, y: UIScreen.portraitSize.height + 5)]
    
    var initialPlatterOriginY = CGFloat.zero
    
    @objc func platterPanner(recognizer: UIPanGestureRecognizer) {
        
        let translation = recognizer.translation(in: superview)
        let velocity = recognizer.velocity(in: superview)
        
        switch recognizer.state {
        case .began:
            initialPlatterOriginY = frame.origin.y
        case .changed:
            
            let resolvedOriginY: CGFloat = {
                let initialEstimate = initialPlatterOriginY + translation.y
                if initialEstimate >= possibleEndpoints[0].y {
                    
                    // Stick buttons to bottom.
                    [fontText,doneButton, resetButton,
                     ResizeController.shared.bottomGrabber, ResizeController.shared.rightGrabber,
                     self.terminalView
                    ].forEach {
                        $0.transform = .identity
                    }
                    
                    return initialEstimate
                } else {
                    var excess = possibleEndpoints[0].y - initialEstimate
                    excess = 10 * log(1/10 * excess + 1)
                    
                    // Stick buttons to bottom.
                    doneButton.transform = .init(translationX: 0, y: excess)
                    resetButton.transform = .init(translationX: 0, y: excess)
                    
                    ResizeController.shared.bottomGrabber.transform = .init(translationX: 0, y: -excess / 2.5)
                    ResizeController.shared.rightGrabber.transform = .init(translationX: 0, y: -excess / 2)
                    self.terminalView.transform = .init(translationX: 0, y: -excess / 2)
                    
                    return possibleEndpoints[0].y - excess
                }
            }()
            
            if frame.origin.y > possibleEndpoints[0].y + 40 {
                ResizeController.shared.isActive = false
            } else {
                ResizeController.shared.isActive = true
            }
            
            frame.origin.y = resolvedOriginY
            
        case .ended, .cancelled:
            
            // After the PiP is thrown, determine the best corner and re-target it there.
            let decelerationRate = UIScrollView.DecelerationRate.normal.rawValue

            let projectedPosition = CGPoint(
                x: 0,
                y: frame.origin.y + project(initialVelocity: velocity.y, decelerationRate: decelerationRate)
            )

            let nearestTargetPosition = nearestTargetTo(projectedPosition, possibleTargets: possibleEndpoints)

            let relativeInitialVelocity = CGVector(
                dx: 0,
                dy: frame.origin.y >= possibleEndpoints[0].y
                    ? relativeVelocity(forVelocity: velocity.y, from: frame.origin.y, to: nearestTargetPosition.y)
                    : 0
            )

            let timingParameters = UISpringTimingParameters(damping: 1, response: 0.4, initialVelocity: relativeInitialVelocity)
            let positionAnimator = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters)
            positionAnimator.addAnimations { [self] in
                frame.origin = nearestTargetPosition

                [fontText,doneButton, resetButton,
                 ResizeController.shared.bottomGrabber, ResizeController.shared.rightGrabber,
                 self.terminalView
                ].forEach {
                    $0.transform = .identity
                }
            }
            positionAnimator.startAnimation()

            if nearestTargetPosition == possibleEndpoints[1] {
                ResizeController.shared.isActive = false
                backgroundButton.isHidden = true
            } else {
                ResizeController.shared.isActive = true
            }
            
        default: break
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        if FontSizeBlock != nil
        {
            if !(textField.text ?? "").stringIsEmpty()
            {
                if (textField.text?.cgFloat())! < LocalConsoleFontMin
                {
                    textField.text = "4"
                    FontSizeBlock!(4)
                }
                else if (textField.text?.cgFloat())! > LocalConsoleFontMax
                {
                    textField.text = "20"
                    FontSizeBlock!(20)
                }
                else
                {
                    FontSizeBlock!((textField.text?.cgFloat())!)
                }
            }
        }
    }
}
