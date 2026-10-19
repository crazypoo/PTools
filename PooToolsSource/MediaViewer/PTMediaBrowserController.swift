//
//  PTMediaBrowserController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
#if SWIFT_PACKAGE
import ptools
#endif
#if canImport(PToolsUIFoundation)
import PToolsUIFoundation
#endif
#if SWIFT_PACKAGE
import PooToolsPageControl
import PooToolsProgressBar
#endif

let numberOfVisibleLines = 2

@objcMembers
public class PTMediaBrowserController: PTBaseViewController {

    // English: MediaViewer owns the full-screen canvas so the iOS 27 vertical system rail cannot shrink paging cells.
    // Español: MediaViewer controla el lienzo de pantalla completa para que la barra vertical de iOS 27 no reduzca las celdas paginadas.
    // 中文：MediaViewer 使用完整屏幕画布，避免 iOS 27 系统纵向栏缩小分页 Cell 的宽度。
    @available(iOS 27.1, *)
    public override var preferredVerticalBarBehavior: UIVerticalBarBehavior {
        .disabled
    }

    ///界面消失后回调
    public var viewDismissBlock:PTActionTask?

    public var defaultIndex: Int = 0
    
    ///界面配置
    fileprivate let viewConfig = PTMediaBrowserConfig.share
    
    ///更多按钮操作
    public var viewMoreActionBlock:PTViewerEXIndexBlock?
    ///保存回调
    public var viewSaveImageBlock:PTViewerSaveBlock?
    ///删除回调
    public var viewDeleteImageBlock:PTViewerIndexBlock?
    
    ///查看到哪儿
    public var browserCurrentDataBlock:((Int)->Void)?

    fileprivate var firstLoad:Bool = false
    fileprivate var hideToolBar:Bool = false
    fileprivate var currentIndex:Int = 0
    private var lastReportedPageIndex: Int?
    private var lastAdaptiveContentLayoutSignature: String?

    fileprivate var actionSheetTitle:[String] = []

    fileprivate lazy var navControl:PTMediaBrowserNav = {
        let view = PTMediaBrowserNav()
        view.titleLabel.font = self.viewConfig.titleFont
        view.titleLabel.textColor = self.viewConfig.titleColor
        view.closeButton.setImage(self.viewConfig.closeViewerImage, for: .normal)
        // MARK: -  修复循环引用，避免 Controller 无法释放
        view.closeButton.addActionHandlers { [weak self] _ in
            guard let self = self else { return }
            if let sheet = self.sheetViewController {
                if self.navigationController?.viewControllers.first == self {
                    self.returnFrontVC {
                        Task { @MainActor in
                            self.viewDismissBlock?()
                        }
                    }
                } else {
                    self.navigationController?.popViewController(animated: true)
                    self.viewDismissBlock?()
                }
            } else {
                Task { @MainActor in
                    self.returnFrontVC {
                        Task { @MainActor in
                            self.viewDismissBlock?()
                        }
                    }
                }
            }
        }
        return view
    }()
    
    fileprivate lazy var bottomControl:PTMediaBrowserBottom = {
        let view = PTMediaBrowserBottom()
        switch self.viewConfig.actionType {
        case .Empty:
            view.moreActionButton.isHidden = true
            view.moreActionButton.isUserInteractionEnabled = false
        default:
            view.moreActionButton.setImage(self.viewConfig.moreActionImage, for: .normal)
            view.moreActionButton.isHidden = false
            view.moreActionButton.isUserInteractionEnabled = true
        }
        view.pageControlView.isHidden = !viewConfig.pageControlShow
        view.moreActionButton.addActionHandlers(handler: { [weak self] sender in
            guard let self = self else { return }
            self.moreAction(sender: self.bottomControl.moreActionButton)
        })
        view.pageTabCallback = { [weak self] index in
            guard let self = self else { return }
            // MARK: -  加入安全边界检查，防止越界崩溃
            guard self.mediaData.indices.contains(index) else { return }
            self.commitCurrentPage(index: index, notify: true)
            self.newCollectionView.scrolToItem(indexPath: IndexPath(row: index, section: 0), position: .right)
        }
        return view
    }()
    
