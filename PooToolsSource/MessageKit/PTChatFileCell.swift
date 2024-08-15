//
//  PTChatFileCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/4/2.
//

import UIKit
import AttributedString
import SnapKit

public class PTChatFileCell: PTChatBaseCell {
    public static let ID = "PTChatFileCell"
    public static let FileCellHeight: CGFloat = 88
    public static let FileCellImageHeight: CGFloat = 64
    public static let FileCellConentFixbel: CGFloat = 7.5
    public static let FileConentWidth: CGFloat = 250

    public var cellModel: PTChatListModel! {
        didSet {
            PTGCDManager.gcdMain {
                self.setBaseSubviews(cellModel: self.cellModel)
                self.dataContentSets(cellModel: self.cellModel)
            }
        }
    }
    
    fileprivate lazy var fileImageView: UIImageView = {
        let view = UIImageView()
        view.image = PTChatConfig.share.fileImage
        return view
    }()
    
    fileprivate lazy var fileNameInfo: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    // 提前设置视图和约束，避免重复添加子视图
    private func setupSubviews() {
        dataContent.addSubviews([fileImageView, fileNameInfo])

        fileImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTChatFileCell.FileCellConentFixbel)
            make.size.equalTo(PTChatFileCell.FileCellImageHeight)
            make.centerY.equalToSuperview()
        }

        fileNameInfo.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(PTChatFileCell.FileCellConentFixbel)
            make.top.bottom.equalToSuperview().inset(PTChatFileCell.FileCellConentFixbel)
            make.right.equalTo(fileImageView.snp.left).offset(-PTChatFileCell.FileCellConentFixbel)
        }
    }

    fileprivate func dataContentSets(cellModel: PTChatListModel) {
        // 选择不同的气泡背景
        let config = PTChatConfig.share
        if cellModel.belongToMe {
            dataContentStatusView.setBackgroundImage(config.chatMeBubbleImage.resizeImage(), for: .normal)
            dataContentStatusView.setBackgroundImage(config.chatMeHighlightedBubbleImage.resizeImage(), for: .highlighted)
        } else {
            dataContentStatusView.setBackgroundImage(config.chatOtherBubbleImage.resizeImage(), for: .normal)
            dataContentStatusView.setBackgroundImage(config.chatOtherHighlightedBubbleImage.resizeImage(), for: .highlighted)
        }

        // 处理URL
        guard let url = extractURL(from: cellModel.msgContent) else { return }

        // 计算动态高度
        var cellHeight: CGFloat = PTChatFileCell.FileCellHeight
        let nameHeight = UIView.sizeFor(
            string: url.lastPathComponent,
            font: config.fileNameFont,
            lineSpacing: config.fileContentSpace as NSNumber,
            width: PTChatFileCell.FileConentWidth - PTChatFileCell.FileCellImageHeight - PTChatFileCell.FileCellConentFixbel * 3
        ).height
        let fileSizeHeight = config.fileSizeFont.pointSize + 2 + PTChatFileCell.FileCellConentFixbel * 2
        cellHeight = max(cellHeight, nameHeight + fileSizeHeight)

        dataContent.snp.remakeConstraints { make in
            if cellModel.belongToMe {
                make.right.equalTo(userIcon.snp.left).offset(-PTChatBaseCell.dataContentUserIconInset)
            } else {
                make.left.equalTo(userIcon.snp.right).offset(PTChatBaseCell.dataContentUserIconInset)
            }
            make.top.equalTo(senderNameLabel.snp.bottom)
            make.height.equalTo(cellHeight)
            make.width.equalTo(PTChatFileCell.FileConentWidth)
        }

        // 更新文件信息
        updateFileInfo(with: url)
        resetSubviewsFrame(cellModel: cellModel)
    }

    // 从 msgContent 中提取 URL
    private func extractURL(from content: Any?) -> URL? {
        if let contentString = content as? String {
            return URL(string: contentString)
        } else if let contentURL = content as? URL {
            return contentURL
        }
        return nil
    }

    // 更新文件信息
    private func updateFileInfo(with url: URL) {
        if FileManager.pt.judgeFileOrFolderExists(filePath: url.absoluteString) {
            // 本地文件
            let fileSizeString = FileManager.pt.fileOrDirectorySize(path: url.absoluteString)
            setFileInfo(name: url.lastPathComponent, size: fileSizeString)
        } else {
            // 在线文件大小
            url.getFileSizeOnline { fileSize in
                PTGCDManager.gcdMain {
                    let fileSizeString = FileManager.pt.covertUInt64ToString(with: fileSize)
                    self.setFileInfo(name: url.lastPathComponent, size: fileSizeString)
                }
            }
        }
    }

    // 设置文件信息的富文本
    private func setFileInfo(name: String, size: String) {
        let config = PTChatConfig.share
        let infoAtt: ASAttributedString = """
        \(wrap: .embedding("""
        \(name, .foreground(config.fileNameColor), .font(config.fileNameFont), .paragraph(.alignment(.left), .lineSpacing(config.fileContentSpace)))
        \(size, .foreground(config.fileSizeColor), .font(config.fileSizeFont), .paragraph(.alignment(.left), .lineSpacing(config.fileContentSpace)))
        """))
        """
        self.fileNameInfo.attributedText = infoAtt.value
    }
}
