//
//  PTMediaBrowserController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif
import SwifterSwift
import AttributedString

let numberOfVisibleLines = 2

@objcMembers
public class PTMediaBrowserController: PTBaseViewController {

    ///界面消失后回调
    public var viewDismissBlock:PTActionTask?

    ///界面配置
    public var viewConfig:PTMediaBrowserConfig! {
        didSet {
            showCollectionViewData()
        }
    }
    
    ///更多按钮操作
    public var viewMoreActionBlock:PTViewerIndexBlock?
    ///保存回调
    public var viewSaveImageBlock:PTViewerSaveBlock?
    ///删除回调
    public var viewDeleteImageBlock:PTViewerIndexBlock?
    
    ///查看到哪儿
    public var browserCurrentDataBlock:((Int)->Void)?

    fileprivate var firstLoad:Bool = false
    fileprivate var hideToolBar:Bool = false

    fileprivate var actionSheetTitle:[String] = []

    fileprivate lazy var navControl:PTMediaBrowserNav = {
        let view = PTMediaBrowserNav()
        view.titleLabel.font = self.viewConfig.viewerFont
        view.titleLabel.textColor = self.viewConfig.titleColor
        view.closeButton.setImage(self.viewConfig.closeViewerImage, for: .normal)
        view.closeButton.addActionHandlers { sender in
            self.returnFrontVC {
                if self.viewDismissBlock != nil {
                    self.viewDismissBlock!()
                }
            }
        }
        return view
    }()
    
    fileprivate lazy var bottomControl:PTMediaBrowserBottom = {
        let view = PTMediaBrowserBottom(viewConfig: self.viewConfig)
        switch self.viewConfig.actionType {
        case .Empty:
            view.moreActionButton.isHidden = true
            view.moreActionButton.isUserInteractionEnabled = false
        default:
            view.moreActionButton.setImage(self.viewConfig.moreActionImage, for: .normal)
            view.moreActionButton.isHidden = false
            view.moreActionButton.isUserInteractionEnabled = true
        }
        
        switch viewConfig.pageControlOption {
        case .system:
            (view.pageControlView as! UIPageControl).addPageControlHandlers { sender in
                let cellModel = self.viewConfig.mediaData[sender.currentPage]
                self.updateBottom(models: cellModel)
                self.newCollectionView.scrolToItem(indexPath: IndexPath(row: sender.currentPage, section: 0), position: .right)
            }
        default:
            break
        }
        return view
    }()
    