    fileprivate lazy var newCollectionView : PTCollectionView = {
        let cConfig = PTCollectionViewConfig()
        cConfig.viewType = .Custom
        cConfig.collectionViewBehavior = .paging
        // English: Media paging is a fullscreen background layer, so UIKit must not inset the first cell.
        // Español: La paginación multimedia es una capa de fondo a pantalla completa; UIKit no debe insertar el primer cell.
        // 中文：媒体分页属于全屏背景层，UIKit 不应为首个 Cell 自动添加安全区 inset。
        cConfig.contentInsetAdjustmentBehavior = .never
        
        let collectionView = PTCollectionView(viewConfig: cConfig)
        
        // MARK: -  所有闭包引入 [weak self]，防止严重的内存泄漏
        collectionView.cellInCollection = { [weak self] collectionView, dataModel, indexPath in
            guard let self = self else { return nil }
            if let itemRow = dataModel.rows?[indexPath.row], let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.reuseID, for: indexPath) as? PTMediaBrowserCell {
                
                // MARK: -  防止滑动过快导致的数据越界
                guard indexPath.row < self.mediaData.count else { return cell }
                
                let cellModel = self.mediaData[indexPath.row]
                cell.dataModel = cellModel
                cell.viewerDismissBlock = { [weak self] in
                    Task { @MainActor in
                        self?.returnFrontVC {
                            Task { @MainActor in
                                self?.viewDismissBlock?()
                            }
                        }
                    }
                }
                cell.zoomTask = { [weak self] boolValue in
                    Task { @MainActor in
                        self?.toolBarControl(hide: boolValue)
                    }
                }
                cell.tapTask = { [weak self] in
                    guard let self = self else { return }
                    Task { @MainActor in
                        self.toolBarControl(hide: !self.navControl.isHidden)
                    }
                }
                cell.longTapWakeUp = { [weak self] in
                    guard let self = self else { return }
                    Task { @MainActor in
                        self.toolBarControl(hide: true)
                        self.moreAction(sender: self.bottomControl.moreActionButton)
                    }
                }
                cell.videoPlayHandler = { [weak self] videoController in
                    videoController.modalPresentationStyle = .fullScreen
                    videoController.onCloseTapped = {
                        Task { @MainActor in
                            let current = PTUtils.getCurrentVC()
                            if let sheet = current as? PTPlayerViewController {
                                if sheet.checkVCIsPresenting() {
                                    sheet.dismissAnimated()
                                } else {
                                    sheet.navigationController?.popViewController(animated: true)
                                }
                            } else {
                                current?.dismissAnimated()
                            }
                        }
                    }
                    let current = PTUtils.getCurrentVC()
                    if let _ = current?.sheetViewController {
                        current?.navigationController?.pushViewController(videoController, animated: true)
                        videoController.videoPlayer?.play()
                        videoController.sheetViewController?.setSizes([.fullscreen])
                    } else {
                        self?.present(videoController, animated: true) {
                            videoController.videoPlayer?.play()
                        }
                    }
                }
                return cell
            }
            return nil
        }
        
        collectionView.customerLayout = { [weak collectionView] _, sectionModel in
            let effectiveSize = collectionView?.contentCollectionView.bounds.size ?? .zero
            let width = max(1, effectiveSize.width)
            let height = max(1, effectiveSize.height)
            return UICollectionView.horizontalLayoutSystem(data: sectionModel.rows,
                                                           itemOriginalX: 0,
                                                           itemWidth: width,
                                                           itemHeight: height,
                                                           topContentSpace: 0,
                                                           bottomContentSpace: 0,
                                                           itemLeadingSpace: 0)
        }
        
        collectionView.collectionDidEndDisplay = { [weak self] collectionView, cell, sectionModel, indexPath in
            guard let self = self else { return }
            guard indexPath.section == 0,
                  indexPath.item < self.mediaData.count,
                  let endCell = cell as? PTMediaBrowserCell else { return }

            // English: Clean only the cell that actually left the viewport; never use the settled page to invalidate another cell.
            // Español: Limpia solo la celda que realmente salió del viewport; nunca invalida otra celda usando la página estable.
            // 中文：只清理真正离开可视区域的 Cell，不能用当前稳定页索引去失效另一张 Cell。
            if endCell.currentCellType == .GIF {
                endCell.imageView.stopAnimating()
            }
            endCell.invalidateMediaResources()
        }
        
