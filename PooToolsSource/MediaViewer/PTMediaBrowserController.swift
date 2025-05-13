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
let PTBroswerBaseTag = 900

public protocol PTPageControllable : AnyObject {
    var currentPage: Int { get }
    func setCurrentPage(index: Int)
    func update(currentPage: Int, totalPages: Int)
}

extension UIPageControl: PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.currentPage = index
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.currentPage = currentPage
        self.numberOfPages = totalPages
    }
}
extension PTFilledPageControl: PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.progress = CGFloat(index)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.progress = CGFloat(currentPage)
        self.pageCount = totalPages
    }
}
extension PTPillPageControl: PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.progress = CGFloat(index)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.progress = CGFloat(currentPage)
        self.pageCount = totalPages
    }
}
extension PTSnakePageControl: PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.progress = CGFloat(index)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.progress = CGFloat(currentPage)
        self.pageCount = totalPages
    }
}
extension PTScrollingPageControl: PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.progress = CGFloat(index)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.progress = CGFloat(currentPage)
        self.pageCount = totalPages
    }
}

@objcMembers
public class PTMediaBrowserController: PTBaseViewController {

    ///界面消失后回调
    public var viewDismissBlock:PTActionTask?
    
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
    ///界面配置
    fileprivate var viewConfig:PTMediaBrowserConfig!
    fileprivate var actionSheetTitle:[String] = []

    fileprivate var currentPage:Int = 1
    
    fileprivate lazy var navControl:PTMediaBrowserNav = {
        let view = PTMediaBrowserNav()
        view.titleLabel.font = self.viewConfig.viewerFont
        view.titleLabel.textColor = self.viewConfig.titleColor
        view.closeButton.setImage(self.viewConfig.closeViewerImage, for: .normal)
        view.closeButton.addActionHandlers { [weak self] _ in
            self?.returnFrontVC {
                self?.viewDismissBlock?()
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
        
        if viewConfig.pageControlShow {
            switch viewConfig.pageControlOption {
            case .system:
                if let pageControl = view.pageControlView as? UIPageControl {
                    pageControl.addPageControlHandlers { sender in
                        let cellModel = self.viewConfig.mediaData[sender.currentPage]
                        self.updateBottom(models: cellModel)
                        self.mediaScrollerView.contentOffset = CGPointMake(CGFloat(sender.currentPage) * CGFloat.kSCREEN_WIDTH, 0)
                    }
                }
            default:
                break
            }
        }
        view.pageControlView.isHidden = !viewConfig.pageControlShow
        return view
    }()
    
    fileprivate lazy var mediaScrollerView:UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.isPagingEnabled = true
        view.delegate = self
        return view
    }()
        
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBarBackgroundColorAlpha = 0
        self.zx_hideBaseNavBar = true
#else
        navigationController?.isNavigationBarHidden = true
#endif
        self.changeStatusBar(type: .Dark)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.changeStatusBar(type: .Auto)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        SwizzleTool().swizzleContextMenuReverseOrder()

        if viewConfig.dynamicBackground {
            view.backgroundColor = viewConfig.viewerContentBackgroundColor
        } else {
            view.backgroundColor = .DevMaskColor
        }
        
        let closeButton = UIButton(type: .close)
        closeButton.addActionHandlers(handler: { sender in
            self.returnFrontVC {
                self.viewDismissBlock?()
            }
        })
        
        view.addSubviews([mediaScrollerView,navControl,bottomControl])

        mediaScrollerView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        navControl.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(CGFloat.kNavBarHeight_Total)
        }
        
