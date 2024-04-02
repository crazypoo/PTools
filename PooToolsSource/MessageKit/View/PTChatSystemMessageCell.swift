//
//  PTChatSystemMessageCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/3/31.
//

import UIKit
import AttributedString

class PTChatSystemMessageCell: PTBaseNormalCell {
    static let ID = "PTChatSystemMessageCell"
    
    var cellModel:PTChatListModel! {
        didSet {
            var timeAtt:ASAttributedString = """
                    \(wrap: .embedding("""
                    \(cellModel.messageTimeStamp.conversationTimeSet()!,.foreground(PTChatConfig.share.chatTimeColor),.font(PTChatConfig.share.chatTimeFont),.paragraph(.alignment(.center),.lineSpacing(CGFloat(truncating: PTChatConfig.share.chatSystemTimeLineSpace))))
                    """))
                    """
            if cellModel.msgContent is String {
                let msgContent = cellModel.msgContent as! String
                if !msgContent.stringIsEmpty() {
                    let contentAtt:ASAttributedString = """
                            \(wrap: .embedding("""
                            \("\n\(msgContent)",.foreground(PTChatConfig.share.chatSystemMessageColor),.font(PTChatConfig.share.chatSystemMessageFont),.paragraph(.alignment(.center),.lineSpacing(CGFloat(truncating: PTChatConfig.share.chatSystemContentLineSpace))))
                            """))
                            """
                    timeAtt += contentAtt
                }
            }
            
            timeLabel.attributedText = timeAtt.value
        }
    }
    
    lazy var timeLabel:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubviews([timeLabel])
        timeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