        collectionView.collectionWillDisplay = { [weak self] collectionView, cell, sectionModel, indexPath in
            guard let self = self else { return }
            guard indexPath.section == 0,
                  indexPath.row < self.mediaData.count,
                  let endCell = cell as? PTMediaBrowserCell else { return }

            // English: Display callbacks only control media playback; page state is committed after scrolling settles.
            // Español: Los callbacks de visualización solo controlan la reproducción; el estado se confirma al terminar el desplazamiento.
            // 中文：展示回调只负责媒体播放，页面状态统一在滚动结束后提交。
            if let _ = sectionModel.rows?[indexPath.row] {
                switch endCell.currentCellType {
                case .GIF:
                    endCell.imageView.startAnimating()
                default: break
                }
            }
        }

        // English: Media pages use an orthogonal compositional section, so commit the index from its own page callback.
        // Español: Las páginas multimedia usan una sección composicional ortogonal; confirma el índice desde su callback de página.
        // 中文：媒体页面使用正交 Compositional Section，因此必须从正交分页回调提交索引。
        collectionView.orthogonalPageDidChange = { [weak self] sectionIndex, pageIndex in
            guard let self,
                  sectionIndex == 0,
                  self.mediaData.indices.contains(pageIndex) else { return }
            self.commitCurrentPage(index: pageIndex, notify: true)
        }
        