        bottomControl.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(CGFloat.kTabbarSaveAreaHeight + PageControlBottomSpace + PageControlHeight + 10 + 34 + 10)
        }
        
        //MARK: 我都唔知点嗨解,懒加载用唔到,系都要在外部调用,小喇叭
        bottomControl.moreActionButton.showsMenuAsPrimaryAction = true
        bottomControl.moreActionButton.menu = makeMenu()

        loadCellDatas()
    }
    
    func showCollectionViewData(loadedTask:((UIScrollView)->Void)? = nil) {
        PTGCDManager.gcdGobal {
            self.mediaScrollerView.removeSubviews()
            if self.viewConfig.mediaData.count > 1 {
                self.bottomControl.pageControlView.isHidden = !self.viewConfig.pageControlShow
                if self.viewConfig.pageControlShow {
                    self.setPageControlValue(0)
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
            
            PTGCDManager.gcdMain {
                if self.viewConfig.mediaData.count >= 10 {
                    self.navControl.titleLabel.isHidden = false
                    self.navControl.titleLabel.text = "1/\(self.viewConfig.mediaData.count)"
                } else {
                    self.navControl.titleLabel.isHidden = true
                }
                self.mediaScrollerView.contentSize = CGSizeMake(CGFloat.kSCREEN_WIDTH * CGFloat(self.viewConfig.mediaData.count), CGFloat.kSCREEN_HEIGHT)
                if !self.firstLoad {
                    self.firstLoad = true
                    var loadSome = 0
                    if self.viewConfig.defultIndex > self.viewConfig.mediaData.count {
                        loadSome = self.viewConfig.mediaData.count - 1
                    } else {
                        loadSome = self.viewConfig.defultIndex
                    }
                    self.mediaScrollerView.contentOffset = CGPointMake(CGFloat(loadSome) * CGFloat.kSCREEN_WIDTH, 0)
                    self.navControl.titleLabel.text = "\(loadSome + 1)/\(self.viewConfig.mediaData.count)"
                    self.pageControlProgressSet(indexPath: IndexPath(row: loadSome, section: 0))
                    self.loadVisibleCells(currentIndex: loadSome)
                } else {
                    self.loadVisibleCells(currentIndex: 0)
                    loadedTask?(self.mediaScrollerView)
                }
            }
        }
    }
    
    func viewMoreActionDismiss() {
        if let itemRow = mediaScrollerView.viewWithTag(PTBroswerBaseTag + currentPage) as? PTMediaBrowserCell {
            switch itemRow.currentCellType {
            case .GIF:
                itemRow.imageView.stopAnimating()
            default:
                break
            }
            returnFrontVC()
        }
    }
    
    func toolBarControl(boolValue:Bool) {
        navControl.isHidden = boolValue
        bottomControl.moreActionButton.isHidden = navControl.isHidden
        bottomControl.titleLabel.isHidden = navControl.isHidden
        bottomControl.backgroundColor = navControl.isHidden ? .clear : MediaBrowserToolBarColor
    }
    
    public func medisShow(mediaConfig:PTMediaBrowserConfig) {
        self.viewConfig = mediaConfig
        self.modalPresentationStyle = .fullScreen
        PTUtils.getCurrentVC().pt_present(self)
    }
    
    public func reloadConfig(mediaConfig:PTMediaBrowserConfig) {
        viewConfig = mediaConfig
        loadCellDatas()
    }
    
    fileprivate func loadCellDatas() {
        var loadSome = 0
        if self.viewConfig.defultIndex > self.viewConfig.mediaData.count {
            loadSome = self.viewConfig.mediaData.count - 1
        } else {
            loadSome = self.viewConfig.defultIndex
        }

        let cellModel = self.viewConfig.mediaData[loadSome]
        self.updateBottom(models: cellModel)
        showCollectionViewData()
    }
}

//MARK: PageControl
fileprivate extension PTMediaBrowserController {
    func pageControlProgressSet(indexPath:IndexPath) {
        guard viewConfig.pageControlShow,
              let controllable = bottomControl.pageControlView as? PTPageControllable else { return }
        controllable.setCurrentPage(index: indexPath.row)
    }
    
    func getPageControlCurrentValue() -> Int {
        return (bottomControl.pageControlView as? PTPageControllable)?.currentPage ?? 0
    }
    
    func setPageControlValue(_ value: Int) {
        guard let control = bottomControl.pageControlView as? PTPageControllable else { return }
        control.update(currentPage: value, totalPages: viewConfig.mediaData.count)
    }
}

//MARK: Menu&ActionSheet
fileprivate extension PTMediaBrowserController {
    func makeMenu() -> UIMenu {
        
        bottomControl.moreActionButton.isSelected = false
        
        var debugActions: [UIMenuElement] = []
        actionSheetTitle.enumerated().forEach { index,value in
            let menuActions = UIAction(title: value) { _ in
                if let cell = self.mediaScrollerView.viewWithTag(PTBroswerBaseTag + self.currentPage) as? PTMediaBrowserCell {
                    self.handleAction(at: index, gifImage: cell.gifImage)
                }
            }
            debugActions.append(menuActions)
        }
        
        var menuContent: [UIMenuElement] = []
                
        menuContent.append(contentsOf: debugActions)
        
        return UIMenu(title: "", children: menuContent)
    }

    func actionSheet() {
        UIAlertController.baseActionSheet(title: viewConfig.actionTitle, cancelButtonName: viewConfig.actionCancel,titles: self.actionSheetTitle, otherBlock: { sheet,index,title in
            if let cell = self.mediaScrollerView.viewWithTag(PTBroswerBaseTag + self.currentPage) as? PTMediaBrowserCell {
                self.handleAction(at: index, gifImage: cell.gifImage)
            }
        })
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

//MARK: Media editor
fileprivate extension PTMediaBrowserController {
    func saveImage() {
        
        let currentPageControlValue = self.getPageControlCurrentValue()

        let model = viewConfig.mediaData[currentPageControlValue]
        
        if let cell = self.mediaScrollerView.viewWithTag(PTBroswerBaseTag + self.currentPage) as? PTMediaBrowserCell {
            switch cell.currentCellType {
            case .Video:
                if let imageUrl = model.imageURL as? String {
                    saveVideoAction(url: imageUrl)
                }
            default:
                if let gifImage = cell.gifImage {
                    saveImageToPhotos(saveImage: gifImage)
                }
            }
        }
    }
    
    func saveVideoAction(url:String) {
        if let cell = self.mediaScrollerView.viewWithTag(PTBroswerBaseTag + self.currentPage) as? PTMediaBrowserCell {
            let loadingView = PTMediaBrowserLoadingView.init(type: .LoopDiagram)
            cell.contentView.addSubview(loadingView)
            loadingView.snp.makeConstraints { make in
                make.width.equalTo(cell.frame.size.width * 0.5)
                make.height.equalTo(cell.frame.size.height * 0.5)
                make.centerX.centerY.equalToSuperview()
            }
            
            let documentDirectory = FileManager.pt.DocumnetsDirectory()
            let fullPath = documentDirectory + "/\(String.currentDate(dateFormatterString: "yyyy-MM-dd_HH:mm:ss")).mp4"
            let download = Network()
            download.createDownload(fileUrl: url, saveFilePath: fullPath, progress: { bytesRead, totalBytesRead, progress in
                PTGCDManager.gcdMain {
                    loadingView.progress = progress
                }
            }) { reponse in
                loadingView.removeFromSuperview()
                self.saveVideo(videoPath: fullPath)
            } fail: { error in }
        }
    }
    
    func saveVideo(videoPath:String) {
        let url = NSURL.fileURL(withPath: videoPath)
        let compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path)
        if compatible {
            UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, #selector(self.save(image:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            viewSaveImageBlock?(compatible)
        }
    }
    
    func saveImageToPhotos(saveImage:UIImage) {
        UIImageWriteToSavedPhotosAlbum(saveImage, self, #selector(self.save(image:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func save(image:UIImage, didFinishSavingWithError:NSError?,contextInfo:AnyObject) {
            
        var saveImageBool:Bool? = false
        if didFinishSavingWithError != nil {
            saveImageBool = false
        } else {
            saveImageBool = true
        }
        
        viewSaveImageBlock?(saveImageBool!)
    }
    
    func deleteImage() {
        if viewConfig.mediaData.count == 1 {
            viewDeleteImageBlock?(0)
            viewMoreActionDismiss()
        } else {
            let currentPageControlValue = self.getPageControlCurrentValue()

            let index = currentPageControlValue
            if let cell = self.mediaScrollerView.viewWithTag(PTBroswerBaseTag + self.currentPage) as? PTMediaBrowserCell {
                switch cell.currentCellType {
                case .GIF:
                    cell.imageView.stopAnimating()
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
                    self.viewConfig.mediaData.remove(at: index)
                    self.mediaScrollerView.contentSize = CGSize(width: CGFloat(self.viewConfig.mediaData.count) * CGFloat.kSCREEN_WIDTH, height: CGFloat.kSCREEN_HEIGHT)
                    self.mediaScrollerView.contentOffset = CGPointMake(CGFloat(newIndex) * CGFloat.kSCREEN_WIDTH, 0)

                    var textIndex = newIndex + 1
                    PTGCDManager.gcdAfter(time: 0.35) {
                        self.showCollectionViewData { reloadCollectionView in
                            if textIndex == 0 {
                                textIndex = 1
                            }
                            self.navControl.titleLabel.text = "\(textIndex)/\(self.viewConfig.mediaData.count)"

                            if self.viewConfig.mediaData.count > 1 {
                                self.bottomControl.pageControlView.isHidden = false
                                self.setPageControlValue(newIndex)
                            } else {
                                self.bottomControl.pageControlView.isHidden = true
                            }
                            
                            let models = self.viewConfig.mediaData[newIndex]
                            self.updateBottom(models: models)
                        }
                    }

                    self.viewDeleteImageBlock?(currentPageControlValue)
                }
            }
        }
    }
}

//MARK: Bottom view
extension PTMediaBrowserController {
    func labelMoreAtt(models:PTMediaBrowserModel) -> ASAttributedString {
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
                bottomH = CGFloat.kTabbarSaveAreaHeight + PageControlBottomSpace + PageControlHeight + 10 + 34 + 10
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
        let labelW:CGFloat = labelContentWidth()
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
         string.numberOfLines(font: viewConfig.viewerFont, labelShowWidth: labelContentWidth(), lineSpacing: 2)
    }
    
    func truncatedText(fullText:String) -> String {
        fullText.truncatedText(maxLineNumber: numberOfVisibleLines, font: viewConfig.viewerFont, labelShowWidth: labelContentWidth())
    }
}

//MARK: Cells
extension PTMediaBrowserController {
    // 只保留最多3个cell：当前页、前一页、后一页
    func loadVisibleCells(currentIndex: Int) {
        guard viewConfig.mediaData.indices.contains(currentIndex) else { return }

        // 安全计算前一页、当前页、后一页索引
        var indexesToLoad: [Int] = []
        if currentIndex > 0 {
            indexesToLoad.append(currentIndex - 1)
        }
        indexesToLoad.append(currentIndex)
        if currentIndex + 1 < viewConfig.mediaData.count {
            indexesToLoad.append(currentIndex + 1)
        }

        // 移除不在可见范围的 cell（tag = PTBroswerBaseTag + index）
        for cell in mediaScrollerView.subviews {
            if let cell = cell as? PTMediaBrowserCell {
                let cellIndex = cell.tag - PTBroswerBaseTag
                if !indexesToLoad.contains(cellIndex) {
                    cell.removeFromSuperview()
                }
            }
        }

        // 添加需要显示的 cell
        for index in indexesToLoad {
            if mediaScrollerView.viewWithTag(PTBroswerBaseTag + index) == nil {
                let value = viewConfig.mediaData[index]
                let cell = PTMediaBrowserCell()
                cell.viewConfig = self.viewConfig
                cell.tag = PTBroswerBaseTag + index
                cell.dataModel = value
                mediaScrollerView.addSubview(cell)
                cell.snp.makeConstraints { make in
                    make.left.equalTo(CGFloat(index) * CGFloat.kSCREEN_WIDTH)
                    make.height.equalTo(CGFloat.kSCREEN_HEIGHT)
                    make.width.equalTo(CGFloat.kSCREEN_WIDTH)
                    make.centerY.equalToSuperview()
                }

                // 回调注册（建议封装成函数来绑定）
                cell.viewerDismissBlock = { [weak self] in
                    self?.returnFrontVC {
                        self?.viewDismissBlock?()
                    }
                }
                cell.zoomTask = { [weak self] boolValue in
                    self?.toolBarControl(boolValue: boolValue)
                }
                cell.tapTask = { [weak self] in
                    guard let self = self else { return }
                    self.toolBarControl(boolValue: !self.navControl.isHidden)
                }
                cell.longTapWakeUp = { [weak self] in
                    self?.actionSheet()
                    PTGCDManager.gcdAfter(time: 0.5) {
                        cell.imageLongTaped = false
                    }
                }
                cell.videoPlayHandler = { [weak self] videoController in
                    self?.present(videoController, animated: true) {
                        videoController.player?.play()
                    }
                }
            }
        }
    }
}

//MARK: UIScrollViewDelegate
extension PTMediaBrowserController : UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentPageControlValue = Int(scrollView.contentOffset.x / scrollView.frame.width + 0.5)
        currentPage = currentPageControlValue
        loadVisibleCells(currentIndex: currentPageControlValue)

        if let currentCell = scrollView.viewWithTag(PTBroswerBaseTag + currentPageControlValue) as? PTMediaBrowserCell {
            if abs(scrollView.contentOffset.y) > 0 {
                currentCell.contentScrolView.isUserInteractionEnabled = false
                currentCell.contentScrolView.isScrollEnabled = false
                currentCell.prepareForHide()
                var delt = 1 - abs(scrollView.contentOffset.y ) / currentCell.contentView.frame.size.height
                delt = max(delt, 0)
                let s = max(delt, 0.5)
                let translation = CGAffineTransform(translationX: scrollView.contentOffset.x / s, y: -(scrollView.contentOffset.y / s))
                let scale = CGAffineTransform(scaleX: s, y: s)
                currentCell.tempView.transform = translation.concatenating(scale)
            }
            
            if abs(scrollView.contentOffset.y) > self.viewConfig.dismissY {
                currentCell.hideAnimation()
            } else if scrollView.contentOffset.y == 0 {
                currentCell.bounceToOriginal()
                currentCell.contentScrolView.isUserInteractionEnabled = true
                currentCell.contentScrolView.isScrollEnabled = true
            }
        }
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let currentPageControlValue = Int(scrollView.contentOffset.x / scrollView.frame.width + 0.5)
        if let itemRow = scrollView.viewWithTag(PTBroswerBaseTag + currentPageControlValue ) as? PTMediaBrowserCell {
            switch itemRow.currentCellType {
            case .GIF:
                itemRow.imageView.stopAnimating()
            default:
                break
            }
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentPageControlValue = Int(scrollView.contentOffset.x / scrollView.frame.width + 0.5)
        currentPage = currentPageControlValue
        let cellModel = self.viewConfig.mediaData[currentPageControlValue]

        if let itemRow = scrollView.viewWithTag(PTBroswerBaseTag + currentPageControlValue ) as? PTMediaBrowserCell {
            switch itemRow.currentCellType {
            case .GIF:
                itemRow.imageView.stopAnimating()
            default:
                break
            }
            
            if self.viewConfig.pageControlShow {
                self.pageControlProgressSet(indexPath: IndexPath(row: currentPageControlValue, section: 0))
            }
            
            if !self.navControl.titleLabel.isHidden {
                self.navControl.titleLabel.text = "\(currentPageControlValue + 1)/\(self.viewConfig.mediaData.count)"
            }
            self.updateBottom(models: cellModel)
            self.browserCurrentDataBlock?(currentPageControlValue)
        }
    }
}
