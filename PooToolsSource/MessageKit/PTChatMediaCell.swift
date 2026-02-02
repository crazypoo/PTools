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

    public var videoCacheURL:URL? = nil
    public var loadMediaURL:URL? = nil
    public var needLoadVideo:Bool = false
    
    public var mediaPlayButtonTapCallback:PTActionTask?
    public var mediaDownloadFinishCallback:PTActionTask?

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
    
    private lazy var mediaPlayImageView: UIButton = {
        let view = UIButton(type:.custom)
        view.setImage(PTChatConfig.share.mediaPlayButton, for: .normal)
        view.isHidden = true
        return view
    }()
    
    private lazy var loadingView : PTMediaBrowserLoadingView = {
        let view = PTMediaBrowserLoadingView(type: .LoopDiagram)
        view.viewCanTap = true
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

    public var isImage:Bool {
        get {
            if let mediaString = cellModel.msgContent as? String {
                switch mediaString.nsString.contentTypeForUrl() {
                case .MOV, .MP4, .ThreeGP:
                    return false
                default:
                    return true
                }
            } else if let mediaURL = cellModel.msgContent as? URL {
                switch mediaURL.absoluteString.nsString.contentTypeForUrl() {
                case .MOV, .MP4, .ThreeGP:
                    return false
                default:
                    return true
                }
            } else if let _ = cellModel.msgContent as? AVPlayerItem {
                return false
            } else if let _ = cellModel.msgContent as? AVAsset {
                return false
            } else if let asset = cellModel.msgContent as? PHAsset {
                switch asset.mediaType {
                case .image:
                    return true
                case .video:
                    return false
                default:
                    return true
                }
            } else {
                return true
            }
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
            if let _ = cellModel.msgContent as? String {
                if self.isImage {
                    make.height.equalTo(PTChatConfig.share.imageMessageImageHeight)
                    make.width.equalTo(PTChatConfig.share.imageMessageImageWidth)
                } else {
                    make.height.equalTo(PTChatConfig.share.mediaMessageVideoHeight)
                    make.width.equalTo(PTChatConfig.share.mediaMessageVideoWidth)
                }
            } else if let _ = cellModel.msgContent as? URL {
                if self.isImage {
                    make.height.equalTo(PTChatConfig.share.imageMessageImageHeight)
                    make.width.equalTo(PTChatConfig.share.imageMessageImageWidth)
                } else {
                    make.height.equalTo(PTChatConfig.share.mediaMessageVideoHeight)
                    make.width.equalTo(PTChatConfig.share.mediaMessageVideoWidth)
                }
            } else if let _ = cellModel.msgContent as? AVPlayerItem {
                make.height.equalTo(PTChatConfig.share.mediaMessageVideoHeight)
                make.width.equalTo(PTChatConfig.share.mediaMessageVideoWidth)
            } else if let _ = cellModel.msgContent as? AVAsset {
                make.height.equalTo(PTChatConfig.share.mediaMessageVideoHeight)
                make.width.equalTo(PTChatConfig.share.mediaMessageVideoWidth)
            } else if let _ = cellModel.msgContent as? PHAsset {
                if self.isImage {
                    make.height.equalTo(PTChatConfig.share.imageMessageImageHeight)
                    make.width.equalTo(PTChatConfig.share.imageMessageImageWidth)
                } else {
                    make.height.equalTo(PTChatConfig.share.mediaMessageVideoHeight)
                    make.width.equalTo(PTChatConfig.share.mediaMessageVideoWidth)
                }
            } else {
                make.height.equalTo(PTChatConfig.share.imageMessageImageHeight)
                make.width.equalTo(PTChatConfig.share.imageMessageImageWidth)
            }
        }
    }

    private func checkAndLoadMediaContent(cellModel: PTChatListModel) {
        guard let msgContent = cellModel.msgContent else {
            self.contentImageView.image = PTAppBaseConfig.share.defaultEmptyImage
            return
        }
        checkIsVideo(msgContent: msgContent)
    }

    private func checkIsVideo(msgContent: Any) {
        if let contentString = msgContent as? String,let contentURL = URL(string: contentString.urlToUnicodeURLString() ?? "") {
            handleContentURL(contentURL)
        } else if let contentURL = msgContent as? URL {
            handleContentURL(contentURL)
        } else if let avItem = msgContent as? AVPlayerItem {
            needLoadVideo = false
            handleAVPlayerItem(avItem)
        } else if let avAsset = msgContent as? AVAsset {
            needLoadVideo = false
            handleAVAsset(avAsset)
        } else if let asset = msgContent as? PHAsset {
            handlePHAsset(asset)
        } else {
            self.contentImageView.image = PTAppBaseConfig.share.defaultEmptyImage
        }
    }

    private func handleContentURL(_ contentURL: URL) {
        if isImage {
            needLoadVideo = false
            self.mediaPlayImageView.isHidden = true
            self.mediaPlayImageView.isUserInteractionEnabled = false
            self.contentImageView.loadImage(contentData: contentURL)
        } else {
            needLoadVideo = true
            self.mediaPlayImageView.isHidden = false
            self.mediaPlayImageView.isUserInteractionEnabled = true
            videoUrlLoad(url: contentURL.absoluteString)
        }
    }

    private func handleAVPlayerItem(_ avItem: AVPlayerItem) {
        self.mediaPlayImageView.isHidden = false
        self.mediaPlayImageView.isUserInteractionEnabled = true
        avItem.generateThumbnail { [weak self] image in
            guard let self = self else { return }
            self.contentImageView.image = image ?? PTAppBaseConfig.share.defaultEmptyImage
        }
    }

    private func handleAVAsset(_ avAsset: AVAsset) {
        self.mediaPlayImageView.isHidden = false
        self.mediaPlayImageView.isUserInteractionEnabled = true
        let avPlayerItem = AVPlayerItem(asset: avAsset)
        handleAVPlayerItem(avPlayerItem)
    }

    private func handlePHAsset(_ asset: PHAsset) {
        self.mediaPlayImageView.isHidden = true
        self.mediaPlayImageView.isUserInteractionEnabled = false
        self.contentImageView.loadImage(contentData: asset)
    }

    private func videoUrlLoad(url: String) {
        PTVideoCoverCache.getVideoFirstImage(videoUrl: url) { image in
            PTGCDManager.gcdMain {
                self.contentImageView.image = image ?? PTAppBaseConfig.share.defaultEmptyImage
            }
        }
        
        if let urlSave = URL(string: url) {
            loadMediaURL = urlSave
            self.videoCacheURL = PTVideoFileCache.shared.cachedFileURL(for: urlSave)
        }
        
        mediaPlayButtonImageSet()
        
        mediaPlayImageView.addActionHandlers { sender in
            if let _ = self.videoCacheURL {
                self.mediaPlayButtonTapCallback?()
            } else {
                if let urlReal = URL(string: url) {
                    self.mediaDownloadFunction(urlReal: urlReal)
                }
            }
        }
    }
    
    public func mediaDownloadFunction(urlReal:URL) {
        self.loadingView.hubTapCallback = {
            self.loadingView.removeFromSuperview()
            self.mediaPlayImageView.setImage(PTChatConfig.share.mediaDownloadPauseImage, for: .normal)
            Network.share.suspend(fileUrl: urlReal.absoluteString)
        }
        dataContent.addSubviews([loadingView])
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        PTVideoFileCache.shared.prepareVideo(url: urlReal,progress: { _, _, progress in
            self.loadingView.progress = progress
        }, completion: { localURL in
            self.loadingView.removeFromSuperview()
            self.videoCacheURL = localURL
            self.mediaPlayButtonImageSet()
            self.mediaDownloadFinishCallback?()
        })
    }
    
    func mediaPlayButtonImageSet() {
        if let _ = self.videoCacheURL {
            mediaPlayImageView.setImage(PTChatConfig.share.mediaPlayButton, for: .normal)
        } else {
            mediaPlayImageView.setImage(PTChatConfig.share.mediaDownloadImage, for: .normal)
        }
    }
}