        collectionView.collectionViewDidScroll = { [weak self] collectionViewScrol in
            guard let self = self else { return }
            let currentPageControlValue = self.getPageControlCurrentValue()
            guard currentPageControlValue < self.mediaData.count else { return }
            
            if let currentCell = collectionViewScrol.cellForItem(at: IndexPath(item: self.currentIndex, section: 0)) as? PTMediaBrowserCell {
                if abs(collectionViewScrol.contentOffset.y) > 0 {
                    currentCell.contentScrolView.isUserInteractionEnabled = false
                    currentCell.contentScrolView.isScrollEnabled = false
                    var delt = 1 - abs(collectionViewScrol.contentOffset.y ) / currentCell.contentView.frame.size.height
                    delt = max(delt, 0)
                    let s = max(delt, 0.5)
                    let translation = CGAffineTransform(translationX: collectionViewScrol.contentOffset.x / s, y: -(collectionViewScrol.contentOffset.y / s))
                    let scale = CGAffineTransform(scaleX: s, y: s)
                    currentCell.tempView.transform = translation.concatenating(scale)
                }
                
                if abs(collectionViewScrol.contentOffset.y) > self.viewConfig.dismissY {
                    currentCell.hideAnimation()
                } else if collectionViewScrol.contentOffset.y == 0 {
                    currentCell.bounceToOriginal()
                    currentCell.contentScrolView.isUserInteractionEnabled = true
                    currentCell.contentScrolView.isScrollEnabled = true
                }
            }
        }
        return collectionView
    }()
    
    ///数据源
    fileprivate var mediaData:[PTMediaBrowserModel] = []
    
    public init(mediaData: [PTMediaBrowserModel], defaultIndex: Int = 0) {
        self.mediaData = mediaData
        self.defaultIndex = defaultIndex
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.becomeFirstResponder()
        self.view.window?.makeKeyAndVisible()
        
        // MARK: -  动画包裹 StatusBar 变更，防止闪烁
        PTGCDManager.shared.delayOnMain(time: 0.35, block: {
            self.changeStatusBar(type: .Dark)
        })
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        PTGCDManager.shared.delayOnMain(time: 0.35, block: {
            self.changeStatusBar(type: .Auto)
        })
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        SwizzleTool.swizzleContextMenuReverseOrder()

        if viewConfig.dynamicBackground {
            view.backgroundColor = viewConfig.viewerContentBackgroundColor
        } else {
            view.backgroundColor = .DevMaskColor
        }
        
        view.addSubviews([newCollectionView,navControl,bottomControl])

        // MARK: -  统一约束布局
        newCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        navControl.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(CGFloat.kNavBarHeight_Total)
        }
        
        let pageControlHeight = viewConfig.pageControlShow ? (PageControlBottomSpace + PageControlHeight + BottomItemSpacing) : 0
        bottomControl.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(bottomSafeAreaInset + pageControlHeight + BottomTopSpacing + BottomMoreHeight)
        }
                
        // MARK: -  取消不必要的硬编码延时，提早设置初始状态
        currentIndex = min(defaultIndex, max(0, mediaData.count - 1))
        defaultIndex = currentIndex
        if !mediaData.isEmpty {
            updateBottom(models: mediaData[currentIndex])
        }
        
        self.showCollectionViewData()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !view.bounds.isEmpty else { return }
        let context = PTAdaptiveBarLayoutContext.make(for: view)
        let region = PTAdaptiveVisibleRegionResolver.region(for: context)
        let horizontalVisibleRect = CGRect(x: region.visibleRect.minX,
                                            y: view.bounds.minY,
                                            width: region.visibleRect.width,
                                            height: view.bounds.height).intersection(view.bounds)
        let hasSystemVerticalPane = context.verticalBarEdge != .unspecified || !region.reservedRects.isEmpty
        let visibleRect: CGRect
        if hasSystemVerticalPane {
            // English: Media is a full-bleed surface on Duo; only foreground controls avoid the reserved rail.
            // Español: El multimedia ocupa toda la superficie en Duo; solo los controles en primer plano evitan la rail reservada.
            // 中文：Duo 上媒体内容使用全屏铺底，只有前景操作控件避开系统保留栏。
            visibleRect = view.bounds
        } else {
            visibleRect = horizontalVisibleRect.isEmpty ? view.bounds : horizontalVisibleRect
        }
        let layoutSignature = "\(region.signature)|\(hasSystemVerticalPane)|\(visibleRect.integral)"
        if layoutSignature != lastAdaptiveContentLayoutSignature {
            lastAdaptiveContentLayoutSignature = layoutSignature
            // English: Keep normal paging behavior while allowing Duo media to fill the host bounds.
            // Español: Conserva el paginado normal y permite que el multimedia Duo llene los límites del host.
            // 中文：普通设备保持原分页行为，Duo 媒体允许铺满宿主边界。
            newCollectionView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(visibleRect.minX)
                make.right.equalToSuperview().inset(max(0, view.bounds.width - visibleRect.maxX))
                make.top.bottom.equalToSuperview()
            }
            // English: Resolve the new host frame before invalidating the custom page geometry.
            // Español: Resuelve el nuevo frame del host antes de invalidar la geometría personalizada de las páginas.
            // 中文：先解析新的宿主 frame，再让自定义分页几何失效，避免沿用旧面板宽度。
            view.layoutIfNeeded()
            newCollectionView.clearLayoutCaches()
            newCollectionView.contentCollectionView.collectionViewLayout.invalidateLayout()
        }
        // English: Re-resolve the bottom surface after safe-area or reserved-region changes.
        // Español: Vuelve a resolver la superficie inferior tras cambios del área segura o regiones reservadas.
        // 中文：安全区或保留区域变化后重新计算底部工具栏位置。
        let pageControlHeight = viewConfig.pageControlShow ? (PageControlBottomSpace + PageControlHeight + BottomItemSpacing) : 0
        let safeBottom = max(0, view.safeAreaInsets.bottom)
        let currentHeight = bottomControl.frame.height
        let minimumHeight = safeBottom + pageControlHeight + BottomTopSpacing + BottomMoreHeight
        if currentHeight > 0, currentHeight < minimumHeight {
            bottomControl.snp.updateConstraints { make in
                make.height.equalTo(minimumHeight)
            }
        }
    }
    
    func showCollectionViewData(loadedTask:PTCollectionCallback? = nil) {
        Task { @MainActor in
            if self.mediaData.count > 1 {
                self.bottomControl.pageControlView.isHidden = !self.viewConfig.pageControlShow
                if self.viewConfig.pageControlShow {
                    let initialIndex = min(self.defaultIndex, max(0, self.mediaData.count - 1))
                    self.setPageControlValue(initialIndex)
                }
            } else {
                self.bottomControl.pageControlView.isHidden = true
            }

            self.actionSheetTitle.removeAll()
            switch self.viewConfig.actionType {
            case .All:
                self.actionSheetTitle = [self.viewConfig.saveDesc,self.viewConfig.deleteDesc]
                self.actionSheetTitle.append(contentsOf: self.viewConfig.moreActionEX.map { $0 })
            case .Save:
                self.actionSheetTitle = [self.viewConfig.saveDesc]
                self.actionSheetTitle.append(contentsOf: self.viewConfig.moreActionEX.map { $0 })
            case .Delete:
                self.actionSheetTitle = [self.viewConfig.deleteDesc]
                self.actionSheetTitle.append(contentsOf: self.viewConfig.moreActionEX.map { $0 })
            case .DIY:
                self.actionSheetTitle.append(contentsOf: self.viewConfig.moreActionEX.map { $0 })
            default:
                break
            }

            var sections = [PTSection]()
            let rows = self.mediaData.compactMap {
                let row = PTRows(dataModel: $0)
                row.cellClass = PTMediaBrowserCell.self
                return row
            }
            let cellSection = PTSection(rows:rows)
            sections.append(cellSection)
            
            self.navControl.titleLabel.isHidden = false
            let initialIndex = min(self.defaultIndex, max(0, self.mediaData.count - 1))
            self.lastReportedPageIndex = nil
            self.commitCurrentPage(index: initialIndex, notify: true)
            
            self.newCollectionView.showCollectionDetail(collectionData: sections) { [weak self = self] collectionView in
                guard let self = self else { return }
                if !self.firstLoad {
                    self.firstLoad = true
                    self.currentIndex = initialIndex
                    collectionView.safeScrollToItem(at: IndexPath(row: initialIndex, section: 0), at: .centeredHorizontally, animated: false)
                    collectionView.layoutIfNeeded()
                } else {
                    loadedTask?(collectionView)
                }
            }
        }
    }
    
    func viewMoreActionDismiss() {
        let currentCell = newCollectionView.visibleCells()
        if let endCell = currentCell.first as? PTMediaBrowserCell {
            switch endCell.currentCellType {
            case .GIF:
                endCell.imageView.stopAnimating()
            default: break
            }
            returnFrontVC()
        }
    }
    
    // MARK: -  丝滑的工具栏显示隐藏动画
    func toolBarControl(hide: Bool) {
        if hide {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
                self.navControl.alpha = 0
                self.bottomControl.alpha = 0
            }) { _ in
                self.navControl.isHidden = true
                self.bottomControl.moreActionButton.isHidden = true
                self.bottomControl.titleLabel.isHidden = true
                self.bottomControl.backgroundColor = .clear
            }
        } else {
            self.navControl.isHidden = false
            self.bottomControl.moreActionButton.isHidden = false
            self.bottomControl.titleLabel.isHidden = false
            self.bottomControl.backgroundColor = MediaBrowserToolBarColor
            
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
                self.navControl.alpha = 1
                self.bottomControl.alpha = 1
            }, completion: nil)
        }
    }
        
    public func mediasShow() {
        self.modalPresentationStyle = .fullScreen
        PTUtils.getCurrentVC()?.pt_present(self)
    }
    
    public func reloadConfig(mediaData:[PTMediaBrowserModel]) {
        self.mediaData = mediaData
        self.defaultIndex = min(self.defaultIndex, max(0, mediaData.count - 1))
        if viewConfig.dynamicBackground {
            view.backgroundColor = viewConfig.viewerContentBackgroundColor
        } else {
            view.backgroundColor = .DevMaskColor
        }
        switch self.viewConfig.actionType {
        case .Empty:
            bottomControl.moreActionButton.isHidden = true
            bottomControl.moreActionButton.isUserInteractionEnabled = false
        default:
            bottomControl.moreActionButton.setImage(self.viewConfig.moreActionImage, for: .normal)
            bottomControl.moreActionButton.isHidden = false
            bottomControl.moreActionButton.isUserInteractionEnabled = true
        }

        newCollectionView.clearAllData(finishTask: { [weak self] _ in
            guard let self = self else { return }
            PTGCDManager.shared.delayOnMain(time: 0.35) {
                let loadSome = min(self.defaultIndex, max(0, self.mediaData.count - 1))
                self.currentIndex = loadSome
                if loadSome < self.mediaData.count {
                    let cellModel = self.mediaData[loadSome]
                    self.updateBottom(models: cellModel)
                }
            }
            self.showCollectionViewData()
        })
    }
}

