//
//  PTBadgeProtocol.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/28.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

public let kBadgeScaleAniKey = "scale"
public let kBadgeBreatheAniKey = "breathe"
public let kBadgeRotateAniKey = "rotate"
public let kBadgeShakeAniKey = "shake"
public let kBadgeBounceAniKey = "bounce"

public let kPTBAdgeDefaultRedDotRadius:CGFloat = 4
public let kPTBAdgeDefaultMaximumBadgeNumber:Int = 99

public enum PTBadgeStyle:Int {
    case RedDot
    case Number
    case New
}

public enum PTBadgeAnimType {
    case None
    case Scale
    case Shake
    case Bounce
    case Breathe
}

public struct PTBadgeAssociatedKeys {
    static var badgeLabelKey = 990
    static var badgeBgColorKey = 991
    static var badgeFontKey = 992
    static var badgeTextColorKey = 993
    static var badgeAniTypeKey = 994
    static var badgeFrameKey = 995
    static var badgeCenterOffsetKey = 996
    static var badgeMaximumBadgeNumberKey = 997
    static var badgeRadiusKey = 998
    static var badgeCenterKey = 999
    static var badgeCenterChangeKey = 989
    static var badgeCanDragToDeleteKey = 988
    static var badgeCanDragToDeleteLongPressTimeKey = 987
}

public protocol PTBadgeProtocol {
    var badge:UILabel? { get set }
    var badgeFont:UIFont { get set }
    var badgeBgColor:UIColor { get set }
    var badgeTextColor:UIColor { get set }
    var badgeFrame:CGRect { get set }
    var badgeCenterOffset:CGPoint { get set }
    var aniType:PTBadgeAnimType { get set }
    var badgeMaximumBadgeNumber:Int { get set }
    var badgeRadius:CGFloat { get set }

    func showBadge()
    func showBadge(style:PTBadgeStyle,value: Any,aniType:PTBadgeAnimType)
    func clearBadge()
}

