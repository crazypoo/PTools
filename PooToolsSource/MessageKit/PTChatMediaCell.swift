//
//  PTChatMediaCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/4/1.
//

import UIKit
import AVFoundation
import SnapKit
import Photos

public class PTChatMediaCell: PTChatBaseCell {
    public static let ID = "PTChatMediaCell"

    public var cellModel:PTChatListModel! {
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
        
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func dataContentSets(cellModel:PTChatListModel) {
                
        contentImageView.viewCorner(radius: PTChatConfig.share.imageMessageImageCorner)
        dataContent.viewCorner(radius: PTChatConfig.share.imageMessageImageCorner)
        dataContent.snp.remakeConstraints { make in
            if cellModel.belongToMe {
                make.right.equalTo(self.userIcon.snp.left).offset(-PTChatBaseCell.dataContentUserIconInset)
            } else {
                make.left.equalTo(self.userIcon.snp.right).offset(PTChatBaseCell.dataContentUserIconInset)
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

        resetSubsFrame(cellModel: cellModel)
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
                videoUrlLoad(url: contentURL.absoluteString)
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
        } else if msgContent is PHAsset {
            self.mediaPlayImageView.isHidden = true
            let asset = msgContent as! PHAsset
            self.contentImageView.loadImage(contentData: asset)
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