//MARK: Action&Menu
fileprivate extension PTMediaBrowserController {
    
    func moreAction(sender:ConsoleMenuButton) {
        var actions = [PTEditMenuAction]()
        self.actionSheetTitle.enumerated().forEach { index,value in
            // MARK: -  修复 Action 闭包里的内存泄漏
            let action = PTEditMenuAction(title: value) { [weak self] in
                Task { @MainActor [ weak self] in
                    guard let self = self else { return }
                    guard let cell = self.newCollectionView.visibleCells().first as? PTMediaBrowserCell else { return }
                        self.handleAction(at: index, gifImage: cell.gifImage)
                }
            }
            actions.append(action)
        }
        sender.pt_bindEditMenu(actions: actions)
    }
    
    private func handleAction(at index: Int, gifImage: UIImage?) {
        switch viewConfig.actionType {
        case .Save:
            index == 0 ? saveImage() : executeMoreAction(index: index - 1, image: gifImage)
        case .Delete:
            index == 0 ? deleteImage() : executeMoreAction(index: index - 1, image: gifImage)
        case .All:
            if index == 0 {
                saveImage()
            } else if index == 1 {
                deleteImage()
            } else {
                executeMoreAction(index: index - 2, image: gifImage)
            }
        case .DIY:
            executeMoreAction(index: index, image: gifImage)
        default:
            break
        }
    }

    private func executeMoreAction(index: Int, image: UIImage?) {
        viewMoreActionBlock?(index, image)
        viewMoreActionDismiss()
    }
}