    fileprivate lazy var newCollectionView : PTCollectionView = {
        let cellHeight = CGFloat.kSCREEN_HEIGHT
        let cellWidth = CGFloat.kSCREEN_WIDTH
        let cConfig = PTCollectionViewConfig()
        cConfig.viewType = .Custom
        cConfig.itemOriginalX = 0
        cConfig.contentTopAndBottom = 0
        cConfig.cellTrailingSpace = 0
        cConfig.cellLeadingSpace = 0
        cConfig.collectionViewBehavior = .paging
        
        let collectionView = PTCollectionView(viewConfig: cConfig)
        collectionView.cellInCollection = { collectionView ,dataModel,indexPath in
            let itemRow = dataModel.rows[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTMediaBrowserCell
            cell.viewConfig = self.viewConfig
            cell.dataModel = (itemRow.dataModel as! PTMediaBrowserModel)
            cell.viewerDismissBlock = {
                self.returnFrontVC {
                    if self.viewDismissBlock != nil {
                        self.viewDismissBlock!()
                    }
                }
            }
            cell.zoomTask = { boolValue in
                self.toolBarControl(boolValue: boolValue)
            }
            cell.tapTask = {
                self.toolBarControl(boolValue: !self.navControl.isHidden)
            }
            return cell
        }
        collectionView.customerLayout = { sectionModel in
            var groupWidth:CGFloat = 0
            var bannerGroupSize : NSCollectionLayoutSize
            var customers = [NSCollectionLayoutGroupCustomItem]()
            sectionModel.rows.enumerated().forEach { (index,model) in
                let cellHeight:CGFloat = cellHeight
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: CGFloat(index) * cellWidth, y: 0, width: cellWidth, height: cellHeight), zIndex: 1000+index)
                customers.append(customItem)
                groupWidth += cellWidth
            }
            bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(groupWidth), heightDimension: NSCollectionLayoutDimension.absolute(cellHeight))
            return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                customers
            })
        }
        
        collectionView.collectionDidEndDisplay = { collectionView,cell,sectionModel,indexPath in
            let itemRow = sectionModel.rows[indexPath.row]
            let cellModel = (itemRow.dataModel as! PTMediaBrowserModel)
            let endCell = cell as! PTMediaBrowserCell
            switch endCell.currentCellType {
            case .GIF:
                endCell.imageView.stopAnimating()
            default:
                break
            }
            
            var currentPageControlValue = 0
            switch self.viewConfig.pageControlOption {
            case .system:
                currentPageControlValue = (self.bottomControl.pageControlView as! UIPageControl).currentPage
            case .fill:
                currentPageControlValue = (self.bottomControl.pageControlView as! PTFilledPageControl).currentPage
            case .pill:
                currentPageControlValue = (self.bottomControl.pageControlView as! PTPillPageControl).currentPage
            case .snake:
                currentPageControlValue = (self.bottomControl.pageControlView as! PTSnakePageControl).currentPage
            case .image:
                currentPageControlValue = (self.bottomControl.pageControlView as! PTImagePageControl).currentPage
            case .scrolling:
                currentPageControlValue = (self.bottomControl.pageControlView as! PTScrollingPageControl).currentPage
            }
            
            if currentPageControlValue == indexPath.row {
                if !self.navControl.titleLabel.isHidden {
                    self.navControl.titleLabel.text = "\(indexPath.row + 1)/\(self.viewConfig.mediaData.count)"
                }
                self.updateBottom(models: cellModel)
            }
        }
        
        collectionView.collectionWillDisplay = { collectionView,cell,sectionModel,indexPath in
            switch self.viewConfig.pageControlOption {
            case .system:
                (self.bottomControl.pageControlView as! UIPageControl).currentPage = indexPath.row
            case .fill:
                (self.bottomControl.pageControlView as! PTFilledPageControl).progress = CGFloat(indexPath.row)
            case .pill:
                (self.bottomControl.pageControlView as! PTPillPageControl).progress = CGFloat(indexPath.row)
            case .snake:
                (self.bottomControl.pageControlView as! PTSnakePageControl).progress = CGFloat(indexPath.row)
            case .image:
                (self.bottomControl.pageControlView as! PTImagePageControl).currentPage = indexPath.row
            case .scrolling:
                (self.bottomControl.pageControlView as! PTScrollingPageControl).progress = CGFloat(indexPath.row)
            }

            let itemRow = sectionModel.rows[indexPath.row]
            let cellModel = (itemRow.dataModel as! PTMediaBrowserModel)
            let endCell = cell as! PTMediaBrowserCell
            switch endCell.currentCellType {
            case .GIF:
                endCell.imageView.startAnimating()
            default:
                break
            }
            if !self.navControl.titleLabel.isHidden {
                self.navControl.titleLabel.text = "\(indexPath.row + 1)/\(self.viewConfig.mediaData.count)"
            }
            self.updateBottom(models: cellModel)
            
            if self.browserCurrentDataBlock != nil {
                self.browserCurrentDataBlock!(indexPath.row)
            }
        }
        
        collectionView.collectionViewDidScroll = { collectionViewScrol in
            var currentPageControlValue = 0
            switch self.viewConfig.pageControlOption {
            case .system:
                currentPageControlValue = (self.bottomControl.pageControlView as! UIPageControl).currentPage
            case .fill:
                currentPageControlValue = (self.bottomControl.pageControlView as! PTFilledPageControl).currentPage
            case .pill:
                currentPageControlValue = (self.bottomControl.pageControlView as! PTPillPageControl).currentPage
            case .snake:
                currentPageControlValue = (self.bottomControl.pageControlView as! PTSnakePageControl).currentPage
            case .image:
                currentPageControlValue = (self.bottomControl.pageControlView as! PTImagePageControl).currentPage
            case .scrolling:
                currentPageControlValue = (self.bottomControl.pageControlView as! PTScrollingPageControl).currentPage
            }
            
            let cellModel = self.viewConfig.mediaData[currentPageControlValue]
            let currentCell = collectionView.visibleCells().first as! PTMediaBrowserCell
            if abs(collectionViewScrol.contentOffset.y) > 0 {
                currentCell.contentScrolView.isUserInteractionEnabled = false
                currentCell.contentScrolView.isScrollEnabled = false
                currentCell.prepareForHide()
                var delt = 1 - abs(collectionViewScrol.contentOffset.y ) / currentCell.contentView.frame.size.height
                delt = max(delt, 0)
                let s = max(delt, 0.5)
                let translation = CGAffineTransform(translationX: collectionViewScrol.contentOffset.x / s, y: collectionViewScrol.contentOffset.y / s)
                let scale = CGAffineTransform(scaleX: s, y: s)
                currentCell.tempView.transform = translation.concatenating(scale)
            }
            
            if abs(collectionViewScrol.contentOffset.y) > 200 {
                currentCell.hideAnimation()
            } else if collectionViewScrol.contentOffset.y == 0 {
                currentCell.bounceToOriginal()
                currentCell.contentScrolView.isUserInteractionEnabled = true
                currentCell.contentScrolView.isScrollEnabled = true
            }
        }
        return collectionView
    }()
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBarBackgroundColorAlpha = 0
        self.zx_hideBaseNavBar = true
