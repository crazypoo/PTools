//
//  PTChatSystemMessageCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/3/31.
//

import UIKit
import AttributedString
import SnapKit

@MainActor
public class PTChatSystemMessageCell: PTBaseNormalCell {
    public static let ID = "PTChatSystemMessageCell"
    
    public var cellModel:PTChatListModel! {
        didSet {
            guard let cellModel else {
                timeLabel.attributedText = nil
                return
            }
            let timeText = cellModel.messageTimeStamp.conversationTimeSet() ?? ""
            var timeAtt:ASAttributedString = """
                    \(wrap: .embedding("""
                    \(timeText,.foreground(PTChatConfig.share.chatTimeColor),.font(PTChatConfig.share.chatTimeFont),.paragraph(.alignment(.center),.lineSpacing(CGFloat(truncating: PTChatConfig.share.chatSystemTimeLineSpace))))
                    """))
                    """
            if let msgContent = cellModel.msgContent as? String,!msgContent.stringIsEmpty() {
                let contentAtt:ASAttributedString = """
                        \(wrap: .embedding("""
                        \("\n\(msgContent)",.foreground(PTChatConfig.share.chatSystemMessageColor),.font(PTChatConfig.share.chatSystemMessageFont),.paragraph(.alignment(.center),.lineSpacing(CGFloat(truncating: PTChatConfig.share.chatSystemContentLineSpace))))
                        """))
                        """
                timeAtt += contentAtt

            }
            
            timeLabel.attributedText = timeAtt.value
        }
    }
    
    lazy var timeLabel:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubviews([timeLabel])
        timeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        contentView.addSubviews([timeLabel])
        timeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
