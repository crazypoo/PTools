//
//  PTChatMediaCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/4/1.
//

import UIKit
import AVFoundation

class PTChatMediaCell: PTChatBaseCell {
    static let ID = "PTChatMediaCell"

    var cellModel:PTChatListModel! {
        didSet {
            PTGCDManager.gcdMain {
                self.setBaseSubsViews(cellModel: self.cellModel)
                self.dataContentSets(cellModel: self.cellModel)
            }
        }
    }
    
    lazy var contentImageView:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    lazy var mediaPlayImageView:UIImageView = {
        let view = UIImageView()
        view.image = PTChatConfig.share.mediaPlayButton
        view.isHidden = true
        return view
    }()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func dataContentSets(cellModel:PTChatListModel) {
                
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

        contentImageView.viewCorner(radius: PTChatConfig.share.imageMessageImageCorner)
        dataContent.viewCorner(radius: PTChatConfig.share.imageMessageImageCorner)
        dataContent.snp.remakeConstraints { make in
            if cellModel.belongToMe {
                make.right.equalTo(self.userIcon.snp.left).offset(-PTChatBaseCell.DataContentUserIconFixel)
            } else {
                make.left.equalTo(self.userIcon.snp.right).offset(PTChatBaseCell.DataContentUserIconFixel)
            }
            make.top.equalTo(self.senderNameLabel.snp.bottom)
            make.height.equalTo(PTChatConfig.share.imageMessageImageHeight)
            make.width.equalTo(PTChatConfig.share.imageMessageImageWidth)
        }
        dataContent.addSubviews([contentImageView,mediaPlayImageView])
        contentImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        mediaPlayImageView.snp.makeConstraints({ make in
            make.size.equalTo(34)
            make.centerX.centerY.equalToSuperview()
        })
        
        if cellModel.msgContent != nil {
            checkIsVideo(msgContent: cellModel.msgContent)
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
    
    func checkIsVideo(msgContent:Any?) {
        if msgContent is String {
            let contentString = msgContent as! String
            switch contentString.nsString.contentTypeForUrl() {
            case .MOV,.MP4,.ThreeGP:
                self.mediaPlayImageView.isHidden = false
                videoUrlLoad(url: contentString)
            default:
                self.mediaPlayImageView.isHidden = true
                self.contentImageView.loadImage(contentData: contentString)
            }
        } else if msgContent is URL {
            let contentURL = msgContent as! URL
            switch contentURL.pathExtension.nsString.contentTypeForUrl() {
            case .MOV,.MP4,.ThreeGP:
                self.mediaPlayImageView.isHidden = false
                videoUrlLoad(url: contentURL.description)
            default:
                self.mediaPlayImageView.isHidden = true
                self.contentImageView.loadImage(contentData: contentURL)
            }
        } else if msgContent is AVPlayerItem {
            self.mediaPlayImageView.isHidden = false
            let avItem  = msgContent as! AVPlayerItem
            videoAVItem(avItem: avItem)
        } else if msgContent is AVAsset {
            self.mediaPlayImageView.isHidden = false
            let avAsset  = msgContent as! AVAsset
            let avPlayerItem = AVPlayerItem(asset: avAsset)
            videoAVItem(avItem: avPlayerItem)
        }
    }

    func videoAVItem(avItem:AVPlayerItem) {
        avItem.generateThumbnail { image in
            if image != nil {
                self.contentImageView.image = image
            } else {
                self.contentImageView.image = PTAppBaseConfig.share.defaultEmptyImage
            }
        }
    }

    func videoUrlLoad(url:String) {
        UIImage.pt.getVideoFirstImage(videoUrl: url, closure: { image in
            if image == nil {
                self.contentImageView.image = PTAppBaseConfig.share.defaultEmptyImage
            } else {
                self.contentImageView.image = image
            }
        })
    }
}
