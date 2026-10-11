//
//  PTMediaBrowserCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import AVFoundation
import AVKit
import Kingfisher
import Photos
import PhotosUI

@MainActor
class PTMediaBrowserCell: PTBaseNormalCell {
    static let ID = "PTMediaBrowserCell"
    
    private var loadIdentifier = UUID()
    private var loadTask: Task<Void, Never>?

    var viewerDismissBlock:PTActionTask?
    var zoomTask:PTBoolTask?
    var tapTask:PTActionTask?
    var currentCellType:PTViewerDataType = .None
    var longTapWakeUp:PTActionTask?
    var imageLongTaped:Bool = false
    var videoPlayHandler:((PTPlayerViewController) -> Void)?
    
    let maxZoomSale:CGFloat = 2
    let minZoomSale:CGFloat = 0.6
    fileprivate var videoOriginalItem:Any?
    fileprivate var videoCacheURL:URL?
    
    private var hasSetupGesture = false

    lazy var contentScrolView:UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.delegate = self
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.clipsToBounds = true
        return view
    }()

    lazy var effectView: UIVisualEffectView = {
      let effect = UIBlurEffect(style: .dark)
      let view = UIVisualEffectView(effect: effect)
      return view
    }()

    lazy var backgroundImageView: UIImageView = {
      let view = UIImageView()
      return view
    }()

    let viewConfig = PTMediaBrowserConfig.share
    
    var dataModel:PTMediaBrowserModel! {
        didSet {
            self.cellLoadData()
        }
    }

    lazy var tempView:UIImageView = {
        let view = UIImageView()
        
        let safeOffset = self.scrollOffset ?? .zero
        let safeSize = self.zoomImageSize ?? self.frame.size

        let tempImageX:CGFloat = self.imageView.frame.origin.x - safeOffset.x
        var tempImageY:CGFloat = self.imageView.frame.origin.y - safeOffset.y

        let tempImageW = safeSize.width
        var tempImageH = safeSize.height
        
        let isLandscape = bounds.width > bounds.height
        if isLandscape {
            if tempImageH > self.frame.size.height {
                tempImageH = tempImageH > (tempImageW * 1.5) ? (tempImageW * 1.5) : tempImageH
                if abs(tempImageY) > tempImageH {
                    tempImageY = 0
                }
            }
        }
        
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.frame = CGRect(x: tempImageX, y: tempImageY, width: tempImageW, height: tempImageH)
        view.image = self.gifImage
        return view
    }()

    //MARK: 图片相关
    fileprivate var scrollOffset:CGPoint? = CGPoint.zero
    fileprivate lazy var zoomImageSize:CGSize? = CGSize(width: frame.size.width, height: frame.size.height)
    
    fileprivate lazy var reloadButton:UIButton = {
        let view = UIButton.init(type: .custom)
        view.viewCorner(radius: 2,borderWidth:1,borderColor: .white)
        view.titleLabel?.font = self.viewConfig.viewerFont
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.3)
        view.setTitleColor(.white, for: .normal)
        view.addActionHandlers { sender in
            self.reloadButton.isHidden = true
            self.cellLoadData()
        }
        return view
    }()
    
    lazy var imageView:UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = true
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    var gifImage:UIImage? = nil
    private var lastAdaptiveViewportSignature: String?

    //MARK: 视频相关
    fileprivate lazy var playBtn:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(viewConfig.playButtonImage, for: .normal)
        view.imageView?.contentMode = .scaleAspectFill
        view.addActionHandlers { sender in
            self.videoPlay()
        }
        return view
    }()
    
    fileprivate lazy var livePhoto:PHLivePhotoView = {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        view.delegate = self
        view.backgroundColor = .clear
        return view
    }()
    
    fileprivate lazy var loading: PTMediaBrowserLoadingView = {
        let view = PTMediaBrowserLoadingView(type: .LoopDiagram)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
                
        contentView.addSubviews([backgroundImageView,effectView,contentScrolView, playBtn, loading, reloadButton])
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        effectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        effectView.isHidden = !viewConfig.dynamicBackground
        backgroundImageView.isHidden = !viewConfig.dynamicBackground
        
        contentScrolView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentScrolView.addSubviews([imageView,livePhoto])
        
        playBtn.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(viewConfig.playButtonImageSize)
        }

        loading.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(50)
        }

        reloadButton.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        livePhoto.isHidden = true
        loading.isHidden = true
        reloadButton.isHidden = true
        setupGestureOnce()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateAdaptiveViewportLayout()
    }

    // English: Use the full host for Duo media while keeping the legacy visible-pane behavior elsewhere.
    // Español: Usa todo el host para el multimedia Duo y conserva el panel visible heredado en los demás casos.
    // 中文：Duo 媒体使用完整宿主区域，其他设备继续使用原有可视面板逻辑。
    private func updateAdaptiveViewportLayout() {
        guard !contentView.bounds.isEmpty else { return }
        let context = PTAdaptiveBarLayoutContext.make(for: contentView)
        let region = PTAdaptiveVisibleRegionResolver.region(for: context)
        let horizontalRect = CGRect(x: region.visibleRect.minX,
                                    y: contentView.bounds.minY,
                                    width: region.visibleRect.width,
                                    height: contentView.bounds.height).intersection(contentView.bounds)
        let hasSystemVerticalPane = context.verticalBarEdge != .unspecified || !region.reservedRects.isEmpty
        let visibleRect: CGRect
        if hasSystemVerticalPane {
            // English: The media viewport may render beneath the system rail; play and loading states share it.
            // Español: El viewport multimedia puede dibujarse bajo la rail del sistema; reproducción y carga comparten el mismo espacio.
            // 中文：媒体视口允许铺到系统保留栏下方，播放和加载状态共用同一完整区域。
            visibleRect = contentView.bounds
        } else {
            visibleRect = horizontalRect.isEmpty ? contentView.bounds : horizontalRect
        }
        let signature = "\(region.signature)|\(hasSystemVerticalPane)|\(visibleRect.integral)"
        guard signature != lastAdaptiveViewportSignature else { return }
        lastAdaptiveViewportSignature = signature

        contentScrolView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(visibleRect.minX)
            make.right.equalToSuperview().inset(max(0, contentView.bounds.width - visibleRect.maxX))
            make.top.bottom.equalToSuperview()
        }
        [playBtn, loading, reloadButton].forEach { view in
            view.snp.remakeConstraints { make in
                make.center.equalTo(contentScrolView)
                if view === playBtn {
                    make.size.equalTo(viewConfig.playButtonImageSize)
                } else if view === loading {
                    make.size.equalTo(50)
                }
            }
        }

        contentView.layoutIfNeeded()
        if gifImage != nil, contentScrolView.zoomScale <= 1.01 {
            adjustFrame()
        }
    }
    
    private func setupGestureOnce() {
        guard !hasSetupGesture else { return }
        hasSetupGesture = true

        imageView.removeAllGestureRecognizers()
        
        let doubleTap = UITapGestureRecognizer { [weak self] sender in
            guard let self = self, let ges = sender as? UITapGestureRecognizer else { return }
            
            if self.contentScrolView.zoomScale > 1 {
                self.contentScrolView.setZoomScale(1, animated: true)
                self.zoomTask?(false)
            } else {
                // MARK: - 1. 计算更平滑的双击放大矩形，以点击点为中心
                let zoomView = self.currentCellType == .LivePhoto ? self.livePhoto : self.imageView
                let point = ges.location(in: zoomView)
                let scale = self.maxZoomSale
                
                let width = self.contentScrolView.bounds.width / scale
                let height = self.contentScrolView.bounds.height / scale
                let x = point.x - (width / 2.0)
                let y = point.y - (height / 2.0)
                
                let zoomRect = CGRect(x: x, y: y, width: width, height: height)
                self.contentScrolView.zoom(to: zoomRect, animated: true)
                self.zoomTask?(true)
            }
        }
        doubleTap.numberOfTapsRequired = 2

        let singleTap = UITapGestureRecognizer { [weak self] sender in
            if let _ = sender as? UITapGestureRecognizer {
                self?.tapTask?()
            }
        }
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)

        var imageActions:[UIGestureRecognizer] = [singleTap,doubleTap]

        if viewConfig.imageLongTapAction {
            let longTap = UILongPressGestureRecognizer { [weak self] sender in
                guard let self = self else { return }
                if let _ = sender as? UILongPressGestureRecognizer {
                    if !self.imageLongTaped {
                        self.longTapWakeUp?()
                        self.imageLongTaped = true
                    }
                }
            }
            longTap.numberOfTapsRequired = 1
            longTap.minimumPressDuration = 1.5
            imageActions.append(longTap)
        }
        imageView.addGestureRecognizers(imageActions)
        
        let longPress = UILongPressGestureRecognizer { [weak self] sender in
            self?.livePhoto.startPlayback(with: .hint)
        }
        longPress.minimumPressDuration = 1
        livePhoto.addGestureRecognizer(longPress)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        invalidateMediaResources()
        
        // MARK: - 2. 彻底清理状态，取消正在进行的任务防止卡顿和错乱
        currentCellType = .None
        gifImage = nil
        videoCacheURL = nil
        videoOriginalItem = nil // 确保清理视频源
        imageLongTaped = false

        imageView.image = nil
        livePhoto.livePhoto = nil

        imageView.isHidden = false
        livePhoto.isHidden = true
        playBtn.isHidden = true

        loading.isHidden = true
        reloadButton.isHidden = true

        contentScrolView.setZoomScale(1, animated: false)
        contentScrolView.contentOffset = .zero
    }

    // English: Invalidate every asynchronous media resource before a cell is reused or released.
    // Español: Invalida todos los recursos multimedia asíncronos antes de reutilizar o liberar la celda.
    // 中文：在 Cell 复用或释放前，统一失效所有异步媒体资源。
    func invalidateMediaResources() {
        loadTask?.cancel()
        loadTask = nil
        loadIdentifier = UUID()
        lastAdaptiveViewportSignature = nil
        imageView.kf.cancelDownloadTask()
        imageView.stopAnimating()
        livePhoto.stopPlayback()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func adjustFrame(normal:Bool = true,fixed:PTActionTask? = nil) {
        // English: Scroll-view bounds may carry a content offset; media frames must use zero-origin content coordinates.
        // Español: Los bounds del scroll pueden incluir contentOffset; los frames multimedia deben empezar en cero.
        // 中文：ScrollView 的 bounds 可能带有 contentOffset，媒体 frame 必须使用零起点内容坐标。
        let viewportBounds = CGRect(origin: .zero, size: contentScrolView.bounds.size)
        guard viewportBounds.width > 0, viewportBounds.height > 0 else {
            // English: Defer scale math until Auto Layout provides a real viewport size.
            // Español: Aplaza el cálculo de escala hasta que Auto Layout proporcione un tamaño real.
            // 中文：等 Auto Layout 提供有效尺寸后再计算缩放，避免首帧产生无效比例。
            imageView.frame = viewportBounds
            livePhoto.frame = viewportBounds
            contentScrolView.contentSize = viewportBounds.size
            return
        }
        guard let image = gifImage else {
            imageView.frame = viewportBounds
            livePhoto.frame = viewportBounds
            contentScrolView.contentSize = viewportBounds.size
            return
        }
        guard image.size.width > 0, image.size.height > 0 else {
            imageView.frame = viewportBounds
            livePhoto.frame = viewportBounds
            contentScrolView.contentSize = viewportBounds.size
            return
        }

        let width = viewportBounds.width
        let height = width * (image.size.height / image.size.width)

        let frame = CGRect(x: 0,
                           y: max(0, (viewportBounds.height - height) / 2),
                           width: width,
                           height: height)

        imageView.frame = frame
        livePhoto.frame = frame
        contentScrolView.contentSize = frame.size

        let maxScale = max(viewportBounds.height / height, viewportBounds.width / width, maxZoomSale)

        contentScrolView.minimumZoomScale = minZoomSale
        contentScrolView.maximumZoomScale = maxScale
        contentScrolView.zoomScale = 1

        fixed?()
    }
                    
    open class func centerOfScrollVIewContent(scrollView:UIScrollView) -> CGPoint {
        let offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? ((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5) : 0
        let offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? ((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5) : 0
        let actualCenter = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
        return actualCenter
    }
    
    private func clearContentView() {
        gifImage = nil
        reloadButton.isHidden = true
    }
    
    func cellLoadData() {
        loadTask?.cancel()
        let currentID = UUID()
        loadIdentifier = currentID
        loadTask = Task { [weak self] in
            guard let self, let dataModel = self.dataModel else { return }
            self.showLoading()
            
            guard let imageData = dataModel.imageURL else {
                self.currentCellType = .None
                self.createReloadButton()
                self.hideLoading()
                return
            }

            switch imageData {
            case let urlString as String:
                self.loadDataUrl(loadUrl: urlString.urlToUnicodeURLString() ?? "",currentID: currentID)
            case let url as URL:
                self.loadDataUrl(loadUrl: url.absoluteString.urlToUnicodeURLString() ?? "",currentID: currentID)
            case let avItem as AVPlayerItem:
                self.videoOriginalItem = avItem
                self.videoAVItem(avItem: avItem, currentID: currentID)
            case let avAsset as AVAsset:
                let avPlayerItem = AVPlayerItem(asset: avAsset)
                self.videoOriginalItem = avPlayerItem
                self.videoAVItem(avItem: avPlayerItem, currentID: currentID)
            case let livePhotoTarget as PHLivePhoto:
                self.currentCellType = .LivePhoto
                do {
                    let result = try await PTLivePhoto.extractResources(from: livePhotoTarget)
                    guard !Task.isCancelled, self.loadIdentifier == currentID else { return }
                    if FileManager.pt.judgeFileOrFolderExists(filePath: result.pairedImage.path) {
                        self.gifImage = UIImage(contentsOfFile: result.pairedImage.path)
                    }
                    self.livePhoto.livePhoto = livePhotoTarget
                    self.adjustFrame(normal: false) {
                        PTGCDManager.shared.runOnMain {
                            self.livePhoto.startPlayback(with: .hint)
                        }
                    }
                    self.livePhoto.isHidden = false
                    self.hideLoading()
                } catch {
                    guard !Task.isCancelled, self.loadIdentifier == currentID else { return }
                    self.currentCellType = .None
                    self.hideLoading()
                    self.createReloadButton()
                }
            default:
                self.baseLoadImageData(imageData: imageData, currentID: currentID)
            }
        }
    }
    
    func loadDataUrl(loadUrl:String, currentID: UUID) {
        if !loadUrl.isEmpty {
            let pathExtension = URL(string: loadUrl)?.pathExtension
                ?? URL(fileURLWithPath: loadUrl).pathExtension
            if GlobalVideoExts.contains(pathExtension.lowercased()) {
                self.videoUrlLoad(url: loadUrl,currentID:currentID)
            } else {
                if !loadUrl.stringIsEmpty() {
                    self.setImageTypeView(url:loadUrl, currentID: currentID)
                } else {
                    self.currentCellType = .None
                    self.createReloadButton()
                    self.adjustFrame()
                    self.hideLoading()
                }
            }
        } else {
            self.currentCellType = .None
            self.createReloadButton()
            self.adjustFrame()
            self.hideLoading()
        }
    }
                
    func hideAnimation() {
        contentView.isUserInteractionEnabled = false
        guard let window = PTSceneContext.window(for: contentView) else {
            contentView.isUserInteractionEnabled = true
            viewerDismissBlock?()
            return
        }
        let targetTemp = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)

        window.windowLevel = .normal
        UIView.animate(withDuration: 0.35) {
            self.tempView.transform = self.contentView.transform.inverted()
            self.tempView.frame = targetTemp
        } completion: { finish in
            self.tempView.removeFromSuperview()
            self.contentView.alpha = 0
            
            switch self.currentCellType {
            case .GIF:
                self.imageView.stopAnimating()
            default:
                break
            }
            self.viewerDismissBlock?()
        }
    }

    func bounceToOriginal() {
        contentScrolView.isUserInteractionEnabled = true
        contentView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.35) {
            self.tempView.transform = CGAffineTransform.identity
            self.contentView.alpha = 1
        } completion: { finish in
            self.contentView.isUserInteractionEnabled = true
            self.tempView.removeFromSuperview()
            self.imageView.alpha = 1
            self.contentView.alpha = 1
            if self.currentCellType == .Video {
                self.playBtn.isHidden = false
                self.playBtn.isUserInteractionEnabled = true
            } else {
                self.playBtn.isHidden = true
                self.playBtn.isUserInteractionEnabled = false
            }
        }
    }
}

