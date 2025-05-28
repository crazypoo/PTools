//
//  PTGroupBuyAvatarView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/28/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

public class PTGroupBuyAvatarView: UIView {

    private let firstTag = 100
    private var showAvatarCount = 4
    private var avatarImages: [Any] = []

    private var dotViews: [UIView] = []
    private var firstAvatar: UIImageView?
    private var lastAvatar: UIImageView?
    private var newAvatarView: UIImageView?
    private var centerAvatar: [UIImageView] = []
    private var index = 0

    private var dotSize: CGFloat = 0
    private var dotSpacing: CGFloat = 5
    private var imageLastDotSpacing: CGFloat = 5
    private var imageSpacingOffset: CGFloat = 10
    private var dotCount: Int = 4
    private var hasSetup = false
    private var dotColor: DynamicColor = DynamicColor(hexString: "EAEEF1")!

    public init(avatarImages: [Any],
                showAvatarCount:Int = 4,
                dotCount: Int = 4,
                dotSize: CGFloat = 10,
                dotSpacing: CGFloat = 5,
                dotColor:DynamicColor = DynamicColor(hexString: "EAEEF1")!,
                imageLastDotSpacing: CGFloat = 5,
                imageSpacingOffset: CGFloat = 10) {
        super.init(frame: .zero)
        self.avatarImages = avatarImages.compactMap { $0 }
        self.showAvatarCount = showAvatarCount
        self.index = max(0, self.avatarImages.count - 1)
        self.dotCount = dotCount
        self.dotSize = dotSize
        self.dotSpacing = dotSpacing
        self.dotColor = dotColor
        self.imageLastDotSpacing = imageLastDotSpacing
        self.imageSpacingOffset = imageSpacingOffset
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func viewStartX(realShowCount:Int) -> CGFloat {
        let dotTotalWidth = CGFloat(dotCount) * dotSize - CGFloat(dotCount - 1) * dotSpacing
        let imageTotalWidth = CGFloat(realShowCount) * frame.height - CGFloat(realShowCount - 1) * imageSpacingOffset
        var result = (frame.width - dotTotalWidth - imageLastDotSpacing - imageTotalWidth) / 2
        if result < 0 {
            result = 0
        }
        return result
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if !hasSetup {
            setup()
            startAnimation()
            hasSetup = true
        }
    }

    private func setup() {
        backgroundColor = .clear
        layer.masksToBounds = true

        clearSubviews()
        setupAvatars()
        setupDots()
    }

    private func clearSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
        centerAvatar.removeAll()
        dotViews.removeAll()
        firstAvatar = nil
        lastAvatar = nil
        newAvatarView = nil
    }

    private func setupAvatars() {
        if showAvatarCount > avatarImages.count {
            showAvatarCount = avatarImages.count
        }
        
        let realShowCount = (avatarImages.count == showAvatarCount) ? (showAvatarCount - 1) : showAvatarCount
        let startX = viewStartX(realShowCount: realShowCount)
        for (i, image) in avatarImages.prefix(realShowCount).enumerated() {
            let avatarView = UIImageView()
            avatarView.tag = firstTag + i
            avatarView.loadImage(contentData: image)
            avatarView.contentMode = .scaleAspectFill
            avatarView.frame = CGRect(x: CGFloat(i) * frame.height - CGFloat(i) * imageSpacingOffset + startX,
                                      y: 0,
                                      width: frame.height,
                                      height: frame.height)
            avatarView.viewCorner(radius: frame.height / 2, borderWidth: 2, borderColor: .white)
            addSubview(avatarView)

            if i == 0 {
                firstAvatar = avatarView
            } else {
                centerAvatar.append(avatarView)
            }

            if i == realShowCount - 1 {
                lastAvatar = avatarView
            }
        }
    }

    private func setupDots() {
        let dotY = (frame.height - dotSize) / 2
        let startX = (lastAvatar?.frame.maxX ?? 0) + imageLastDotSpacing
        for i in 0..<dotCount {
            let dotView = UIView()
            dotView.backgroundColor = dotColor
            dotView.layer.cornerRadius = dotSize / 2
            dotView.frame = CGRect(x: startX + CGFloat(i) * (dotSize + dotSpacing),
                                   y: dotY,
                                   width: dotSize,
                                   height: dotSize)
            addSubview(dotView)
            dotViews.append(dotView)
        }
    }

    private func createNewAvatarView() {
        index += 1
        let newAvatar = UIImageView()
        newAvatar.contentMode = .scaleAspectFill
        newAvatar.alpha = 0.1
        newAvatar.loadImage(contentData: avatarImages[index % avatarImages.count])
        if let firstDot = dotViews.first {
            newAvatar.frame = firstDot.frame
        }
        newAvatar.viewCorner(radius: dotSize / 2, borderWidth: 2, borderColor: .white)
        addSubview(newAvatar)
        newAvatarView = newAvatar
    }

    public func startAnimation() {
        guard let firstAvatar = firstAvatar,
              let lastAvatar = lastAvatar else { return }

        createNewAvatarView()
        let avatarMoveX = frame.height - imageSpacingOffset

        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveLinear], animations: {
            firstAvatar.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)

            for avatar in self.centerAvatar {
                avatar.frame.origin.x -= avatarMoveX
            }
            for dot in self.dotViews {
                dot.frame.origin.x -= (self.dotSpacing * 3)
            }

            if let newAvatar = self.newAvatarView {
                newAvatar.frame = CGRect(x: lastAvatar.frame.origin.x + avatarMoveX,
                                         y: 0,
                                         width: self.frame.height,
                                         height: self.frame.height)
                newAvatar.alpha = 1
                newAvatar.viewCorner(radius: self.frame.height / 2, borderWidth: 2, borderColor: .white)
            }

        }, completion: { _ in
            firstAvatar.removeFromSuperview()
            self.firstAvatar = self.centerAvatar.first
            if !self.centerAvatar.isEmpty {
                self.centerAvatar.removeFirst()
            }
            if let newAvatar = self.newAvatarView {
                self.lastAvatar = newAvatar
                self.centerAvatar.append(newAvatar)
            }

            for dot in self.dotViews {
                dot.frame.origin.x += (self.dotSpacing * 3)
            }

            PTGCDManager.gcdAfter(time: 0.6) {
                self.startAnimation()
            }
        })
    }
}
