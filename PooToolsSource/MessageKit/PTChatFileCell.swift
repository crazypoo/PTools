//
//  PTChatFileCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/4/2.
//

import UIKit
import AttributedString

public class PTChatFileCell: PTChatBaseCell {
    public static let ID = "PTChatFileCell"
    public static let FileCellHeight:CGFloat = 88
    public static let FileCellImageHeight:CGFloat = 64
    public static let FileCellConentFixbel:CGFloat = 7.5
    public static let FileConentWidth:CGFloat = 250

    public var cellModel:PTChatListModel! {
        didSet {
            PTGCDManager.gcdMain {
                self.setBaseSubsViews(cellModel: self.cellModel)
                self.dataContentSets(cellModel: self.cellModel)
            }
        }
    }
    
    fileprivate lazy var fileImageView:UIImageView = {
        let view = UIImageView()
        view.image = PTChatConfig.share.fileImage
        return view
    }()
    
    fileprivate lazy var fileNameInfo:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func dataContentSets(cellModel:PTChatListModel) {
                
        userIcon.snp.remakeConstraints { make in
            make.size.equalTo(PTChatConfig.share.messageUserIconSize)
            if cellModel.belongToMe {
                make.right.equalToSuperview().inset(PTChatConfig.share.userIconFixelSpace)
            } else {
                make.left.equalToSuperview().inset(PTChatConfig.share.userIconFixelSpace)
            }
            make.top.equalTo(self.messageTimeLabel.snp.bottom).offset(PTChatBaseCell.TimeTopSpace)
        }

        senderNameLabel.snp.remakeConstraints { make in
            make.top.equalTo(self.userIcon)
            if cellModel.belongToMe {
                make.right.equalTo(self.userIcon.snp.left).offset(-PTChatBaseCell.DataContentUserIconFixel)
            } else {
                make.left.equalTo(self.userIcon.snp.right).offset(PTChatBaseCell.DataContentUserIconFixel)
            }
            
            make.height.equalTo(PTChatConfig.share.showSenderName ? PTChatBaseCell.NameHeight : 0)
        }

        if cellModel.belongToMe {
            dataContent.setBackgroundImage(PTChatConfig.share.chatMeBubbleImage.resizeImage(), for: .normal)
            dataContent.setBackgroundImage(PTChatConfig.share.chatMeHighlightedBubbleImage.resizeImage(), for: .highlighted)
        } else {
            dataContent.setBackgroundImage(PTChatConfig.share.chatOtherBubbleImage.resizeImage(), for: .normal)
            dataContent.setBackgroundImage(PTChatConfig.share.chatOtherHighlightedBubbleImage.resizeImage(), for: .highlighted)
        }
        
        var url:URL?
        if cellModel.msgContent is String {
            let contentString = cellModel.msgContent as! String
            url = URL(string: contentString)
        } else if cellModel.msgContent is URL {
            url = (cellModel.msgContent as! URL)
        }
        
        var cellHeight:CGFloat = PTChatFileCell.FileCellHeight
        if url != nil {
            let nameHeight = UIView.sizeFor(string: url!.lastPathComponent, font: PTChatConfig.share.fileNameFont,lineSpacing: PTChatConfig.share.fileContentSpace as NSNumber,width: PTChatFileCell.FileConentWidth - PTChatFileCell.FileCellImageHeight - PTChatFileCell.FileCellConentFixbel * 3).height
            let fileSizeHeight = PTChatConfig.share.fileSizeFont.pointSize + 2 + PTChatFileCell.FileCellConentFixbel * 2
            let total = nameHeight + fileSizeHeight
            if total >= cellHeight {
                cellHeight = total
            }
        }

        dataContent.snp.remakeConstraints { make in
            if cellModel.belongToMe {
                make.right.equalTo(self.userIcon.snp.left).offset(-PTChatBaseCell.DataContentUserIconFixel)
            } else {
                make.left.equalTo(self.userIcon.snp.right).offset(PTChatBaseCell.DataContentUserIconFixel)
            }
            make.top.equalTo(self.senderNameLabel.snp.bottom)
            make.height.equalTo(cellHeight)
            make.width.equalTo(PTChatFileCell.FileConentWidth)
        }
        
        dataContent.addSubviews([fileImageView,fileNameInfo])
        fileImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTChatFileCell.FileCellConentFixbel)
            make.size.equalTo(PTChatFileCell.FileCellImageHeight)
            make.centerY.equalToSuperview()
        }
                
        if url != nil {
            if FileManager.pt.judgeFileOrFolderExists(filePath: url!.absoluteString) {
                let fileSizeString = FileManager.pt.fileOrDirectorySize(path: url!.absoluteString)
                let infoAtt:ASAttributedString = """
                        \(wrap: .embedding("""
                        \(url!.lastPathComponent,.foreground(PTChatConfig.share.fileNameColor),.font(PTChatConfig.share.fileNameFont),.paragraph(.alignment(.left),.lineSpacing(PTChatConfig.share.fileContentSpace)))
                        \(fileSizeString,.foreground(PTChatConfig.share.fileSizeColor),.font(PTChatConfig.share.fileSizeFont),.paragraph(.alignment(.left),.lineSpacing(PTChatConfig.share.fileContentSpace)))
                        """))
                        """
                self.fileNameInfo.attributedText = infoAtt.value
            } else {
                url!.getFileSizeOnline { fileSize in
                    PTGCDManager.gcdMain {
                        let infoAtt:ASAttributedString = """
                                \(wrap: .embedding("""
                                \(url!.lastPathComponent,.foreground(PTChatConfig.share.fileNameColor),.font(PTChatConfig.share.fileNameFont),.paragraph(.alignment(.left),.lineSpacing(PTChatConfig.share.fileContentSpace)))
                                \(FileManager.pt.covertUInt64ToString(with: fileSize),.foreground(PTChatConfig.share.fileSizeColor),.font(PTChatConfig.share.fileSizeFont),.paragraph(.alignment(.left),.lineSpacing(PTChatConfig.share.fileContentSpace)))
                                """))
                                """
                        self.fileNameInfo.attributedText = infoAtt.value
                    }
                }
            }
        }
        
        fileNameInfo.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(PTChatFileCell.FileCellConentFixbel)
            make.top.bottom.equalToSuperview().inset(PTChatFileCell.FileCellConentFixbel)
            make.right.equalTo(self.fileImageView.snp.left).offset(-PTChatFileCell.FileCellConentFixbel)
        }
        
        waitImageView.snp.remakeConstraints { make in
            make.size.equalTo(PTChatBaseCell.WaitImageSize)
            if cellModel.belongToMe {
                make.right.equalTo(self.dataContent.snp.left).offset(-PTChatBaseCell.DataContentWaitImageFixel)
            } else {
                make.left.equalTo(self.dataContent.snp.right).offset(PTChatBaseCell.DataContentWaitImageFixel)
            }
            make.centerY.equalToSuperview()
        }
        waitImageView.addActionHandlers { sender in
            self.sendMesageError?(cellModel)
        }
        checkCellSendStatus(cellModel: cellModel)
    }    
}