#else
        navigationController?.isNavigationBarHidden = true
#endif
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        SwizzleTool().swizzleContextMenuReverseOrder()

        if viewConfig.dynamicBackground {
            view.backgroundColor = viewConfig.viewerContentBackgroundColor
        } else {
            view.backgroundColor = .DevMaskColor
        }
        
        let closeButton = UIButton.init(type: .close)
        closeButton.addActionHandlers(handler: { sender in
            self.returnFrontVC {
                if self.viewDismissBlock != nil {
                    self.viewDismissBlock!()
                }
            }
        })
        
        view.addSubviews([newCollectionView,navControl,bottomControl])

        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        navControl.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(CGFloat.kNavBarHeight_Total)
        }
        
        bottomControl.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(CGFloat.kTabbarHeight_Total)
        }
        
        //MARK: 我都唔知点嗨解,懒加载用唔到,系都要在外部调用,小喇叭
        if #available(iOS 14.0, *) {
            bottomControl.moreActionButton.showsMenuAsPrimaryAction = true
            bottomControl.moreActionButton.menu = makeMenu()
        } else {
            bottomControl.moreActionButton.addActionHandlers { sender in
                UIAlertController.baseActionSheet(title: "PT Media option".localized(), cancelButtonName: "PT Button cancel".localized(),titles: self.actionSheetTitle, otherBlock: { sheet,index,title in
                    switch self.viewConfig.actionType {
                    case .Save:
                        switch index {
                        case 0:
                            self.saveImage()
                        default:
                            if self.viewMoreActionBlock != nil {
                                self.viewMoreActionBlock!(index - 1)
                            }
                            self.viewMoreActionDismiss()
                        }
                    case .Delete:
                        switch index {
                        case 0:
                            self.deleteImage()
                        default:
                            if self.viewMoreActionBlock != nil {
                                self.viewMoreActionBlock!(index - 1)
                            }
                            self.viewMoreActionDismiss()
                        }
                    case .All:
                        switch index {
                        case 0:
                            self.saveImage()
                        case 1:
                            self.deleteImage()
                        default:
                            if self.viewMoreActionBlock != nil {
                                self.viewMoreActionBlock!(index - 2)
                            }
                            self.viewMoreActionDismiss()
                        }
                    case .DIY:
                        if self.viewMoreActionBlock != nil {
                            self.viewMoreActionBlock!(index)
                        }
                        self.viewMoreActionDismiss()
                    default:
                        break
                    }
                })
            }
        }
        
        PTGCDManager.gcdAfter(time: 0.35) {
            var loadSome = 0
            if self.viewConfig.defultIndex > self.viewConfig.mediaData.count {
                loadSome = self.viewConfig.mediaData.count - 1
            } else {
                loadSome = self.viewConfig.defultIndex
            }

            let cellModel = self.viewConfig.mediaData[loadSome]
            self.updateBottom(models: cellModel)
        }        
    }
    
    func showCollectionViewData(loadedTask:((UICollectionView)->Void)? = nil) {
        var sections = [PTSection]()
        
        var rows = [PTRows]()
        viewConfig.mediaData.enumerated().forEach { index,value in
            let row_List = PTRows.init(cls: PTMediaBrowserCell.self, ID: PTMediaBrowserCell.ID,dataModel: value)
            rows.append(row_List)
        }
        let cellSection = PTSection.init(rows: rows)
        sections.append(cellSection)

        PTGCDManager.gcdAfter(time: 0.1) {
            self.newCollectionView.showCollectionDetail(collectionData: sections) { collectionView in
                if !self.firstLoad {
                    self.firstLoad = true
                    var loadSome = 0
                    if self.viewConfig.defultIndex > self.viewConfig.mediaData.count {
                        loadSome = self.viewConfig.mediaData.count - 1
                    } else {
                        loadSome = self.viewConfig.defultIndex
                    }
                    collectionView.scrollToItem(at: IndexPath(row: loadSome, section: 0), at: .right, animated: false)
                } else {
                    if loadedTask != nil {
                        loadedTask!(collectionView)
                    }
                }
            }
        }

        if viewConfig.mediaData.count >= 10 {
            navControl.titleLabel.isHidden = false
            navControl.titleLabel.text = "1/\(viewConfig.mediaData.count)"
        } else {
            navControl.titleLabel.isHidden = true
        }
        
        if viewConfig.mediaData.count > 1 {
            bottomControl.pageControlView.isHidden = false
            switch self.viewConfig.pageControlOption {
            case .system:
                (bottomControl.pageControlView as! UIPageControl).currentPage = 0
                (bottomControl.pageControlView as! UIPageControl).numberOfPages = viewConfig.mediaData.count
            case .fill:
                (bottomControl.pageControlView as! PTFilledPageControl).progress = 0
                (bottomControl.pageControlView as! PTFilledPageControl).pageCount = viewConfig.mediaData.count
            case .pill:
                (bottomControl.pageControlView as! PTPillPageControl).progress = 0
                (bottomControl.pageControlView as! PTPillPageControl).pageCount = viewConfig.mediaData.count
            case .snake:
                (bottomControl.pageControlView as! PTSnakePageControl).progress = 0
                (bottomControl.pageControlView as! PTSnakePageControl).pageCount = viewConfig.mediaData.count
            case .image:
                (bottomControl.pageControlView as! PTImagePageControl).currentPage = 0
                (bottomControl.pageControlView as! PTImagePageControl).numberOfPages = viewConfig.mediaData.count
            case .scrolling:
                (bottomControl.pageControlView as! PTScrollingPageControl).progress = 0
                (bottomControl.pageControlView as! PTScrollingPageControl).pageCount = viewConfig.mediaData.count
            }
        } else {
            bottomControl.pageControlView.isHidden = true
        }

        actionSheetTitle.removeAll()
        switch viewConfig.actionType {
        case .All:
            actionSheetTitle = ["PT Media save".localized(),"PT Media delete".localized()]
            viewConfig.moreActionEX.enumerated().forEach { index,value in
                actionSheetTitle.append(value)
            }
        case .Save:
            actionSheetTitle = ["PT Media save".localized()]
            viewConfig.moreActionEX.enumerated().forEach { index,value in
                actionSheetTitle.append(value)
            }
        case .Delete:
            actionSheetTitle = ["PT Media delete".localized()]
            viewConfig.moreActionEX.enumerated().forEach { index,value in
                actionSheetTitle.append(value)
            }
        case .DIY:
            viewConfig.moreActionEX.enumerated().forEach { index,value in
                actionSheetTitle.append(value)
            }
        default:
            break
        }
    }
    
    func viewMoreActionDismiss() {
        let currentCell = newCollectionView.visibleCells()
        let endCell = currentCell.first as! PTMediaBrowserCell
        switch endCell.currentCellType {
        case .GIF:
            endCell.imageView.stopAnimating()
        default:
            break
        }
        returnFrontVC()
    }
    
    func toolBarControl(boolValue:Bool) {
        navControl.isHidden = boolValue
        bottomControl.moreActionButton.isHidden = navControl.isHidden
        bottomControl.titleLabel.isHidden = navControl.isHidden
        bottomControl.backgroundColor = navControl.isHidden ? .clear : MediaBrowserToolBarColor
    }
    
    @available(iOS 14.0, *)
    func makeMenu() -> UIMenu {
        
        self.bottomControl.moreActionButton.isSelected = false
        
        var debugActions: [UIMenuElement] = []
        self.actionSheetTitle.enumerated().forEach { index,value in
            let menuActions = UIAction(title: value) { _ in
                switch self.viewConfig.actionType {
                case .Save:
                    switch index {
                    case 0:
                        self.saveImage()
                    default:
                        if self.viewMoreActionBlock != nil {
                            self.viewMoreActionBlock!(index - 1)
                        }
                        self.viewMoreActionDismiss()
                    }
                case .Delete:
                    switch index {
                    case 0:
                        self.deleteImage()
                    default:
                        if self.viewMoreActionBlock != nil {
                            self.viewMoreActionBlock!(index - 1)
                        }
                        self.viewMoreActionDismiss()
                    }
                case .All:
                    switch index {
                    case 0:
                        self.saveImage()
                    case 1:
                        self.deleteImage()
                    default:
                        if self.viewMoreActionBlock != nil {
                            self.viewMoreActionBlock!(index - 2)
                        }
                        self.viewMoreActionDismiss()
                    }
                case .DIY:
                    if self.viewMoreActionBlock != nil {
                        self.viewMoreActionBlock!(index)
                    }
                    self.viewMoreActionDismiss()
                default:
                    break
                }
            }
            debugActions.append(menuActions)
        }
        
        var menuContent: [UIMenuElement] = []
                
        menuContent.append(contentsOf: debugActions)
        
        return UIMenu(title: "", children: menuContent)
    }

}

