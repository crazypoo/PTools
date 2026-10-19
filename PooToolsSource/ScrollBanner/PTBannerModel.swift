//
//  PTBannerModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/3/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
#if SWIFT_PACKAGE
import ptools
#endif
#if canImport(PToolsUIFoundation)
import PToolsUIFoundation
#endif

public class PTBannerModel: NSObject {
    /// English: Stable identity used by the PTCollectionView-backed banner projection.
    /// Español: Identidad estable utilizada por la proyección del banner respaldada por PTCollectionView.
    /// 中文：由 PTCollectionView 驱动的 Banner 投影使用的稳定身份。
    public let identifier: String = UUID().uuidString
    open var media:Any?
    open var title:String = ""
    open var desc:String = ""
    open var att:PTRichText?
    // MARK: Title
    /// 字体颜色
    open var titleColor: UIColor = UIColor.white
    open var descColor: UIColor = UIColor.white
    /// 字体
    open var titleFont: UIFont = UIFont.systemFont(ofSize: 15)
    open var descFont: UIFont = UIFont.systemFont(ofSize: 15)
    open var titleLineSpacing:CGFloat = 1.5
    open var imageViewContentMode: UIView.ContentMode = .scaleAspectFit
    open var cellCornerRadius: CGFloat = 0
    open var corner:UIRectCorner = .allCorners
    public var cachedDescHeight: CGFloat?
}
