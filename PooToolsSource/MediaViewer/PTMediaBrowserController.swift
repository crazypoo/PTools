//
//  PTMediaBrowserController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import AttributedString
#if POOTOOLS_VIDEOCACHE
import KTVHTTPCache
#endif

let numberOfVisibleLines = 2

@objcMembers
public class PTMediaBrowserController: PTBaseViewController {

    ///界面消失后回调
    public var viewDismissBlock:PTActionTask?

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
                        self.viewDismissBlock?()
                    }
                } else {
                    self.navigationController?.popViewController(animated: true) {
                        self.viewDismissBlock?()
                    }
                }
            } else {
                self.returnFrontVC {
                    self.viewDismissBlock?()
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
        
        if viewConfig.pageControlShow {
            switch viewConfig.pageControlOption {
            case .system:
                if let pageControl = view.pageControlView as? UIPageControl {
                    pageControl.addPageControlHandlers { [weak self] sender in
                        guard let self = self else { return }
                        // MARK: -  加入安全边界检查，防止越界崩溃
                        guard sender.currentPage < self.mediaData.count else { return }
                        let cellModel = self.mediaData[sender.currentPage]
                        self.updateBottom(models: cellModel)
                        self.newCollectionView.scrolToItem(indexPath: IndexPath(row: sender.currentPage, section: 0), position: .right)
                    }
                }
            default: break
            }
        }
        view.pageControlView.isHidden = !viewConfig.pageControlShow
        view.moreActionButton.addActionHandlers(handler: { [weak self] sender in
            guard let self = self else { return }
            self.moreAction(sender: self.bottomControl.moreActionButton)
        })
        return view
    }()
    
    fileprivate lazy var newCollectionView : PTCollectionView = {
        let cellHeight = CGFloat.kSCREEN_HEIGHT
        let cellWidth = CGFloat.kSCREEN_WIDTH
        let cConfig = PTCollectionViewConfig()
        cConfig.viewType = .Custom
        cConfig.collectionViewBehavior = .paging
        
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
                    self?.returnFrontVC {
                        self?.viewDismissBlock?()
                    }
                }
                cell.zoomTask = { [weak self] boolValue in
                    self?.toolBarControl(hide: boolValue)
                }
                cell.tapTask = { [weak self] in
                    guard let self = self else { return }
                    self.toolBarControl(hide: !self.navControl.isHidden)
                }
                cell.longTapWakeUp = { [weak self] in
                    guard let self = self else { return }
                    self.toolBarControl(hide: true)
                    self.moreAction(sender: self.bottomControl.moreActionButton)
                    PTGCDManager.gcdAfter(time: 0.5) {
                        cell.imageLongTaped = false
                    }
                }
                cell.videoPlayHandler = { [weak self] videoController in
                    videoController.modalPresentationStyle = .fullScreen
                    videoController.onCloseTapped = {
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
                    let current = PTUtils.getCurrentVC()
                    if let _ = current?.sheetViewController {
                        current?.navigationController?.pushViewController(videoController, completion: {
                            videoController.videoPlayer?.play()
                            videoController.sheetViewController?.setSizes([.fullscreen])
                        })
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
        
        collectionView.customerLayout = { sectionIndex, sectionModel in
            return UICollectionView.horizontalLayoutSystem(data: sectionModel.rows, itemOriginalX: 0, itemWidth: cellWidth, itemHeight: cellHeight, topContentSpace: 0, bottomContentSpace: 0, itemLeadingSpace: 0)
        }
        
        collectionView.collectionDidEndDisplay = { [weak self] collectionView, cell, sectionModel, indexPath in
            guard let self = self else { return }
            if let currentCell = collectionView.visibleCells.first as? PTMediaBrowserCell, let currentIndex = collectionView.indexPath(for: currentCell) {
                if let _ = sectionModel.rows?[currentIndex.row], let endCell = cell as? PTMediaBrowserCell {
                    
                    guard currentIndex.row < self.mediaData.count else { return }
                    let cellModel = self.mediaData[currentIndex.row]
                    switch endCell.currentCellType {
                    case .GIF:
                        endCell.imageView.stopAnimating()
                    default: break
                    }
                    
                    if self.viewConfig.pageControlShow {
                        self.pageControlProgressSet(indexPath: currentIndex)
                    }
                    self.currentIndex = currentIndex.row
                    
                    if !self.navControl.titleLabel.isHidden {
                        self.navControl.titleLabel.text = "\(currentIndex.row + 1)/\(self.mediaData.count)"
                    }
                    self.updateBottom(models: cellModel)
                }
            }
        }
        
        collectionView.collectionWillDisplay = { [weak self] collectionView, cell, sectionModel, indexPath in
            guard let self = self else { return }
            if self.viewConfig.pageControlShow {
                self.pageControlProgressSet(indexPath: indexPath)
            }
            self.currentIndex = indexPath.row

            if let _ = sectionModel.rows?[indexPath.row], let endCell = cell as? PTMediaBrowserCell {
                guard indexPath.row < self.mediaData.count else { return }
                let cellModel = self.mediaData[indexPath.row]
                switch endCell.currentCellType {
                case .GIF:
                    endCell.imageView.startAnimating()
                default: break
                }
                if !self.navControl.titleLabel.isHidden {
                    self.navControl.titleLabel.text = "\(indexPath.row + 1)/\(self.mediaData.count)"
                }
                self.updateBottom(models: cellModel)
                
                self.browserCurrentDataBlock?(indexPath.row)
            }
        }
        
        collectionView.collectionViewDidScroll = { [weak self] collectionViewScrol in
            guard let self = self else { return }
            let currentPageControlValue = self.getPageControlCurrentValue()
            guard currentPageControlValue < self.mediaData.count else { return }
            
            if let currentCell = collectionViewScrol.visibleCells.first as? PTMediaBrowserCell {
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
    
    public init(mediaData: [PTMediaBrowserModel]) {
        self.mediaData = mediaData
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
        UIView.animate(withDuration: 0.3) {
            self.changeStatusBar(type: .Dark)
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIView.animate(withDuration: 0.3) {
            self.changeStatusBar(type: .Auto)
        }
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
            make.height.equalTo(CGFloat.kTabbarSaveAreaHeight + pageControlHeight + BottomTopSpacing + BottomMoreHeight)
        }
                
        // MARK: -  取消不必要的硬编码延时，提早设置初始状态
        currentIndex = min(viewConfig.defultIndex, max(0, mediaData.count - 1))
        if !mediaData.isEmpty {
            updateBottom(models: mediaData[currentIndex])
        }
        
        self.showCollectionViewData()
    }
    
    func showCollectionViewData(loadedTask:PTCollectionCallback? = nil) {
        PTGCDManager.gcdGobal {
            
            if self.mediaData.count > 1 {
                PTGCDManager.gcdMain {
                    self.bottomControl.pageControlView.isHidden = !self.viewConfig.pageControlShow
                    if self.viewConfig.pageControlShow {
                        self.setPageControlValue(0)
                    }
                }
            } else {
                PTGCDManager.gcdMain {
                    self.bottomControl.pageControlView.isHidden = true
                }
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
            
            PTGCDManager.gcdMain {
                self.navControl.titleLabel.isHidden = false
                self.navControl.titleLabel.text = "1/\(self.mediaData.count)"

                self.newCollectionView.showCollectionDetail(collectionData: sections) { [weak self] collectionView in
                    guard let self = self else { return }
                    if !self.firstLoad {
                        self.firstLoad = true
                        let loadSome = min(self.viewConfig.defultIndex, max(0, self.mediaData.count - 1))
                        self.currentIndex = loadSome
                        collectionView.safeScrollToItem(at: IndexPath(row: loadSome, section: 0), at: .right, animated: false)
                    } else {
                        loadedTask?(collectionView)
                    }
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
            PTGCDManager.gcdAfter(time: 0.35) {
                let loadSome = min(self.viewConfig.defultIndex, max(0, self.mediaData.count - 1))
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
                guard let self = self else { return }
                guard let cell = self.newCollectionView.visibleCells().first as? PTMediaBrowserCell else { return }
                self.handleAction(at: index, gifImage: cell.gifImage)
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
            loadingView.hudShow(hudSize: .init(width: CGFloat.kSCREEN_WIDTH * 0.5, height: CGFloat.kSCREEN_WIDTH * 0.5))
            
            if let findCurrentLocal = PTVideoFileCache.shared.cachedFileURL(for: urlReal) {
                loadingView.removeFromSuperview()
                self.saveVideo(videoPath: findCurrentLocal.path,videoOrURL: url)
            } else {
                PTVideoManager.shared.getVideoItem(for: urlReal.absoluteString,autoCacheVideo: true) { _, _, progress in
                    loadingView.progress = progress
                } coverReady: { item in
                    
                } videoReady: { [weak self] item in
                    loadingView.hudHide()
                    if let findLocal = item.localVideoURL {
                        self?.saveVideo(videoPath: findLocal.path,videoOrURL: url)
                    } else {
                        self?.viewSaveImageBlock?(false)
                    }
                }
            }
        } else {
            viewSaveImageBlock?(false)
        }
    }
        
    func saveVideo(videoPath:String,videoOrURL:String) {
        let url = NSURL.fileURL(withPath: videoPath)
        let compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path)
        if compatible {
            UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, #selector(self.save(image:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            if let urlReal = URL(string: videoOrURL) {
                PTVideoFileCache.shared.prepareVideo(url: urlReal,completion: { _ in })
            }
            viewSaveImageBlock?(compatible)
        }
    }
    
    func saveImageToPhotos(saveImage:UIImage) {
        UIImageWriteToSavedPhotosAlbum(saveImage, self, #selector(self.save(image:didFinishSavingWithError:contextInfo:)), nil)
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
                    
                    PTGCDManager.gcdAfter(time: 0.35) { [weak self] in
                        guard let self = self else { return }
                        let newCurrentPageControlValue = self.getPageControlCurrentValue()
                        self.navControl.titleLabel.text = "\(newCurrentPageControlValue + 1)/\(self.mediaData.count)"

                        if self.mediaData.count > 1 {
                            self.bottomControl.pageControlView.isHidden = !self.viewConfig.pageControlShow
                            self.setPageControlValue(newCurrentPageControlValue)
                        } else {
                            self.bottomControl.pageControlView.isHidden = true
                        }
                        
                        if newCurrentPageControlValue < self.mediaData.count {
                            let models = self.mediaData[newCurrentPageControlValue]
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
    func labelMoreAtt(models:PTMediaBrowserModel) -> ASAttributedString {
        let atts:ASAttributedString = """
        \(wrap: .embedding("""
        \(truncatedText(fullText:models.imageInfo),.foreground(viewConfig.titleColor),.font(viewConfig.viewerFont),.paragraph(.alignment(.left)))\(viewConfig.showMore,.foreground(.systemBlue),.font(viewConfig.viewerFont),.paragraph(.alignment(.left)),.action { [weak self] in
                guard let self = self else { return }
                PTGCDManager.gcdAfter(time: 0.1) {
                    let fullAtts:ASAttributedString = """
                    \(wrap: .embedding("""
                    \(models.imageInfo,.foreground(self.viewConfig.titleColor),.font(self.viewConfig.viewerFont),.paragraph(.alignment(.left)))
                    """))
                    """
                    self.bottomControl.setLabelAtt(att: fullAtts)
                }

                let maskView = UIView()
                maskView.backgroundColor = .DevMaskColor
                self.view.addSubview(maskView)
        
                let tapGes = UITapGestureRecognizer { [weak self] sender in
                    maskView.removeFromSuperview()
                    self?.updateBottom(models: models)
                }
                maskView.addGestureRecognizer(tapGes)
                maskView.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(self.navControl.snp.bottom)
                    make.bottom.equalTo(self.bottomControl.snp.top)
                }
        
                let pageControlHeight = self.viewConfig.pageControlShow ? (PageControlBottomSpace + PageControlHeight + BottomItemSpacing) : 0

                self.bottomControl.snp.updateConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                    make.height.equalTo(self.heightForString(models.imageInfo) + CGFloat.kTabbarSaveAreaHeight + pageControlHeight + BottomTopSpacing)
                }
        })
        """))
        """
        return atts
    }
    
    func updateBottom(models:PTMediaBrowserModel) {
                
        let pageControlHeight = self.viewConfig.pageControlShow ? (PageControlBottomSpace + PageControlHeight + BottomItemSpacing) : 0
        var bottomH:CGFloat = CGFloat.kTabbarSaveAreaHeight + pageControlHeight + BottomTopSpacing
        if models.imageInfo.stringIsEmpty() {
            bottomControl.setLabelAtt(att: ASAttributedString(stringLiteral: ""))
            switch viewConfig.actionType {
            case .Empty:break
            default:
                bottomH += BottomMoreHeight
            }
        } else {
            if numberOfLines(models.imageInfo) > numberOfVisibleLines {
                bottomH = heightForString(truncatedText(fullText:models.imageInfo) + viewConfig.showMore) + CGFloat.kTabbarSaveAreaHeight + pageControlHeight + BottomTopSpacing
                bottomControl.setLabelAtt(att: labelMoreAtt(models: models))
            } else {
                var textH:CGFloat = heightForString(models.imageInfo)
                if textH < 44 {
                    textH = 44
                }
                
                let atts:ASAttributedString = """
                \(wrap: .embedding("""
                \(truncatedText(fullText:models.imageInfo),.foreground(viewConfig.titleColor),.font(viewConfig.viewerFont),.paragraph(.alignment(.left)))
                """))
                """

                bottomControl.setLabelAtt(att: atts)
                bottomH = textH + CGFloat.kTabbarSaveAreaHeight + pageControlHeight + BottomTopSpacing
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
        var labelW:CGFloat = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2

        switch viewConfig.actionType {
        case .Empty:break
        default:
            labelW -= (ContentMoreSpacing - BottomMoreHeight)
        }
        return labelW
    }
    
     func numberOfLines(_ string: String) -> Int {
         string.numberOfLines(font: viewConfig.viewerFont, labelShowWidth: labelContentWidth(), lineSpacing: 2)
    }
    
    func truncatedText(fullText:String) -> String {
        fullText.truncatedText(maxLineNumber: numberOfVisibleLines, font: viewConfig.viewerFont, labelShowWidth: labelContentWidth())
    }
}