//MARK: Image handling logic
extension PTMediaBrowserCell {
    func setImageTypeView(url:String, currentID: UUID) {
        clearContentView()
        playBtn.isHidden = true
        playBtn.isUserInteractionEnabled = false
        baseLoadImageData(imageData: url, currentID: currentID)
    }

    private func baseLoadImageData(imageData:Any, currentID: UUID) {
        imageView.loadImage(contentData: imageData, iCloudDocumentName: viewConfig.iCloudDocumentName, emptyImage: UIImage()) { receivedSize, totalSize in
            guard totalSize > 0 else { return }
            self.loading.progress = CGFloat(receivedSize) / CGFloat(totalSize)
        } loadFinish: { value in
            guard self.loadIdentifier == currentID else { return }
            self.handleImageLoadFinish(result: value)
        }
    }

    private func handleImageLoadFinish(result:PTLoadImageResult) {
        if let images = result.allImages, images.count > 1 {
            currentCellType = .GIF
            gifImage = UIImage.animatedImage(with: images, duration: result.loadTime)
            if viewConfig.dynamicBackground {
                backgroundImageView.image = result.firstImage
            }
        } else if let images = result.allImages, images.count == 1 {
            currentCellType = .Normal
            gifImage = result.firstImage
            if viewConfig.dynamicBackground {
                backgroundImageView.image = images.first
            }
        } else {
            currentCellType = .None
            createReloadButton()
        }
        adjustFrame()
        hideLoading()
    }
}

