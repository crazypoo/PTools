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
import SwifterSwift

public class PTChatMediaCell: PTChatBaseCell {
    public static let ID = "PTChatMediaCell"

    public var cellModel: PTChatListModel! {
        didSet {
            self.updateCellModel(cellModel: self.cellModel)
        }
    }
    
    // 使用懒加载避免不必要的初始化
    private lazy var contentImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.viewCorner(radius: PTChatConfig.share.imageMessageImageCorner) // 提前设置圆角
        return view
    }()
    
    private lazy var mediaPlayImageView: UIImageView = {
        let view = UIImageView()
        view.image = PTChatConfig.share.mediaPlayButton
        view.isHidden = true
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews() // 提前设置视图层次结构和约束
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 提前设置约束，避免每次都重新设置
    private func setupSubviews() {
        dataContent.addSubviews([contentImageView, mediaPlayImageView])
        
        contentImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        mediaPlayImageView.snp.makeConstraints { make in
            make.size.equalTo(PTChatConfig.share.mediaPlayButtonSize)
            make.centerX.centerY.equalToSuperview()
        }
    }

    private func updateCellModel(cellModel: PTChatListModel) {
        // 避免每次调用时都重新设置视图属性，提前配置
        PTGCDManager.gcdMain {
            self.setBaseSubviews(cellModel: self.cellModel)
            self.updateConstraintsForCellModel(cellModel)
            self.checkAndLoadMediaContent(cellModel: cellModel)
        }
    }

    private func updateConstraintsForCellModel(_ cellModel: PTChatListModel) {
        dataContent.snp.remakeConstraints { make in
            if cellModel.belongToMe {
                make.right.equalTo(self.userIcon.snp.left).offset(-PTChatBaseCell.dataContentUserIconInset)
            } else {
                make.left.equalTo(self.userIcon.snp.right).offset(PTChatBaseCell.dataContentUserIconInset)
            }
            make.top.equalTo(self.senderNameLabel.snp.bottom)
            if let mediaString = cellModel.msgContent as? String {
                switch mediaString.nsString.contentTypeForUrl() {
                case .MOV, .MP4, .ThreeGP:
                    make.height.equalTo(PTChatConfig.share.mediaMessageVideoHeight)
                    make.width.equalTo(PTChatConfig.share.mediaMessageVideoWidth)
                default:
                    make.height.equalTo(PTChatConfig.share.imageMessageImageHeight)
                    make.width.equalTo(PTChatConfig.share.imageMessageImageWidth)
                }
            } else if let mediaURL = cellModel.msgContent as? URL {
                switch mediaURL.absoluteString.nsString.contentTypeForUrl() {
                case .MOV, .MP4, .ThreeGP:
                    make.height.equalTo(PTChatConfig.share.mediaMessageVideoHeight)
                    make.width.equalTo(PTChatConfig.share.mediaMessageVideoWidth)
                default:
                    make.height.equalTo(PTChatConfig.share.imageMessageImageHeight)
                    make.width.equalTo(PTChatConfig.share.imageMessageImageWidth)
                }
            } else if let _ = cellModel.msgContent as? AVPlayerItem {
                make.height.equalTo(PTChatConfig.share.mediaMessageVideoHeight)
                make.width.equalTo(PTChatConfig.share.mediaMessageVideoWidth)
            } else if let _ = cellModel.msgContent as? AVAsset {
                make.height.equalTo(PTChatConfig.share.mediaMessageVideoHeight)
                make.width.equalTo(PTChatConfig.share.mediaMessageVideoWidth)
            } else if let asset = cellModel.msgContent as? PHAsset {
                switch asset.mediaType {
                case .image:
                    make.height.equalTo(PTChatConfig.share.imageMessageImageHeight)
                    make.width.equalTo(PTChatConfig.share.imageMessageImageWidth)
                case .video:
                    make.height.equalTo(PTChatConfig.share.mediaMessageVideoHeight)
                    make.width.equalTo(PTChatConfig.share.mediaMessageVideoWidth)
                default:
                    make.height.equalTo(PTChatConfig.share.mediaMessageVideoHeight)
                    make.width.equalTo(PTChatConfig.share.mediaMessageVideoWidth)
                }
            }
        }
    }

    private func checkAndLoadMediaContent(cellModel: PTChatListModel) {
        guard let msgContent = cellModel.msgContent else { return }
        checkIsVideo(msgContent: msgContent)
    }

    private func checkIsVideo(msgContent: Any) {
        if let contentString = msgContent as? String {
            handleContentString(contentString)
        } else if let contentURL = msgContent as? URL {
            handleContentURL(contentURL)
        } else if let avItem = msgContent as? AVPlayerItem {
            handleAVPlayerItem(avItem)
        } else if let avAsset = msgContent as? AVAsset {
            handleAVAsset(avAsset)
        } else if let asset = msgContent as? PHAsset {
            handlePHAsset(asset)
        }
    }

    private func handleContentString(_ contentString: String) {
        switch contentString.nsString.contentTypeForUrl() {
        case .MOV, .MP4, .ThreeGP:
            self.mediaPlayImageView.isHidden = false
            videoUrlLoad(url: contentString.urlToUnicodeURLString() ?? "")
        default:
            self.mediaPlayImageView.isHidden = true
            self.contentImageView.loadImage(contentData: contentString.urlToUnicodeURLString() ?? "")
        }
    }

    private func handleContentURL(_ contentURL: URL) {
        switch contentURL.pathExtension.nsString.contentTypeForUrl() {
        case .MOV, .MP4, .ThreeGP:
            self.mediaPlayImageView.isHidden = false
            videoUrlLoad(url: contentURL.absoluteString)
        default:
            self.mediaPlayImageView.isHidden = true
            self.contentImageView.loadImage(contentData: contentURL)
        }
    }

    private func handleAVPlayerItem(_ avItem: AVPlayerItem) {
        self.mediaPlayImageView.isHidden = false
        avItem.generateThumbnail { [weak self] image in
            guard let self = self else { return }
            self.contentImageView.image = image ?? PTAppBaseConfig.share.defaultEmptyImage
        }
    }

    private func handleAVAsset(_ avAsset: AVAsset) {
        self.mediaPlayImageView.isHidden = false
        let avPlayerItem = AVPlayerItem(asset: avAsset)
        handleAVPlayerItem(avPlayerItem)
    }

    private func handlePHAsset(_ asset: PHAsset) {
        self.mediaPlayImageView.isHidden = true
        self.contentImageView.loadImage(contentData: asset)
    }

    private func videoUrlLoad(url: String) {
        PTVideoCoverCache.getVideoFirstImage(videoUrl: url) { image in
            PTGCDManager.gcdMain {
                self.contentImageView.image = image ?? PTAppBaseConfig.share.defaultEmptyImage
            }
        }
        
        if let urlReal = URL(string: url) {
            PTVideoFileCache.shared.prepareVideo(url: urlReal, completion: { _ in })
        }
    }
}