//MARK: Pagecontrol
fileprivate extension PTMediaBrowserController {
    func pageControlProgressSet(indexPath:IndexPath) {
        guard viewConfig.pageControlShow,
              let controllable = bottomControl.pageControlView as? PTPageControllable else { return }
        controllable.setCurrentPage(index: indexPath.row)
    }
    
    func getPageControlCurrentValue() -> Int {
        if viewConfig.pageControlShow,let index = (bottomControl.pageControlView as? PTPageControllable)?.currentPage {
            return index
        } else {
            return self.currentIndex
        }
    }
    
    func setPageControlValue(_ value: Int) {
        guard let control = bottomControl.pageControlView as? PTPageControllable else { return }
        control.update(currentPage: value, totalPages: mediaData.count)
    }
}

//MARK: Media action
fileprivate extension PTMediaBrowserController {
    func saveImage() {
        let currentPageControlValue = self.getPageControlCurrentValue()
        guard currentPageControlValue < mediaData.count else { return }
        
        let model = mediaData[currentPageControlValue]
        
        if let currentView = newCollectionView.visibleCells().first as? PTMediaBrowserCell {
            switch currentView.currentCellType {
            case .Video:
                if let imageUrl = model.imageURL as? String {
                    saveVideoAction(url: imageUrl.urlToUnicodeURLString() ?? "")
                }
            default:
                if let gifImage = currentView.gifImage {
                    saveImageToPhotos(saveImage: gifImage)
                }
            }
        }
    }
    
    func saveVideoAction(url:String) {
        if let urlReal = URL(string: url) {
            let loadingView = PTMediaBrowserLoadingView(type: .LoopDiagram)
            let side = max(1, min(view.bounds.width, view.bounds.height) * 0.5)
            loadingView.hudShow(hudSize: .init(width: side, height: side))
            
            if let findCurrentLocal = PTVideoFileCache.shared.cachedFileURL(for: urlReal) {
                loadingView.removeFromSuperview()
                self.saveVideo(videoPath: findCurrentLocal.path,videoOrURL: url)
            } else {
                PTVideoManager.shared.getVideoItem(for: urlReal.absoluteString,autoCacheVideo: true) { _, _, progress in
                    loadingView.progress = progress
                } coverReady: { item in
                    
                } videoReady: { [weak self] item in
                    Task { @MainActor in
                        loadingView.hudHide()
                        if let findLocal = item.localVideoURL {
                            self?.saveVideo(videoPath: findLocal.path,videoOrURL: url)
                        } else {
                            self?.viewSaveImageBlock?(false)
                        }
                    }
                }
            }
        } else {
            viewSaveImageBlock?(false)
        }
    }
        
    func saveVideo(videoPath:String,videoOrURL:String) {
        let url = URL(fileURLWithPath: videoPath)
        let compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path)
        if compatible {
            PTMediaSaveService.save(videoURL: url) { [weak self] result in
                guard let self else { return }
                if case .success = result {
                    self.viewSaveImageBlock?(true)
                } else {
                    self.viewSaveImageBlock?(false)
                }
            }
        } else {
            if let urlReal = URL(string: videoOrURL) {
                PTVideoFileCache.shared.prepareVideo(url: urlReal,completion: { _ in })
            }
            viewSaveImageBlock?(compatible)
        }
    }
    
    func saveImageToPhotos(saveImage:UIImage) {
        PTMediaSaveService.save(image: saveImage) { [weak self] result in
            guard let self else { return }
            if case .success = result {
                self.viewSaveImageBlock?(true)
            } else {
                self.viewSaveImageBlock?(false)
            }
        }
    }
    
    @objc func save(image:UIImage, didFinishSavingWithError:NSError?,contextInfo:AnyObject) {
        let saveImageBool:Bool = !(didFinishSavingWithError != nil)
        viewSaveImageBlock?(saveImageBool)
    }
    
    func deleteImage() {
        if mediaData.count <= 1 {
            viewDeleteImageBlock?(0)
            viewMoreActionDismiss()
        } else {
            let currentPageControlValue = self.getPageControlCurrentValue()

            if let currentImages = newCollectionView.visibleCells().first as? PTMediaBrowserCell {
                switch currentImages.currentCellType {
                case .GIF:
                    currentImages.imageView.stopAnimating()
                default: break
                }
                
                guard currentPageControlValue < self.newCollectionView.collectionSectionDatas.first?.rows?.count ?? 0 else { return }
                
                if let findIndexRow = self.newCollectionView.collectionSectionDatas.first?.rows?[currentPageControlValue] {
                    self.newCollectionView.deleteRows([findIndexRow], from: 0)
                    self.mediaData.remove(at: currentPageControlValue)
                    
                    PTGCDManager.shared.delayOnMain(time: 0.35) { [weak self] in
                        guard let self = self else { return }
                        let rawCurrentPage = self.getPageControlCurrentValue()
                        let safeCurrentPage = min(rawCurrentPage, self.mediaData.count - 1)
                        
                        self.navControl.titleLabel.text = "\(safeCurrentPage + 1)/\(self.mediaData.count)"
                        
                        if self.mediaData.count > 1 {
                            self.bottomControl.pageControlView.isHidden = !self.viewConfig.pageControlShow
                            self.setPageControlValue(safeCurrentPage)
                        } else {
                            self.bottomControl.pageControlView.isHidden = true
                        }
                        
                        if safeCurrentPage < self.mediaData.count {
                            let models = self.mediaData[safeCurrentPage]
                            self.updateBottom(models: models)
                        }
                    }
                    self.viewDeleteImageBlock?(currentPageControlValue)
                }
            }
        }
    }
}

