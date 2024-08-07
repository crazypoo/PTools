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

//MARK: 图片CELL
class PTMediaLibCell: PTBaseNormalCell {
    static let ID = "PTMediaLibCell"
    
    var selectedBlock: ((@escaping (Bool) -> Void) -> Void)?
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
    
    private var imageIdentifier = ""
    private var smallImageRequestID: PHImageRequestID = PHInvalidImageRequestID
    private var bigImageReqeustID: PHImageRequestID = PHInvalidImageRequestID
    var cellModel:PTMediaModel! {
        didSet {
            let mediaLibConfig = PTMediaLibConfig.share
            
            if cellModel.isSelected {
                fetchBigImage()
            } else {
                cancelFetchBigImage()
            }
            
            if let editImage = cellModel.editImage {
                imageView.image = editImage
            } else {
                fetchSmallImage()
            }
            
            let showSelectButton:Bool
            if mediaLibConfig.maxSelectCount > 1 {
                if !mediaLibConfig.allowMixSelect {
                    showSelectButton = cellModel.type.rawValue < PTMediaModel.MediaType.video.rawValue
                } else {
                    showSelectButton = true
                }
            } else {
                showSelectButton = mediaLibConfig.showSelectBtnWhenSingleSelect
            }
            
            selectButton.isHidden = !showSelectButton
            selectButton.isUserInteractionEnabled = showSelectButton
            selectButton.isSelected = cellModel.isSelected
            
            switch cellModel.type {
            case .video:
                mediaTypeImageView.isHidden = false
                mediaTypeImageView.image = UIImage(.video)
                videoTimeLabel.isHidden = false
                videoTimeLabel.text = cellModel.duration
                videoTimeLabel.snp.updateConstraints { make in
                    make.width.equalTo(self.videoTimeLabel.sizeFor(height: 25).width + 5)
                }
            case .livePhoto:
                mediaTypeImageView.isHidden = false
                mediaTypeImageView.image = UIImage(.livephoto)
                videoTimeLabel.isHidden = true
                videoTimeLabel.text = ""
            case .gif:
                mediaTypeImageView.isHidden = true
                mediaTypeImageView.image = nil
                videoTimeLabel.isHidden = false
                videoTimeLabel.text = "GIF"
                videoTimeLabel.snp.updateConstraints { make in
                    make.width.equalTo(self.videoTimeLabel.sizeFor(height: 25).width + 5)
                }
            default:
                mediaTypeImageView.isHidden = true
                videoTimeLabel.isHidden = true
                videoTimeLabel.text = ""
            }
        }
    }
    