fileprivate extension PTMediaBrowserController {
    func saveImage() {
        
        var currentPageControlValue = 0
        switch self.viewConfig.pageControlOption {
        case .system:
            currentPageControlValue = (bottomControl.pageControlView as! UIPageControl).currentPage
        case .fill:
            currentPageControlValue = (bottomControl.pageControlView as! PTFilledPageControl).currentPage
        case .pill:
            currentPageControlValue = (bottomControl.pageControlView as! PTPillPageControl).currentPage
        case .snake:
            currentPageControlValue = (bottomControl.pageControlView as! PTSnakePageControl).currentPage
        case .image:
            currentPageControlValue = (bottomControl.pageControlView as! PTImagePageControl).currentPage
        case .scrolling:
            currentPageControlValue = (bottomControl.pageControlView as! PTScrollingPageControl).currentPage
        }

        let model = viewConfig.mediaData[currentPageControlValue]
        
        let currentView = newCollectionView.visibleCells().first as! PTMediaBrowserCell
        switch currentView.currentCellType {
        case .Video:
            saveVideoAction(url: model.imageURL as! String)
        default:
            saveImageToPhotos(saveImage: currentView.gifImage!)
        }
    }
    
    func saveVideoAction(url:String) {
        let currentMediaView = newCollectionView.visibleCells().first as! PTMediaBrowserCell
        let loadingView = PTMediaBrowserLoadingView.init(type: .LoopDiagram)
        currentMediaView.contentView.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.width.equalTo(currentMediaView.frame.size.width * 0.5)
            make.height.equalTo(currentMediaView.frame.size.height * 0.5)
            make.centerX.centerY.equalToSuperview()
        }
        
        let documentDirectory = FileManager.pt.DocumnetsDirectory()
        let fullPath = documentDirectory + "/\(String.currentDate(dateFormatterString: "yyyy-MM-dd_HH:mm:ss")).mp4"
        _ = PTFileDownloadApi(fileUrl: url, saveFilePath: fullPath) { bytesRead, totalBytesRead, progress in
            PTGCDManager.gcdMain {
                loadingView.progress = progress
            }
        } success: { reponse in
            loadingView.removeFromSuperview()
            self.saveVideo(videoPath: fullPath)
        } fail: { error in
        }
    }
    
    func saveVideo(videoPath:String) {
        let url = NSURL.fileURL(withPath: videoPath)
        let compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path)
        if compatible {
            UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, #selector(save(image:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            if viewSaveImageBlock != nil {
                viewSaveImageBlock!(compatible)
            }
        }
    }
    
    func saveImageToPhotos(saveImage:UIImage) {
        UIImageWriteToSavedPhotosAlbum(saveImage, self, #selector(save(image:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func save(image:UIImage, didFinishSavingWithError:NSError?,contextInfo:AnyObject) {
            
        var saveImageBool:Bool? = false
        if didFinishSavingWithError != nil {
            saveImageBool = false
        } else {
            saveImageBool = true
        }
        
        if viewSaveImageBlock != nil {
            viewSaveImageBlock!(saveImageBool!)
        }
    }
    
    func deleteImage() {
        if viewConfig.mediaData.count == 1 {
            if viewDeleteImageBlock != nil {
                viewDeleteImageBlock!(0)
            }
            viewMoreActionDismiss()
        } else {
            var currentPageControlValue = 0
            switch self.viewConfig.pageControlOption {
            case .system:
                currentPageControlValue = (bottomControl.pageControlView as! UIPageControl).currentPage
            case .fill:
                currentPageControlValue = (bottomControl.pageControlView as! PTFilledPageControl).currentPage
            case .pill:
                currentPageControlValue = (bottomControl.pageControlView as! PTPillPageControl).currentPage
            case .snake:
                currentPageControlValue = (bottomControl.pageControlView as! PTSnakePageControl).currentPage
            case .image:
                currentPageControlValue = (bottomControl.pageControlView as! PTImagePageControl).currentPage
            case .scrolling:
                currentPageControlValue = (bottomControl.pageControlView as! PTScrollingPageControl).currentPage
            }

            let index = currentPageControlValue
            let currentImages = newCollectionView.visibleCells().first as! PTMediaBrowserCell
            switch currentImages.currentCellType {
            case .GIF:
                currentImages.imageView.stopAnimating()
            default:
                break
            }
            
            UIView.animate(withDuration: 0.1) {
                var newIndex = index - 1
                if newIndex < 0 {
                    newIndex = 0
                } else if newIndex == 0 {
                    newIndex = 0
                }
                    
                self.newCollectionView.scrolToItem(indexPath: IndexPath(row: newIndex, section: 0), position: .right)
                self.viewConfig.mediaData.remove(at: index)

                var textIndex = newIndex + 1
                PTGCDManager.gcdAfter(time: 0.35) {
                    self.showCollectionViewData { reloadCollectionView in
                        if textIndex == 0 {
                            textIndex = 1
                        }
                        self.navControl.titleLabel.text = "\(textIndex)/\(self.viewConfig.mediaData.count)"

                        if self.viewConfig.mediaData.count > 1 {
                            self.bottomControl.pageControlView.isHidden = false
                            switch self.viewConfig.pageControlOption {
                            case .system:
                                (self.bottomControl.pageControlView as! UIPageControl).currentPage = newIndex
                                (self.bottomControl.pageControlView as! UIPageControl).numberOfPages = self.viewConfig.mediaData.count
                            case .fill:
                                (self.bottomControl.pageControlView as! PTFilledPageControl).progress = CGFloat(newIndex)
                                (self.bottomControl.pageControlView as! PTFilledPageControl).pageCount = self.viewConfig.mediaData.count
                            case .pill:
                                (self.bottomControl.pageControlView as! PTPillPageControl).progress = CGFloat(newIndex)
                                (self.bottomControl.pageControlView as! PTPillPageControl).pageCount = self.viewConfig.mediaData.count
                            case .snake:
                                (self.bottomControl.pageControlView as! PTSnakePageControl).progress = CGFloat(newIndex)
                                (self.bottomControl.pageControlView as! PTSnakePageControl).pageCount = self.viewConfig.mediaData.count
                            case .image:
                                (self.bottomControl.pageControlView as! PTImagePageControl).currentPage = newIndex
                                (self.bottomControl.pageControlView as! PTImagePageControl).numberOfPages = self.viewConfig.mediaData.count
                            case .scrolling:
                                (self.bottomControl.pageControlView as! PTScrollingPageControl).progress = CGFloat(newIndex)
                                (self.bottomControl.pageControlView as! PTScrollingPageControl).pageCount = self.viewConfig.mediaData.count
                            }
                        } else {
                            self.bottomControl.pageControlView.isHidden = true
                        }
                        
                        let models = self.viewConfig.mediaData[newIndex]
                        self.updateBottom(models: models)
                    }
                }

                if self.viewDeleteImageBlock != nil {
                    self.viewDeleteImageBlock!(currentPageControlValue)
                }
            }
        }
    }

    func labelMoreAtt(models:PTMediaBrowserModel) ->ASAttributedString {
        let atts:ASAttributedString = """
        \(wrap: .embedding("""
        \(truncatedText(fullText:models.imageInfo),.foreground(viewConfig.titleColor),.font(viewConfig.viewerFont),.paragraph(.alignment(.left)))\(viewConfig.showMore,.foreground(.systemBlue),.font(viewConfig.viewerFont),.paragraph(.alignment(.left)),.action {
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
        
                let tapGes = UITapGestureRecognizer { sender in
                    maskView.removeFromSuperview()
                    self.updateBottom(models: models)
                }
                maskView.addGestureRecognizer(tapGes)
                maskView.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(self.navControl.snp.bottom)
                    make.bottom.equalTo(self.bottomControl.snp.top)
                }
        
                self.bottomControl.snp.updateConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                    make.height.equalTo(self.heightForString(models.imageInfo) + CGFloat.kTabbarSaveAreaHeight + PageControlHeight + PageControlBottomSpace + 10)
                }
        })
        """))
        """
        return atts
    }
    
    func updateBottom(models:PTMediaBrowserModel) {
                
        var bottomH:CGFloat = 0
        if models.imageInfo.stringIsEmpty() {
            bottomControl.setLabelAtt(att: ASAttributedString(stringLiteral: ""))
            switch viewConfig.actionType {
            case .Empty:
                bottomH = CGFloat.kTabbarSaveAreaHeight + PageControlHeight + PageControlBottomSpace + 10
            default:
                bottomH = CGFloat.kTabbarHeight_Total
            }
        } else {
            if numberOfLines(models.imageInfo) > numberOfVisibleLines {
                bottomH = heightForString(truncatedText(fullText:models.imageInfo) + viewConfig.showMore) + CGFloat.kTabbarSaveAreaHeight + PageControlHeight + PageControlBottomSpace + 10
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
                bottomH = textH + CGFloat.kTabbarSaveAreaHeight + PageControlHeight + PageControlBottomSpace + 10
            }
        }
        
        bottomControl.snp.updateConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(bottomH)
        }
    }
    
    func heightForString(_ string: String) -> CGFloat {
        var labelW:CGFloat = 0

        switch viewConfig.actionType {
        case .Empty:
            labelW = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2
        default:
            labelW = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2 - 10 - 34
        }

        return UIView.sizeFor(string: string, font: viewConfig.viewerFont,lineSpacing: 2, width: labelW).height
    }

    func labelContentWidth() -> CGFloat {
        var labelW:CGFloat = 0

        switch viewConfig.actionType {
        case .Empty:
            labelW = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2
        default:
            labelW = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2 - 10 - 34
        }
        return labelW
    }
    
     func numberOfLines(_ string: String) -> Int {
         return string.numberOfLines(font: viewConfig.viewerFont, labelShowWidth: labelContentWidth(), lineSpacing: 2)
    }
    
    func truncatedText(fullText:String) -> String {
        return fullText.truncatedText(maxLineNumber: numberOfVisibleLines, font: viewConfig.viewerFont, labelShowWidth: labelContentWidth())
    }
}
