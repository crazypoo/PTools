//
//  PTChatTypingIndicatorCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/4/2.
//

import UIKit

public class PTChatTypingIndicatorCell: PTBaseNormalCell {
    static let ID = "PTChatTypingIndicatorCell"
    
    public var insets = UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0)

    public let typingBubble = PTChatTypingBubble()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
    
    open func setupSubviews() {
        contentView.addSubview(typingBubble)
        typingBubble.startAnimating()
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        if typingBubble.isAnimating {
            typingBubble.stopAnimating()
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        typingBubble.frame = bounds.inset(by: insets)
    }
}
