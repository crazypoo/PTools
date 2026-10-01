//
//  PTNetworkWatchCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
#if canImport(PToolsUIFoundation)
import PToolsUIFoundation
#endif

// MARK: - 抓包主列表展示 Cell
class PTNetworkWatcherCell: PTBaseNormalCell {
    static let ID = "PTNetworkWatchCell"
    
    lazy var codeLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .right
        view.font = .appfont(size: 18)
        return view
    }()
    
    lazy var infoLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    var summary: PTNetworkCaptureSummary? {
        didSet {
            guard let summary else {
                codeLabel.text = nil
                infoLabel.attributedText = nil
                return
            }
            let successColor: UIColor = summary.isSuccessful ? .systemGreen : .systemRed
            codeLabel.textColor = successColor
            codeLabel.text = summary.statusCode.map(String.init) ?? "—"

            let att: PTRichText = """
            \(wrap: .embedding("""
            \("[\(summary.method)]", .foreground(.gray), .font(.appfont(size: 17)), .paragraph(.alignment(.left))) \(summary.completion?.rawValue ?? "pending", .foreground(successColor), .font(.appfont(size: 12)), .paragraph(.alignment(.left)))
            \("#\(summary.sequence)", .foreground(successColor), .font(.appfont(size: 18)), .paragraph(.alignment(.left))) \(summary.url.absoluteString, .foreground(.gray), .font(.appfont(size: 13)), .paragraph(.alignment(.left)))
            """))
            """
            infoLabel.attributedText = att.value
        }
    }

    // English: Render the legacy detail model without routing through the deprecated list property.
    // Español: Renderiza el modelo heredado de detalle sin pasar por la propiedad obsoleta de la lista.
    // 中文：详情页使用旧模型时直接渲染，避免经过已弃用的列表属性。
    func configure(legacyModel: PTHttpModel) {
        let successColor: UIColor = legacyModel.isSuccess ? .systemGreen : .systemRed
        codeLabel.textColor = successColor
        codeLabel.text = legacyModel.statusCode
        let att: PTRichText = """
        \(wrap: .embedding("""
        \("[\(legacyModel.method ?? "")]", .foreground(.gray), .font(.appfont(size: 17)), .paragraph(.alignment(.left))) \(legacyModel.startTime ?? "", .foreground(successColor), .font(.appfont(size: 12)), .paragraph(.alignment(.left)))
        \(legacyModel.id, .foreground(successColor), .font(.appfont(size: 18)), .paragraph(.alignment(.left))) \(legacyModel.url?.absoluteString ?? "", .foreground(.gray), .font(.appfont(size: 13)), .paragraph(.alignment(.left)))
        """))
        """
        infoLabel.attributedText = att.value
    }

    @available(*, deprecated, message: "Use summary so the list does not retain full request and response bodies.")
    var cellModel: PTHttpModel? {
        didSet {
            guard let cellModel else {
                summary = nil
                return
            }
            configure(legacyModel: cellModel)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubviews([codeLabel, infoLabel])
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

// MARK: - 详情页长文本支持搜索高亮的 Cell
class PTNetworkWatcherDetailCell: PTBaseNormalCell {
    static let ID = "PTNetworkWatcherDetailCell"
        
    lazy var details: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        textView.isScrollEnabled = false
        textView.textColor = .gray
        textView.backgroundColor = .clear
        textView.isSelectable = true
        textView.isEditable = false
        return textView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
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
        guard let searched = searched, !searched.isEmpty else { return }

        let attributedString = NSMutableAttributedString(string: description)
        let highlightedWords = searched.lowercased().components(separatedBy: " ")
        let fullRange = NSRange(location: 0, length: (description as NSString).length)

        attributedString.addAttribute(.foregroundColor, value: UIColor.gray, range: fullRange)

        for word in highlightedWords {
            var searchRange = fullRange
            while searchRange.location != NSNotFound {
                searchRange = (description as NSString).range(of: word, options: .caseInsensitive, range: searchRange)
                if searchRange.location != NSNotFound {
                    attributedString.addAttribute(.foregroundColor, value: UIColor.randomColor, range: searchRange)
                    attributedString.addAttribute(.backgroundColor, value: UIColor.yellow, range: searchRange)
                    attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 14), range: searchRange)

                    let newLocation = searchRange.location + searchRange.length
                    searchRange = NSRange(location: newLocation, length: (description as NSString).length - newLocation)
                }
            }
        }
        details.attributedText = attributedString
    }
}
