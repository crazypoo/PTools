//
//  PTNetworkWatchCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import AttributedString

class PTNetworkWatcherCell: PTBaseNormalCell {
    static let ID = "PTNetworkWatchCell"
    
    lazy var codeLabel:UILabel = {
        let view = UILabel()
        view.textAlignment = .right
        view.font = .appfont(size: 18)
        return view
    }()
    
    lazy var infoLabel:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    var cellModel:PTHttpModel! {
        didSet {
            var successColor:UIColor = .clear
            if cellModel.isSuccess {
                successColor = .systemGreen
            } else {
                successColor = .systemRed
            }
            codeLabel.textColor = successColor
            codeLabel.text = cellModel.statusCode
            
            let att:ASAttributedString = """
            \(wrap: .embedding("""
            \("[\(cellModel.method ?? "")]",.foreground(.gray),.font(.appfont(size: 17)),.paragraph(.alignment(.left))) \(cellModel.startTime ?? "",.foreground(successColor),.font(.appfont(size: 12)),.paragraph(.alignment(.left)))
            \(cellModel.id,.foreground(successColor),.font(.appfont(size: 18)),.paragraph(.alignment(.left))) \(cellModel.url?.absoluteString ?? "",.foreground(.gray),.font(.appfont(size: 13)),.paragraph(.alignment(.left)))
            """))
            """
            infoLabel.attributedText = att.value
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        
        contentView.addSubviews([codeLabel,infoLabel])
        codeLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.centerY.equalToSuperview()
        }
        
        infoLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.bottom.equalToSuperview()
            make.right.equalTo(self.codeLabel.snp.left).offset(-5)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PTNetworkWatcherDetailCell: PTBaseNormalCell {
    static let ID = "PTNetworkWatcherDetailCell"
        
    lazy var details: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(
            ofSize: 12,
            weight: .medium
        )
        textView.isScrollEnabled = false

        textView.textColor = .gray
        textView.backgroundColor = .clear
        textView.isSelectable = true
        textView.isEditable = false

        return textView
    }()

    override init(frame: CGRect) {
        super.init(frame:frame)
        
        contentView.addSubviews([details])
        details.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.bottom.equalToSuperview()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup(_ description: String, _ searched: String?) {
        details.text = description

        setupHighlighted(description, searched)
    }

    private func setupHighlighted(_ description: String, _ searched: String?) {
        guard let searched, !searched.isEmpty else {
            return
        }

        let attributedString = NSMutableAttributedString(string: description)
        let highlightedWords = searched.lowercased().components(separatedBy: " ")
        let fullRange = NSRange(location: 0, length: (description as NSString).length)

        attributedString.addAttribute(.foregroundColor, value: UIColor.gray, range: fullRange)

        for word in highlightedWords {
            var searchRange = fullRange
            while searchRange.location != NSNotFound {
                searchRange = (description as NSString).range(
                    of: word,
                    options: .caseInsensitive,
                    range: searchRange
                )

                if searchRange.location != NSNotFound {
                    attributedString.addAttribute(.foregroundColor, value: UIColor.randomColor, range: searchRange)
                    attributedString.addAttribute(.backgroundColor, value: UIColor.yellow, range: searchRange)
                    attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 14), range: searchRange)

                    searchRange = NSRange(
                        location: searchRange.location + searchRange.length,
                        length: (description as NSString).length - (searchRange.location + searchRange.length)
                    )
                }
            }
        }

        details.attributedText = attributedString
    }

}
