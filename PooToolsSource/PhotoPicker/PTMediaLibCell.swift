//
//  PTMediaLibCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import Photos
#if canImport(PToolsUIFoundation)
import PToolsUIFoundation
#endif
#if SWIFT_PACKAGE
import PToolsSymbols
#endif

#if SWIFT_PACKAGE
import ptools
import PooToolsImagePicker
#endif

// MARK: - 图片/视频展示 Cell
@MainActor
class PTMediaLibCell: PTBaseNormalCell {
    static let ID = "PTMediaLibCell"
    
    // PHImageManager 的请求不是结构化 Task，由协调器统一保存并取消。
    private let requestCoordinator = PTMediaRequestCoordinator()
    private var imageIdentifier: String = ""
    private var lastSmallRequestSize: CGSize = .zero
    private var smallRequestStartedAt: CFAbsoluteTime?

    // English: Keep the selection callback on MainActor so the cell never sends UIKit state through a detached closure.
    // Español: Mantén el callback de selección en MainActor para no enviar el estado UIKit mediante un cierre separado.
    // 中文：选择回调固定在 MainActor，避免通过脱离上下文的闭包传递 UIKit 状态。
    var selectedBlock: (@MainActor @Sendable (@escaping @MainActor @Sendable (Bool) -> Void) -> Void)?

    // English: The presenter supplies a frozen selection policy so the cell does not read mutable global limits.
    // Español: El presentador proporciona una política de selección congelada para que la celda no lea límites globales mutables.
    // 中文：由展示控制器提供冻结的选择策略，Cell 不再读取可变的全局限制。
    var selectionOptions: PTMediaLibSelectionOptions?

    // English: Bind the edit action once; cell configuration only replaces this closure.
    // Español: Vincula la acción de edición una sola vez; la configuración solo reemplaza este cierre.
    // 中文：编辑按钮只绑定一次，Cell 配置阶段只替换闭包。
    var editAction: ((UIButton) -> Void)?

    // English: Keep the asset identity visible to the owner so reused cells never apply a stale selection state.
    // Español: Mantiene visible la identidad del recurso para que las celdas reutilizadas no apliquen un estado obsoleto.
    // 中文：让拥有者可以读取资源身份，避免复用 Cell 应用过期的选择状态。
    private(set) var representedAssetID: String?
    
    var cellSelectedIndex = 0 {
        didSet {
            let title = cellSelectedIndex > 0 ? "\(cellSelectedIndex)" : ""
            selectButton.normalTitle = title
            selectButton.selectedTitle = title
        }
    }
    
    var enableSelect = true {
        didSet {
            containerView.alpha = enableSelect ? 1 : 0.2
        }
    }
    
    var cellModel: PTMediaModel? {
        didSet {
            updateCellContent()
        }
    }
    
    // MARK: - 生命周期与重用
    override func prepareForReuse() {
        super.prepareForReuse()
        cancelImageRequests()
        
        imageIdentifier = ""
        representedAssetID = nil
        lastSmallRequestSize = .zero
        smallRequestStartedAt = nil
        imageView.image = nil
        imageView.alpha = 1
        videoTimeLabel.text = ""
        videoTimeLabel.isHidden = true
        mediaTypeImageView.image = nil
        selectButton.isSelected = false
        cellSelectedIndex = 0
        selectButton.isUserInteractionEnabled = false
        coverView.isHidden = true
        editButton.isHidden = true
        editButton.clearProgressLayer()
        editAction = nil
        selectedBlock = nil
        selectionOptions = nil
        cellModel = nil
        enableSelect = true
        layer.borderWidth = 0
    }

