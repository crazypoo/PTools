//
//  DOInvertedTextView.swift
//  Diou
//
//  Created by ken lam on 2021/8/7.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

public class PTInvertedTextView: UITextView {

    public var pendingOffsetChange = false
    
    // Thanks to WWDC21 Lab!
    public override func layoutSubviews() {
        super.layoutSubviews()

        if panGestureRecognizer.numberOfTouches == 0 && pendingOffsetChange {
            contentOffset.y = contentSize.height - bounds.size.height
        } else {
            pendingOffsetChange = false
        }
    }
    
    public var cancelNextContentSizeDidSet = false
    
    public override var contentSize: CGSize {
        didSet {
            cancelNextContentSizeDidSet = true
            
            if contentSize.height < bounds.size.height {
                contentInset.top = bounds.size.height - contentSize.height
            } else {
                contentInset.top = 0
            }
        }
    }
}
