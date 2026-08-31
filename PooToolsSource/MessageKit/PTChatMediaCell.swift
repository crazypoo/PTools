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

@MainActor
public class PTChatMediaCell: PTChatBaseCell {
    public static let ID = "PTChatMediaCell"

    public var videoCacheURL:URL? = nil
    public var loadMediaURL:URL? = nil
    public var needLoadVideo:Bool = false
    
    public var mediaPlayButtonTapCallback:PTActionTask?
    public var mediaDownloadFinishCallback:PTActionTask?

    private var loadGeneration = 0
    private var thumbnailTask: Task<Void, Never>?

    public var cellModel: PTChatListModel! {
        didSet {
            guard let cellModel else { return }
            updateCellModel(cellModel: cellModel)
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
        super.init(coder: coder)
        setupSubviews()
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        loadGeneration += 1
        thumbnailTask?.cancel()
        thumbnailTask = nil
        contentImageView.cancelImageLoad()
        contentImageView.image = PTAppBaseConfig.share.defaultEmptyImage
        mediaPlayImageView.removeTargerAndAction()
        mediaPlayImageView.isHidden = true
        mediaPlayImageView.isUserInteractionEnabled = false
        loadingView.removeFromSuperview()
        videoCacheURL = nil
        loadMediaURL = nil
        needLoadVideo = false
        mediaPlayButtonTapCallback = nil
        mediaDownloadFinishCallback = nil
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
        loadGeneration += 1
        thumbnailTask?.cancel()
        thumbnailTask = nil
        contentImageView.cancelImageLoad()
        contentImageView.image = PTAppBaseConfig.share.defaultEmptyImage
        mediaPlayImageView.removeTargerAndAction()
        mediaPlayImageView.isHidden = true
        mediaPlayImageView.isUserInteractionEnabled = false
        loadingView.removeFromSuperview()
        videoCacheURL = nil
        loadMediaURL = nil
        needLoadVideo = false
        setBaseSubviews(cellModel: cellModel)
        updateConstraintsForCellModel(cellModel)
        checkAndLoadMediaContent(cellModel: cellModel, generation: loadGeneration)
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

    private func checkAndLoadMediaContent(cellModel: PTChatListModel, generation: Int) {
        guard let msgContent = cellModel.msgContent else {
            self.contentImageView.image = PTAppBaseConfig.share.defaultEmptyImage
            return
        }
        checkIsVideo(msgContent: msgContent, generation: generation)
    }

    private func checkIsVideo(msgContent: Any, generation: Int) {
        if let contentString = msgContent as? String,let contentURL = URL(string: contentString.urlToUnicodeURLString() ?? "") {
            handleContentURL(contentURL, generation: generation)
        } else if let contentURL = msgContent as? URL {
            handleContentURL(contentURL, generation: generation)
        } else if let avItem = msgContent as? AVPlayerItem {
            needLoadVideo = false
            handleAVPlayerItem(avItem, generation: generation)
        } else if let avAsset = msgContent as? AVAsset {
            needLoadVideo = false
            handleAVAsset(avAsset, generation: generation)
        } else if let asset = msgContent as? PHAsset {
            handlePHAsset(asset)
        } else {
            self.contentImageView.image = PTAppBaseConfig.share.defaultEmptyImage
        }
    }

    private func handleContentURL(_ contentURL: URL, generation: Int) {
        if isImage {
            needLoadVideo = false
            self.mediaPlayImageView.isHidden = true
            self.mediaPlayImageView.isUserInteractionEnabled = false
            self.contentImageView.loadImage(contentData: contentURL,
                                             loadFinish: { [weak self] _ in
                                                 guard let self, self.loadGeneration == generation else { return }
                                             })
        } else {
            needLoadVideo = true
            self.mediaPlayImageView.isHidden = false
            self.mediaPlayImageView.isUserInteractionEnabled = true
            videoUrlLoad(url: contentURL.absoluteString, generation: generation)
        }
    }

    private func handleAVPlayerItem(_ avItem: AVPlayerItem, generation: Int) {
        self.mediaPlayImageView.isHidden = false
        self.mediaPlayImageView.isUserInteractionEnabled = true
        avItem.generateThumbnail(maximumSize: CGSize(width: PTChatConfig.share.mediaMessageVideoWidth,
                                                     height: PTChatConfig.share.mediaMessageVideoHeight)) { [weak self] image in
            PTMainActorBridge.perform { [weak self] in
                guard let self, self.loadGeneration == generation else { return }
                self.contentImageView.image = image ?? PTAppBaseConfig.share.defaultEmptyImage
            }
        }
    }

    private func handleAVAsset(_ avAsset: AVAsset, generation: Int) {
        self.mediaPlayImageView.isHidden = false
        self.mediaPlayImageView.isUserInteractionEnabled = true
        thumbnailTask = Task { @MainActor [weak self] in
            let image = await PTVideoThumbnailService.image(
                for: avAsset,
                frameNumber: 1,
                maximumSize: CGSize(width: PTChatConfig.share.mediaMessageVideoWidth,
                                    height: PTChatConfig.share.mediaMessageVideoHeight)
            )
            guard !Task.isCancelled,
                  let self,
                  self.loadGeneration == generation else { return }
            self.contentImageView.image = image ?? PTAppBaseConfig.share.defaultEmptyImage
            self.thumbnailTask = nil
        }
    }

    private func handlePHAsset(_ asset: PHAsset) {
        self.mediaPlayImageView.isHidden = true
        self.mediaPlayImageView.isUserInteractionEnabled = false
        self.contentImageView.loadImage(contentData: asset)
    }

    private func videoUrlLoad(url: String, generation: Int) {
        guard let urlSave = URL(string: url) else {
            contentImageView.image = PTAppBaseConfig.share.defaultEmptyImage
            return
        }

        loadMediaURL = urlSave
        PTVideoManager.shared.getVideoItem(for: url,
                                           autoCacheVideo: false) { [weak self] item in
            guard let self, self.loadGeneration == generation else { return }
            self.contentImageView.image = item.coverImage ?? PTAppBaseConfig.share.defaultEmptyImage
        } videoReady: { [weak self] item in
            guard let self, self.loadGeneration == generation else { return }
            self.videoCacheURL = item.localVideoURL
        }
                
        mediaPlayButtonImageSet()
        
        mediaPlayImageView.removeTargerAndAction()
        mediaPlayImageView.addActionHandlers { [weak self] sender in
            guard let self else { return }
            if self.videoCacheURL != nil {
                self.mediaPlayButtonTapCallback?()
            } else {
                self.mediaDownloadFunction(urlReal: urlSave)
            }
        }
    }
    
    public func mediaDownloadFunction(urlReal:URL) {
        let generation = loadGeneration
        loadingView.removeFromSuperview()
        self.loadingView.hubTapCallback = { [weak self] in
            PTMainActorBridge.perform { [weak self] in
                guard let self else { return }
                self.loadingView.removeFromSuperview()
                self.mediaPlayImageView.setImage(PTChatConfig.share.mediaDownloadPauseImage, for: .normal)
                Network.share.suspend(fileUrl: urlReal.absoluteString)
            }
        }
        if loadingView.superview == nil {
            dataContent.addSubview(loadingView)
            loadingView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        PTVideoFileCache.shared.prepareVideo(url: urlReal,progress: { _, _, progress in
            guard self.loadGeneration == generation else { return }
            self.loadingView.progress = progress
        }, completion: { localURL in
            guard self.loadGeneration == generation else { return }
            self.loadingView.removeFromSuperview()
            self.videoCacheURL = localURL
            self.mediaPlayButtonImageSet()
            if localURL != nil {
                self.mediaDownloadFinishCallback?()
            }
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