    private func updateCellContent() {
        guard let cellModel else { return }
        let options = self.selectionOptions ?? .current()
        let identityChanged = imageIdentifier != cellModel.ident
        imageIdentifier = cellModel.ident
        representedAssetID = cellModel.ident
        if identityChanged {
            // English: A reused cell must show a placeholder until the new asset resolves.
            // Español: Una celda reutilizada debe mostrar un marcador hasta resolver el nuevo recurso.
            // 中文：复用 Cell 后，必须先展示占位图，直到新资源加载完成。
            imageView.image = PTAppBaseConfig.share.defaultEmptyImage
            lastSmallRequestSize = .zero
        }
        
        // English: Selection only updates the overlay; original data is requested by an explicit submission path.
        // Español: La selección solo actualiza la máscara; los datos originales se solicitan en la ruta explícita de envío.
        // 中文：选中状态只更新遮罩；原图请求由提交流程按需发起，避免 Cell 重复下载。
        if !cellModel.isSelected {
            cancelFetchBigImage()
        }
        
        // 2. 图像显示优先级：编辑后的图 > 相册原图
        if let editImage = cellModel.editImage {
            imageView.image = editImage
        } else {
            fetchSmallImage()
        }
        
        // 3. 选择按钮显示逻辑控制
        let isSingleSelect = options.maxSelectCount <= 1
        let canShowBtn = isSingleSelect ? options.showSelectBtnWhenSingleSelect : (options.allowMixSelect || cellModel.type != .video)
        
        selectButton.isHidden = !canShowBtn
        selectButton.isUserInteractionEnabled = canShowBtn
        
        // 4. 媒体类型 UI 适配
        configureMediaType()
    }

    // English: Render every selection-dependent property from one immutable projection.
    // Español: Renderiza todas las propiedades dependientes de la selección desde una sola proyección inmutable.
    // 中文：所有依赖选择状态的属性都由同一个不可变投影一次性渲染。
    func applySelectionPresentation(isSelected: Bool,
                                    order: Int?,
                                    canSelect: Bool,
                                    canEdit: Bool,
                                    showInvalidMask: Bool,
                                    borderColor: UIColor) {
        let canInteract = isSelected || canSelect
        selectButton.isSelected = isSelected
        selectButton.isUserInteractionEnabled = canInteract
        cellSelectedIndex = order ?? 0
        enableSelect = canInteract
        editButton.isHidden = !canEdit
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = isSelected ? 4 : 0

        if isSelected {
            coverView.backgroundColor = .DevMaskColor
            coverView.isHidden = false
        } else {
            coverView.backgroundColor = .DevMaskColor
            coverView.isHidden = !showInvalidMask
        }
    }
    
    private func configureMediaType() {
        guard let cellModel else { return }
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
        guard let cellModel else { return }
        guard bounds.width > 1, bounds.height > 1 else {
            imageView.image = PTAppBaseConfig.share.defaultEmptyImage
            return
        }
        let asset = cellModel.asset
        let ident = cellModel.ident
        // English: Resolve scale from the cell's scene; use one only before the cell is attached to a window.
        // Español: Resuelve la escala desde la escena de la celda; usa uno solo antes de adjuntarla a una ventana.
        // 中文：优先从 Cell 所属场景读取比例，尚未挂载到 Window 时才使用 1。
        let scale = window?.screen.scale ?? PTSceneContext.activeWindow()?.screen.scale ?? 1
        guard cellModel.whRatio.isFinite, cellModel.whRatio > 0 else {
            imageView.image = PTAppBaseConfig.share.defaultEmptyImage
            return
        }
        let size = cellModel.previewSize(in: bounds, scale: scale)
        guard size.width > 1, size.height > 1 else { return }
        if imageView.image == nil {
            imageView.image = PTAppBaseConfig.share.defaultEmptyImage
        }
        if requestCoordinator.isActive("small"), lastSmallRequestSize == size { return }
        lastSmallRequestSize = size
        let generation = requestCoordinator.begin("small")
        smallRequestStartedAt = CFAbsoluteTimeGetCurrent()

        let requestID = PTMediaLibManager.requestImage(for: asset,
                                                       targetSize: size,
                                                       contentMode: .aspectFill,
                                                       resizeMode: .fast,
                                                       deliveryMode: .opportunistic) { [weak self = self] result in
            guard let self = self,
                  self.imageIdentifier == ident,
                  self.requestCoordinator.isCurrent("small", generation: generation) else { return }
            let durationMs = Int((CFAbsoluteTimeGetCurrent() - (self.smallRequestStartedAt ?? CFAbsoluteTimeGetCurrent())) * 1000)
            if result.isCancelled {
                PTMediaPickerTrace.event("thumbnailResolved", details: "assetIDPresent=true,status=cancelled,durationMs=\(durationMs)")
                return
            }
            guard let image = result.image else {
                PTMediaPickerTrace.event("thumbnailResolved", details: "assetIDPresent=true,status=failed,degraded=\(result.isDegraded),nilImage=true,errorPresent=\(result.error != nil),durationMs=\(durationMs)")
                return
            }
            self.imageView.image = image
            PTMediaPickerTrace.event("thumbnailResolved", details: "assetIDPresent=true,status=\(result.isDegraded ? "degraded" : "final"),nilImage=false,errorPresent=\(result.error != nil),durationMs=\(durationMs)")
        }
        PTMediaPickerTrace.event("thumbnailRequested", details: "assetIDPresent=true,width=\(Int(size.width)),height=\(Int(size.height)),requestID=\(requestID)")
        requestCoordinator.store(requestID, for: "small", generation: generation)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if cellModel != nil {
            fetchSmallImage()
        }
    }

