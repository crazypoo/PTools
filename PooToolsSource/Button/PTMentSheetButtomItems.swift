//
//  PTMentSheetButtomItems.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/31.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public class PTMentSheetButtomItems {
    
    public typealias ActionBlock = (PTMentSheetButtomItems) -> Void
    
    // MARK: - Properties
    
    // image
    public var image: UIImage?
    public var highlightedImage: UIImage?
    
    // title
    public var attributedTitle: NSAttributedString?
    public var highlightedAttributedTitle: NSAttributedString?
    
    // insets
    public var contentEdgeInsets: UIEdgeInsets = .zero
    public var titleEdgeInsets: UIEdgeInsets = .zero
    public var imageEdgeInsets: UIEdgeInsets = .zero
    
    // width
    public var size: CGSize?
    
    // alignment
    public var titleAlignment: NSTextAlignment = .center
    
    // content mode
    public var imageContentMode: UIView.ContentMode = .scaleAspectFit
    
    // action
    public var action: ActionBlock = {_ in}
    
    // identifier
    public var identifier: String = ""
    
    // MARK: - Init
    
    public init(image: UIImage? = nil,
                highlightedImage: UIImage? = nil,
                attributedTitle: NSAttributedString? = nil,
                highlightedAttributedTitle: NSAttributedString? = nil,
                contentEdgeInsets: UIEdgeInsets = .zero,
                titleEdgeInsets: UIEdgeInsets = .zero,
                imageEdgeInsets: UIEdgeInsets = .zero,
                size: CGSize? = nil,
                titleAlignment: NSTextAlignment = .center,
                imageContentMode: UIView.ContentMode = .scaleAspectFit,
                identifier: String = "",
                action: @escaping ActionBlock = {_ in}) {
        
        self.image = image
        self.highlightedImage = highlightedImage
        self.attributedTitle = attributedTitle
        self.highlightedAttributedTitle = highlightedAttributedTitle
        self.contentEdgeInsets = contentEdgeInsets
        self.titleEdgeInsets = titleEdgeInsets
        self.imageEdgeInsets = imageEdgeInsets
        self.size = size
        self.titleAlignment = titleAlignment
        self.imageContentMode = imageContentMode
        self.identifier = identifier
        self.action = action
    }

}
