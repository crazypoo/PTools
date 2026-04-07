//
//  PTMediaLibCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import SnapKit
import Photos
import AttributedString
import SafeSFSymbols

// MARK: - 图片/视频展示 Cell
@MainActor
class PTMediaLibCell: PTBaseNormalCell {
    static let ID = "PTMediaLibCell"
    
    // 💡 优化：使用 Task 句柄管理异步任务，Swift 6 标准做法
    private var smallImageTask: Task<Void, Never>?
    private var bigImageTask: Task<Void, Never>?
    private var imageIdentifier: String = ""

    var selectedBlock: (@Sendable (@escaping PTBoolTask) -> Void)?
    
    var cellSelectedIndex = 0 {
        didSet {
            selectButton.normalTitle = "\(cellSelectedIndex)"
            selectButton.selectedTitle = "\(cellSelectedIndex)"
        }
    }
    
    var enableSelect = true {
        didSet {
            containerView.alpha = enableSelect ? 1 : 0.2
        }
    }
    
    var cellModel: PTMediaModel! {
        didSet {
            updateCellContent()
        }
    }
    
    // MARK: - 生命周期与重用
    override func prepareForReuse() {
        super.prepareForReuse()
        // 💡 彻底取消任务，防止滑动时图片错位或流量浪费
        smallImageTask?.cancel()
        bigImageTask?.cancel()
        smallImageTask = nil
        bigImageTask = nil
        
        imageIdentifier = ""
        imageView.image = nil
        imageView.alpha = 1
        videoTimeLabel.text = ""
        mediaTypeImageView.image = nil
    }

    private func updateCellContent() {
        let mediaLibConfig = PTMediaLibConfig.share
        imageIdentifier = cellModel.ident
        
        // 1. 处理选中状态的大图预加载/缓存逻辑
        if cellModel.isSelected {
            fetchBigImage()
        } else {
            cancelFetchBigImage()
        }
        
        // 2. 图像显示优先级：编辑后的图 > 相册原图
        if let editImage = cellModel.editImage {
            imageView.image = editImage
        } else {
            fetchSmallImage()
        }
        
        // 3. 选择按钮显示逻辑控制
        let isSingleSelect = mediaLibConfig.maxSelectCount <= 1
        let canShowBtn = isSingleSelect ? mediaLibConfig.showSelectBtnWhenSingleSelect : (mediaLibConfig.allowMixSelect || cellModel.type != .video)
        
        selectButton.isHidden = !canShowBtn
        selectButton.isUserInteractionEnabled = canShowBtn
        selectButton.isSelected = cellModel.isSelected
        
        // 4. 媒体类型 UI 适配
        configureMediaType()
    }
    
    private func configureMediaType() {
        switch cellModel.type {
        case .video:
            mediaTypeImageView.isHidden = false
            mediaTypeImageView.image = PTMediaLibUIConfig.share.cellVideoImage
            videoTimeLabel.isHidden = false
            videoTimeLabel.text = cellModel.duration
        case .livePhoto:
            mediaTypeImageView.isHidden = false
            mediaTypeImageView.image = PTMediaLibUIConfig.share.cellLivePhotoImage
            videoTimeLabel.isHidden = true
        case .gif:
            mediaTypeImageView.isHidden = true
            videoTimeLabel.isHidden = false
            videoTimeLabel.text = "GIF"
        default:
            mediaTypeImageView.isHidden = true
            videoTimeLabel.isHidden = true
        }
        
        // 💡 只有在显示时才更新约束，减少 Layout Engine 负担
        if !videoTimeLabel.isHidden {
            let width = videoTimeLabel.sizeFor(height: 15).width + 8
            videoTimeLabel.snp.updateConstraints { make in
                make.width.equalTo(width)
            }
        }
    }

    // MARK: - 异步加载逻辑
    private func fetchSmallImage() {
        smallImageTask?.cancel()
        
        let asset = cellModel.asset
        let ident = cellModel.ident
        let scale = UIScreen.main.scale
        let targetWidth = bounds.width * scale
        
        let size: CGSize
        if cellModel.whRatio > 1 {
            size = CGSize(width: targetWidth * cellModel.whRatio, height: targetWidth)
        } else {
            size = CGSize(width: targetWidth, height: targetWidth / cellModel.whRatio)
        }

        smallImageTask = Task {
            PTMediaLibManager.fetchImage(for: asset, size: size) { [weak self] image, isDegraded in
                guard let self = self, self.imageIdentifier == ident else { return }
                self.imageView.image = image
            }
        }
    }

    func fetchBigImage() {
        cancelFetchBigImage()
        let asset = cellModel.asset
        
        bigImageTask = Task {
            PTMediaLibManager.fetchOriginalImageData(for: asset, progress: { [weak self] progress, _, _, _ in
                Task { @MainActor in
                    guard let self = self, self.cellModel.isSelected else { return }
                    self.imageView.alpha = 0.5
                    if progress >= 1 { self.resetProgressViewStatus() }
                }
            }, completion: { [weak self] _, _, _ in
                Task { @MainActor in self?.resetProgressViewStatus() }
            })
        }
    }