//MARK: Video handling logic
extension PTMediaBrowserCell {
    func videoUrlLoad(url:String, currentID: UUID) {
        self.videoOriginalItem = url
        imageView.image = UIImage()
        gifImage = nil
        reloadButton.isHidden = true
        reloadButton.isUserInteractionEnabled = false
        playBtn.isHidden = true
        playBtn.isUserInteractionEnabled = false
        handleVideoLoading(videoUrl: url, currentID: currentID)
    }

    func handleVideoLoading(videoUrl: String, currentID: UUID) {
        if let url = URL(string: videoUrl) {
            PTVideoManager.shared.getVideoItem(for: url.absoluteString,autoCacheVideo: true) { item in
                PTGCDManager.shared.runOnMain {
                    guard self.loadIdentifier == currentID else { return }
                    if let findImage = item.coverImage {
                        self.hideLoading()
                        self.setupVideoView(image: findImage, videoUrl: videoUrl)
                    } else {
                        self.handleVideoLoadError()
                    }
                }
            } videoReady: { item in
                PTGCDManager.shared.runOnMain {
                    guard self.loadIdentifier == currentID else { return }
                    self.videoCacheURL = item.localVideoURL
                }
            }
        } else {
            self.handleVideoLoadError()
        }
    }
    
    private func setupVideoView(image: UIImage, videoUrl: String) {
        currentCellType = .Video
        hideLoading()
        
        playBtn.isHidden = false
        playBtn.isUserInteractionEnabled = true
        
        gifImage = image
        imageView.image = image
        adjustFrame()
        if viewConfig.dynamicBackground {
            backgroundImageView.image = image
        }
        
        reloadButton.isHidden = true
        reloadButton.isUserInteractionEnabled = false
    }
    