    private lazy var imageView : UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var coverView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.isHidden = true
        return view
    }()
    
    lazy var mediaTypeImageView:UIImageView = {
        let view = UIImageView()
        view.contentMode = . scaleAspectFit
        return view
    }()
    
    lazy var videoTimeLabel:UILabel = {
        let view = UILabel()
        view.font = .appfont(size: 14)
        view.textColor = .white
        view.viewCorner(radius: 5, borderWidth: 0, borderColor: .clear)
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.85)
        view.textAlignment = .center
        return view
    }()
    
    lazy var editButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTMediaLibConfig.share.editImage, for: .normal)
        return view
    }()

    lazy var selectButton:PTLayoutButton = {
        let view = PTLayoutButton()
        view.normalTitleColor = .clear
        view.selectedTitleColor = .white
        view.configBackgroundColor = .clear
        view.configBackgroundSelectedColor = .systemBlue
        view.addActionHandlers { sender in
            if self.enableSelect {
                self.selectedBlock?({ isSelected in
                    PTGCDManager.gcdMain {
                        sender.isSelected = isSelected
                        sender.layer.removeAllAnimations()
                    }
                    
                    if isSelected {
                        self.fetchBigImage()
                    } else {
                        self.cancelFetchBigImage()
                    }
                })
            }
        }
        view.cornerStyle = .small
        view.cornerRadius = 12.5
        view.borderWidth = 2
        view.borderColor = .white
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubviews([imageView,coverView,containerView,videoTimeLabel])
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        coverView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.addSubviews([selectButton,mediaTypeImageView,editButton])
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
            make.centerY.equalTo(self.mediaTypeImageView)
            make.height.equalTo(15)
            make.width.equalTo(0)
        }
        
        editButton.snp.makeConstraints { make in
            make.size.equalTo(25)
            make.top.left.equalToSuperview().inset(7.5)
        }
        editButton.isHidden = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func fetchSmallImage() {
        let size: CGSize
        let maxSideLength = bounds.width * 2
        if cellModel.whRatio > 1 {
            let w = maxSideLength * cellModel.whRatio
            size = CGSize(width: w, height: maxSideLength)
        } else {
            let h = maxSideLength / cellModel.whRatio
            size = CGSize(width: maxSideLength, height: h)
        }
        
        if smallImageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(smallImageRequestID)
        }
        
        imageIdentifier = cellModel.ident
        imageView.image = nil
        smallImageRequestID = PTMediaLibManager.fetchImage(for: cellModel.asset, size: size, completion: { [weak self] image, isDegraded in
            if self?.imageIdentifier == self?.cellModel.ident {
                self?.imageView.image = image
            }
            if !isDegraded {
                self?.smallImageRequestID = PHInvalidImageRequestID
            }
        })
    }
    
    func fetchBigImage() {
        cancelFetchBigImage()
        bigImageReqeustID = PTMediaLibManager.fetchOriginalImageData(for: cellModel.asset, progress: { [weak self] progress, _, _, _ in
            if self?.cellModel.isSelected == true {
//                self?.progressView.isHidden = false
//                self?.progressView.progress = max(0.1, progress)
                PTGCDManager.gcdMain {
                    self?.imageView.alpha = 0.5
                    if progress >= 1 {
                        self?.resetProgressViewStatus()
                    }
                }
            } else {
                self?.cancelFetchBigImage()
            }
        }, completion: { [weak self] _, _, _ in
            self?.resetProgressViewStatus()
        })
    }

    func cancelFetchBigImage() {
        if bigImageReqeustID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(bigImageReqeustID)
        }
        resetProgressViewStatus()
    }
    
    private func resetProgressViewStatus() {
//        progressView.isHidden = true
        PTGCDManager.gcdMain {
            self.imageView.alpha = 1
        }
    }
}

//MARK: 相册CELL
class PTMediaLibAlbumCell: PTBaseNormalCell {
    static let ID = "PTMediaLibAlbumCell"
        
    private var imageIdentifier: String?

    var albumModel:PTMediaLibListModel! {
        didSet {
            let att:ASAttributedString = """
        \(wrap: .embedding("""
        \(albumModel.title,.foreground(PTAppBaseConfig.share.viewDefaultTextColor),.font(UIFont.appfont(size: 18,bold: true)),.paragraph(.alignment(.left),.lineSpacing(10)))
        \("\n\(albumModel.count)",.foreground(.lightGray),.font(UIFont.appfont(size: 14)),.paragraph(.alignment(.left)))
        """))
        """
            contentLabel.attributed.text = att
            
            imageIdentifier = albumModel.headImageAsset?.localIdentifier
            if let asset = albumModel.headImageAsset {
                let w = bounds.height * 2.5
                PTMediaLibManager.fetchImage(for: asset, size: CGSize(width: w, height: w)) { [weak self] image, _ in
                    if self?.imageIdentifier == self?.albumModel.headImageAsset?.localIdentifier {
                        self?.imageView.image = image ?? PTAppBaseConfig.share.defaultEmptyImage
                    }
                }
            }
        }
    }
    
    lazy var imageView:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    lazy var contentLabel:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    lazy var selectedButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTMediaLibConfig.share.albumSelectedImage, for: .selected)
        view.setImage(nil, for: .normal)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubviews([imageView,selectedButton,contentLabel])
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
            make.left.equalTo(self.imageView.snp.right).offset(10)
            make.top.bottom.equalTo(self.imageView)
            make.right.equalTo(self.selectedButton.snp.left).offset(-10)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: Camera Cell
class PTCameraCell: PTBaseNormalCell {
    static let ID = "PTFilterImageCell"
    
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.image = PTMediaLibConfig.share.cameraImage
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = .white
        contentView.addSubviews([imageView])
        imageView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.size.equalTo(44)
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