    func fetchBigImage() {
        guard let cellModel else { return }
        let asset = cellModel.asset
        let ident = cellModel.ident
        let generation = requestCoordinator.begin("big")
        PTMediaPickerTrace.event("cellRequest", details: "kind=original,assetIDPresent=true")
        
        let requestID = PTMediaLibManager.requestImageData(for: asset, progress: { [weak self = self] progress, _, _, _ in
            Task { @MainActor in
                guard let self = self,
                      self.imageIdentifier == ident,
                      self.requestCoordinator.isCurrent("big", generation: generation),
                      self.cellModel?.isSelected == true else { return }
                self.imageView.alpha = 0.5
                if progress >= 1 { self.resetProgressViewStatus() }
            }
        }, completion: { [weak self = self] _ in
            Task { @MainActor in
                guard let self = self,
                      self.imageIdentifier == ident,
                      self.requestCoordinator.isCurrent("big", generation: generation) else { return }
                self.resetProgressViewStatus()
            }
        })
        requestCoordinator.store(requestID, for: "big", generation: generation)
    }

    func cancelFetchBigImage() {
        requestCoordinator.cancel("big")
        resetProgressViewStatus()
    }

    private func cancelImageRequests() {
        PTMediaPickerTrace.event("cellRequest", details: "kind=cancel,assetIDPresent=\(!imageIdentifier.isEmpty)")
        requestCoordinator.cancelAll()
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
        view.addActionHandlers { [weak self] sender in
            self?.editAction?(sender)
        }
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
                if !isSelected { self.cancelFetchBigImage() }
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
    private let requestCoordinator = PTMediaRequestCoordinator()
    private var imageIdentifier: String?

    var albumModel: PTMediaLibListModel? {
        didSet {
            updateAlbumUI()
        }
    }
    
    private func updateAlbumUI() {
        guard let albumModel else { return }
        let att: PTRichText = """
        \(wrap: .embedding("""
        \(albumModel.title, .foreground(PTAppBaseConfig.share.viewDefaultTextColor), .font(PTMediaLibUIConfig.share.albumCellTitleFont))
        \("\n\(albumModel.count)", .foreground(.secondaryLabel), .font(PTMediaLibUIConfig.share.albumCellDescFont))
        """))
        """
        contentLabel.attributedText = att.value
        
        imageIdentifier = albumModel.headImageAsset?.localIdentifier
        imageView.image = PTAppBaseConfig.share.defaultEmptyImage
        let generation = requestCoordinator.begin("album")
        
        if let asset = albumModel.headImageAsset {
            let ident = asset.localIdentifier
            // English: Keep album thumbnails scene-aware and avoid the process-wide screen singleton.
            // Español: Mantiene las miniaturas del álbum vinculadas a la escena y evita el singleton de pantalla global.
            // 中文：相册缩略图按当前场景计算，避免使用进程级屏幕单例。
            let side = bounds.height * (window?.screen.scale ?? PTSceneContext.activeWindow()?.screen.scale ?? 1)

            let requestID = PTMediaLibManager.requestImage(for: asset,
                                                           targetSize: CGSize(width: side, height: side),
                                                           contentMode: .aspectFill,
                                                           resizeMode: .fast,
                                                           deliveryMode: .opportunistic) { [weak self = self] result in
                guard let self = self,
                      self.imageIdentifier == ident,
                      self.requestCoordinator.isCurrent("album", generation: generation),
                      !result.isCancelled else { return }
                self.imageView.image = result.image ?? PTAppBaseConfig.share.defaultEmptyImage
            }
            requestCoordinator.store(requestID, for: "album", generation: generation)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        requestCoordinator.cancelAll()
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
