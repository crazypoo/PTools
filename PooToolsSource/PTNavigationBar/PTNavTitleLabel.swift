//
//  PTNavTitleLabel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 27/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

open class PTNavTitleLabel: UILabel {
    
    public var jx_titleLabelFrameUpdateBlock:((_ titleLabel:PTNavTitleLabel)->Void)?
    
    open override var text: String? {
        didSet {
            self.noticeUpdateFrame()
        }
    }
    
    open override var attributedText: NSAttributedString? {
        didSet {
            self.noticeUpdateFrame()
        }
    }
    
    open override var font: UIFont! {
        didSet {
            self.noticeUpdateFrame()
        }
    }
    
    private func noticeUpdateFrame() {
        if self.jx_titleLabelFrameUpdateBlock != nil {
            self.jx_titleLabelFrameUpdateBlock!(self)
        }
    }
}