    func videoPlay() {
        let videoController = PTPlayerViewController()
        switch self.videoOriginalItem {
        case let videoURL as String:
            if let findLocal = self.videoCacheURL {
                videoController.videoPlayer = AVPlayer(url: findLocal)
                self.videoPlayHandler?(videoController)
            } else {
                if let url = URL(string: videoURL) {
                    // English: Start remote playback immediately; PTVideoManager caches the same URL in parallel.
                    // Español: Inicia la reproducción remota de inmediato; PTVideoManager almacena la misma URL en paralelo.
                    // 中文：立即开始远程播放；PTVideoManager 会并行缓存同一个 URL。
                    videoController.videoPlayer = AVPlayer(url: url)
                    self.videoPlayHandler?(videoController)
                } else {
                    PTNSLogConsole("Video url error")
                }
            }
        case let avItem as AVPlayerItem:
            videoController.videoPlayer = AVPlayer(playerItem: avItem)
            self.videoPlayHandler?(videoController)
        default:
            PTNSLogConsole("Video item error")
        }
    }
    
    private func handleVideoLoadError() {
        gifImage = nil
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage()
        currentCellType = .None
        hideLoading()
        createReloadButton()
    }
    
    private func videoAVItem(avItem: AVPlayerItem, currentID: UUID) {
        reloadButton.isHidden = true
        imageView.image = UIImage()
        gifImage = nil
        avItem.generateThumbnail { image in
            Task { @MainActor in
                guard self.loadIdentifier == currentID else { return }
                if image != nil {
                    self.currentCellType = .Video
                    self.hideLoading()
                    self.gifImage = image
                    self.imageView.image = image
                    self.adjustFrame()
                    if self.viewConfig.dynamicBackground {
                        self.backgroundImageView.image = image
                    }
                    self.playBtn.isHidden = false
                    self.playBtn.isUserInteractionEnabled = true
                } else {
                    self.playBtn.isHidden = true
                    self.playBtn.isUserInteractionEnabled = false
                    self.gifImage = nil
                    self.imageView.contentMode = .scaleAspectFit
                    self.imageView.image = UIImage()
                    self.currentCellType = .None
                    self.hideLoading()
                    self.createReloadButton()
                }
            }
        }
    }
}