//MARK: Bottom
fileprivate extension PTMediaBrowserController {
    func labelMoreAtt(models:PTMediaBrowserModel) -> PTRichText {
        let atts:PTRichText = """
        \(wrap: .embedding("""
        \(truncatedText(fullText:models.imageInfo),.foreground(viewConfig.titleColor),.font(viewConfig.viewerFont),.paragraph(.alignment(.left)))\(viewConfig.showMore,.foreground(.systemBlue),.font(viewConfig.viewerFont),.paragraph(.alignment(.left)))
        """))
        """
        return atts
    }

    private func showFullInfo(for models: PTMediaBrowserModel) {
        let fullAtts:PTRichText = """
        \(wrap: .embedding("""
        \(models.imageInfo,.foreground(viewConfig.titleColor),.font(viewConfig.viewerFont),.paragraph(.alignment(.left)))
        """))
        """
        bottomControl.setLabelAtt(att: fullAtts)

        let maskView = UIView()
        maskView.backgroundColor = .DevMaskColor
        view.addSubview(maskView)
        maskView.addGestureRecognizer(UITapGestureRecognizer { [weak self] _ in
            maskView.removeFromSuperview()
            self?.updateBottom(models: models)
        })
        maskView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(navControl.snp.bottom)
            make.bottom.equalTo(bottomControl.snp.top)
        }

        let pageControlHeight = viewConfig.pageControlShow ? (PageControlBottomSpace + PageControlHeight + BottomItemSpacing) : 0
        bottomControl.snp.updateConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(heightForString(models.imageInfo) + bottomSafeAreaInset + pageControlHeight + BottomTopSpacing)
        }
    }
    
    func updateBottom(models:PTMediaBrowserModel) {
                
        let pageControlHeight = self.viewConfig.pageControlShow ? (PageControlBottomSpace + PageControlHeight + BottomItemSpacing) : 0
        var bottomH:CGFloat = bottomSafeAreaInset + pageControlHeight + BottomTopSpacing
        if models.imageInfo.stringIsEmpty() {
            bottomControl.titleTapCallback = nil
            bottomControl.setLabelAtt(att: PTRichText(stringLiteral: ""))
            switch viewConfig.actionType {
            case .Empty:break
            default:
                bottomH += BottomMoreHeight
            }
        } else {
            if numberOfLines(models.imageInfo) > numberOfVisibleLines {
                bottomControl.titleTapCallback = { [weak self] in
                    self?.showFullInfo(for: models)
                }
                bottomH = heightForString(truncatedText(fullText:models.imageInfo) + viewConfig.showMore) + bottomSafeAreaInset + pageControlHeight + BottomTopSpacing
                bottomControl.setLabelAtt(att: labelMoreAtt(models: models))
            } else {
                bottomControl.titleTapCallback = nil
                var textH:CGFloat = heightForString(models.imageInfo)
                if textH < 44 {
                    textH = 44
                }
                
                let atts:PTRichText = """
                \(wrap: .embedding("""
                \(truncatedText(fullText:models.imageInfo),.foreground(viewConfig.titleColor),.font(viewConfig.viewerFont),.paragraph(.alignment(.left)))
                """))
                """

                bottomControl.setLabelAtt(att: atts)
                bottomH = textH + bottomSafeAreaInset + pageControlHeight + BottomTopSpacing
            }
        }
        
        bottomControl.snp.updateConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(bottomH)
        }
    }
    
    func heightForString(_ string: String) -> CGFloat {
        let labelW:CGFloat = labelContentWidth()
        return UIView.sizeFor(string: string, font: viewConfig.viewerFont,lineSpacing: 2, width: labelW).height
    }

    func labelContentWidth() -> CGFloat {
        let hostWidth: CGFloat
        if bottomControl.bounds.width > 0 {
            let region = PTAdaptiveVisibleRegionResolver.region(for: bottomControl)
            hostWidth = region.visibleRect.width > 0 ? region.visibleRect.width : bottomControl.bounds.width
        } else {
            hostWidth = viewIfLoaded?.bounds.width ?? 320
        }
        var labelW:CGFloat = hostWidth - PTAppBaseConfig.share.defaultViewSpace * 2

        guard viewConfig.actionType != .Empty else { return labelW }
        labelW -= ContentMoreSpacing + BottomMoreHeight
        return labelW
    }

    // English: Commit title, page control, toolbar and consumer callbacks from one settled-page source.
    // Español: Confirma el título, el control de páginas, la barra y los callbacks desde una única página estable.
    // 中文：从唯一的稳定页来源统一更新标题、分页控件、工具栏和外部回调。
    private func commitCurrentPage(index: Int, notify: Bool) {
        guard mediaData.indices.contains(index) else { return }
        currentIndex = index
        if viewConfig.pageControlShow {
            setPageControlValue(index)
        }
        if !navControl.titleLabel.isHidden {
            navControl.titleLabel.text = "\(index + 1)/\(mediaData.count)"
        }
        updateBottom(models: mediaData[index])

        guard notify, lastReportedPageIndex != index else { return }
        lastReportedPageIndex = index
        browserCurrentDataBlock?(index)
    }

    private var bottomSafeAreaInset: CGFloat {
        max(0, viewIfLoaded?.safeAreaInsets.bottom ?? 0)
    }
    
     func numberOfLines(_ string: String) -> Int {
         string.numberOfLines(font: viewConfig.viewerFont, labelShowWidth: labelContentWidth(), lineSpacing: 2)
    }
    
    func truncatedText(fullText:String) -> String {
        fullText.truncatedText(maxLineNumber: numberOfVisibleLines, font: viewConfig.viewerFont, labelShowWidth: labelContentWidth())
    }
}