    func cancelFetchBigImage() {
        bigImageTask?.cancel()
        bigImageTask = nil
        resetProgressViewStatus()
    }
    
    private func resetProgressViewStatus() {
        imageView.alpha = 1
    }

    // MARK: - UI Components
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.backgroundColor = .secondarySystemBackground
        return view
    }()
    
    private lazy var containerView = UIView()
    
    lazy var coverView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.isHidden = true
        view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        return view
    }()
    
    lazy var mediaTypeImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var videoTimeLabel: UILabel = {
        let view = UILabel()
        view.font = PTMediaLibUIConfig.share.cellVideoTimeFont
        view.textColor = .white
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.textAlignment = .center
        return view
    }()
    
    lazy var editButton: UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTMediaLibUIConfig.share.cellEditImage, for: .normal)
        view.isHidden = true
        return view
    }()

    lazy var selectButton: PTLayoutButton = {
        let view = PTLayoutButton()
        view.normalTitleFont = PTMediaLibUIConfig.share.cellSelectedIndexFont
        view.normalTitleColor = .clear
        view.selectedTitleColor = .white
        view.configBackgroundSelectedColor = .systemBlue
        view.addActionHandlers { [weak self] sender in
            guard let self = self, self.enableSelect else { return }
            self.selectedBlock? { isSelected in
                Task { @MainActor in
                    sender.isSelected = isSelected
                    if isSelected { self.fetchBigImage() } else { self.cancelFetchBigImage() }
                }
            }
        }
        view.cornerRadius = 12.5
        view.borderWidth = 1.5
        view.borderColor = .white
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubviews([imageView, coverView, containerView, videoTimeLabel])
        containerView.addSubviews([selectButton, mediaTypeImageView, editButton])
        
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        coverView.snp.makeConstraints { $0.edges.equalToSuperview() }
        containerView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        selectButton.snp.makeConstraints { make in
            make.size.equalTo(25)
            make.top.right.equalToSuperview().inset(7.5)
        }
        
        mediaTypeImageView.snp.makeConstraints { make in
            make.size.equalTo(25)
            make.left.bottom.equalToSuperview().inset(7.5)
        }
        
        videoTimeLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(7.5)
            make.centerY.equalTo(mediaTypeImageView)
            make.height.equalTo(15)
            make.width.equalTo(0)
        }
        
        editButton.snp.makeConstraints { make in
            make.size.equalTo(25)
            make.top.left.equalToSuperview().inset(7.5)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - 相册列表 Cell
@MainActor
class PTMediaLibAlbumCell: PTBaseNormalCell {
    static let ID = "PTMediaLibAlbumCell"
    private var fetchTask: Task<Void, Never>?
    private var imageIdentifier: String?

    var albumModel: PTMediaLibListModel! {
        didSet {
            updateAlbumUI()
        }
    }
    
    private func updateAlbumUI() {
        let att: ASAttributedString = """
        \(wrap: .embedding("""
        \(albumModel.title, .foreground(PTAppBaseConfig.share.viewDefaultTextColor), .font(PTMediaLibUIConfig.share.albumCellTitleFont))
        \("\n\(albumModel.count)", .foreground(.secondaryLabel), .font(PTMediaLibUIConfig.share.albumCellDescFont))
        """))
        """
        contentLabel.attributed.text = att
        
        imageIdentifier = albumModel.headImageAsset?.localIdentifier
        imageView.image = PTAppBaseConfig.share.defaultEmptyImage
        fetchTask?.cancel()
        
        if let asset = albumModel.headImageAsset {
            let ident = asset.localIdentifier
            let side = bounds.height * UIScreen.main.scale
            
            fetchTask = Task {
                PTMediaLibManager.fetchImage(for: asset, size: CGSize(width: side, height: side)) { [weak self] image, _ in
                    guard let self = self, self.imageIdentifier == ident else { return }
                    self.imageView.image = image ?? PTAppBaseConfig.share.defaultEmptyImage
                }
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        fetchTask?.cancel()
        fetchTask = nil
        imageView.image = nil
        imageIdentifier = nil
    }
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 4
        return view
    }()
    
    lazy var contentLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    lazy var selectedButton: UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTMediaLibUIConfig.share.albumSelectedImage, for: .selected)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubviews([imageView, selectedButton, contentLabel])
        
        imageView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(5)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.width.equalTo(imageView.snp.height)
        }
        
        selectedButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.size.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        contentLabel.snp.makeConstraints { make in
            make.left.equalTo(imageView.snp.right).offset(10)
            make.top.bottom.equalTo(imageView)
            make.right.equalTo(selectedButton.snp.left).offset(-10)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - 相机入口 Cell
@MainActor
class PTCameraCell: PTBaseNormalCell {
    static let ID = "PTFilterImageCell"
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        view.clipsToBounds = true
        view.image = PTMediaLibUIConfig.share.cameraImage
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