extension PTMediaBrowserCell:UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        // MARK: - 3. 动态返回需要缩放的 View，支持 LivePhoto
        return currentCellType == .LivePhoto ? livePhoto : imageView
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        zoomImageSize = view?.frame.size
        scrollOffset = scrollView.contentOffset
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // MARK: - 4. 确保缩放时，图片或 LivePhoto 都能正确居中
        let centerPoint = PTMediaBrowserCell.centerOfScrollVIewContent(scrollView: scrollView)
        if currentCellType == .LivePhoto {
            livePhoto.center = centerPoint
        } else {
            imageView.center = centerPoint
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollOffset = scrollView.contentOffset
    }
}

extension PTMediaBrowserCell : PHLivePhotoViewDelegate { }

extension PTMediaBrowserCell {
    private func showLoading() {
        loading.isHidden = false
    }

    private func hideLoading() {
        loading.isHidden = true
    }
    
    func createReloadButton() {
        reloadButton.isHidden = false
        reloadButton.isUserInteractionEnabled = true
        bringSubviewToFront(reloadButton)
        playBtn.isHidden = true
        
        let viewportWidth = contentScrolView.bounds.width > 0 ? contentScrolView.bounds.width : contentView.bounds.width
        let reloadMaxWidth = max(1, viewportWidth - PTAppBaseConfig.share.defaultViewSpace * 2)
        reloadButton.setTitle(self.viewConfig.imageReloadButton, for: .normal)
        var reloadWidth = reloadButton.sizeFor(height: 34).width + 16
        var baseHeight:CGFloat = 34
        if reloadWidth > reloadMaxWidth {
            reloadWidth = reloadMaxWidth
            baseHeight = reloadButton.sizeFor(lineSpacing: 2.5,width: reloadMaxWidth).height + 16
        }
        reloadButton.snp.remakeConstraints { make in
            make.width.equalTo(reloadWidth)
            make.height.equalTo(baseHeight)
            make.center.equalTo(contentScrolView)
        }
    }
}
