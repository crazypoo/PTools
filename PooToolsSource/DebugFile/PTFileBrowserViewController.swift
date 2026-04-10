//
//  PTFileBrowserViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 23/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import MobileCoreServices
import QuickLook
import AttributedString
import SwifterSwift
import DeviceKit

public class PTFileBrowserViewController: PTBaseViewController {

    var showAction: Bool = false
    
    var dataList = [PTFileModel]()
    var extensionDirectoryPath = "" //选择的相对路径
    var operateFilePath: URL?  //操作的文件路径，例如复制、粘贴等
    var currentDirectoryPath: URL { //当前的文件夹
        PTFileBrowser.shared.rootDirectoryPath.appendingPathComponent(extensionDirectoryPath, isDirectory: true)
    }

    lazy var newCollectionView: PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 64
        config.sectionEdges = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0)
        config.showEmptyAlert = true
                
        var emptyConfig = PTEmptyDataViewConfig()
        emptyConfig.buttonTitle = ""
        emptyConfig.mainTitleAtt = """
                \(wrap: .embedding("""
                \("No file",.foreground(.random),.font(.appfont(size: 20)),.paragraph(.alignment(.center)))
                """))
                """
        emptyConfig.secondaryEmptyAtt = nil
        config.emptyViewConfig = emptyConfig
        
        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTFusionCell.ID: PTFusionCell.self])
        
        // 优化1：闭包中加入 [weak self] 防止内存泄漏
        view.cellInCollection = { [weak self] collection, itemSection, indexPath in
            guard let self = self else { return nil }
            
            if let itemRow = itemSection.rows?[indexPath.row],
               let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTFusionCell,
               let cellModel = itemRow.dataModel as? PTFusionCellModel {
                
                cell.cellModel = cellModel
                let cellRealModel = self.dataList[indexPath.row]
                
                var actionSheetDatas = [String]()
                if cellRealModel.fileType == .folder {
                    self.operateFilePath = self.currentDirectoryPath.appendingPathComponent(cellRealModel.name, isDirectory: true)
                    actionSheetDatas = ["PT Screen share".localized(), "PT File copy".localized(), "PT File move".localized(), "PT Button delete".localized()]
                } else {
                    self.operateFilePath = self.currentDirectoryPath.appendingPathComponent(cellRealModel.name, isDirectory: false)
                    actionSheetDatas = ["PT Screen share".localized(), "PT File copy".localized(), "PT File move".localized(), "PT Button delete".localized(), "PT File hash".localized()]
                }
                
                let longTap = UILongPressGestureRecognizer { [weak self] sender in
                    guard let self = self else { return }
                    self.showAction = !self.showAction
                    if self.showAction {
                        UIAlertController.baseActionSheet(title: "PT Media option".localized(), titles: actionSheetDatas, cancelBlock: { sheet in
                            self.showAction = false
                        }, otherBlock: { sheet, index, title in
                            self.showAction = false
                            
                            // 提前提取 operateFilePath，避免在每个 case 中重复 guard let
                            guard let filePath = self.operateFilePath else { return }
                            let currentPath = self.currentDirectoryPath.appendingPathComponent(filePath.lastPathComponent, isDirectory: false)
                            
                            switch index {
                            case 0: // Share
                                let activityVC = PTActivityViewController(activityItems: [filePath])
                                if Gobal_device_info.isPad {
                                    activityVC.modalPresentationStyle = UIModalPresentationStyle.popover
                                    activityVC.popoverPresentationController?.sourceView = self.view
                                    activityVC.popoverPresentationController?.sourceRect = CGRect(x: 10, y: CGFloat.kSCREEN_HEIGHT - 300, width: CGFloat.kSCREEN_WIDTH - 20, height: 300)
                                }
                                self.present(activityVC, animated: true, completion: nil)
                                
                            case 1: // Copy
                                let result = FileManager.pt.copyFile(type: .file, fromeFilePath: filePath.description, toFilePath: currentPath.description)
                                if result.isSuccess { self.loadData() }
                                else { PTNSLogConsole(result.error, levelType: .error, loggerType: .file) }
                                
                            case 2: // Move
                                let result = FileManager.pt.moveFile(type: .file, fromeFilePath: filePath.description, toFilePath: currentPath.description)
                                if result.isSuccess { self.loadData() }
                                else { PTNSLogConsole(result.error, levelType: .error, loggerType: .file) }
                                
                            case 3: // Delete
                                let result = FileManager.pt.removefile(filePath: filePath.description)
                                if result.isSuccess { self.loadData() }
                                else { PTNSLogConsole(result.error, levelType: .error, loggerType: .file) }
                                
                            default: // Hash
                                // 优化3：后台计算 Hash，防止大文件卡死主 UI
                                DispatchQueue.global(qos: .userInitiated).async {
                                    var hashValue = ""
                                    do {
                                        let data = try Data(contentsOf: filePath)
                                        hashValue = "MD5: \n\(data.pt.hashString(hashType: .md5))\n\n" +
                                                    "SHA1: \n\(data.pt.hashString(hashType: .sha1))\n\n" +
                                                    "SHA256: \n\(data.pt.hashString(hashType: .sha256))\n\n" +
                                                    "SHA384: \n\(data.pt.hashString(hashType: .sha384))\n\n" +
                                                    "SHA512: \n\(data.pt.hashString(hashType: .sha512))"
                                    } catch {
                                        PTNSLogConsole(error, levelType: .error, loggerType: .file)
                                        hashValue = error.localizedDescription
                                    }
                                    
                                    DispatchQueue.main.async {
                                        UIAlertController.base_alertVC(title: "PT File hash".localized(), msg: hashValue, okBtns: ["PT File copy".localized()], cancelBtn: "PT Button cancel".localized()) {
                                        } moreBtn: { index, title in
                                            hashValue.copyToPasteboard()
                                        }
                                    }
                                }
                            }
                        }) { sheet in
                            self.showAction = false
                        }
                    }
                }
                longTap.minimumPressDuration = 1
                cell.addGestureRecognizer(longTap)
                return cell
            }
            return nil
        }
        
        // [weak self] 防止内存泄漏
        view.collectionDidSelect = { [weak self] collection, model, indexPath in
            guard let self = self else { return }
            let cellModel = self.dataList[indexPath.row]
            switch cellModel.fileType {
            case .folder:
                self.extensionDirectoryPath = self.extensionDirectoryPath + "/" + cellModel.name
                self.loadData()
            default:
                self.operateFilePath = self.currentDirectoryPath.appendingPathComponent(cellModel.name, isDirectory: false)
                let previewVC = QLPreviewController()
                previewVC.delegate = self
                previewVC.dataSource = self
                self.navigationController?.pushViewController(previewVC, animated: true)
            }
        }
        return view
    }()
    
    lazy var closeBtn: UIButton = {
        let view = baseButtonCreate(image: "❌".emojiToImage(emojiFont: .appfont(size: 20)))
        view.addActionHandlers { [weak self] sender in
            self?.returnFrontVC()
        }
        return view
    }()

    lazy var back: UIButton = {
        let view = baseButtonCreate(image: "◀️".emojiToImage(emojiFont: .appfont(size: 20)))
        view.addActionHandlers { [weak self] sender in
            guard let self = self else { return }
            var array = self.extensionDirectoryPath.components(separatedBy: "/")
            array.removeLast()
            self.extensionDirectoryPath = array.joined(separator: "/")
            self.loadData()
        }
        return view
    }()

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCustomRightButtons(buttons: [closeBtn])
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        let collectionInset: CGFloat = CGFloat.kTabbarSaveAreaHeight
        let collectionInset_Top: CGFloat = CGFloat.kNavBarHeight_Total
        
        newCollectionView.contentCollectionView.contentInsetAdjustmentBehavior = .never
        newCollectionView.contentCollectionView.contentInset.top = collectionInset_Top
        newCollectionView.contentCollectionView.contentInset.bottom = collectionInset
        newCollectionView.contentCollectionView.verticalScrollIndicatorInsets.bottom = collectionInset

        view.addSubviews([newCollectionView])
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }
        loadData()
    }
    
    func loadData() {
        if extensionDirectoryPath.isEmpty {
            navigationItem.leftBarButtonItem = nil
        } else {
            setCustomBackButtonView(back)
        }
        
        // 优化2：将文件系统读取放入后台队列，避免文件过多时卡主 UI 导致掉帧
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var tempFileList = [PTFileModel]()
            let fileDirectoryPth = self.currentDirectoryPath
            
            if FileManager.pt.judgeFileOrFolderExists(filePath: fileDirectoryPth.path),
               let subPath = FileManager.pt.shallowSearchAllFiles(folderPath: fileDirectoryPth.path) {
                
                for fileName in subPath {
                    let filePath = fileDirectoryPth.path.appending("/\(fileName)")
                    let fileModel = PTFileModel()
                    fileModel.name = fileName
                    fileModel.fileURL = URL(fileURLWithPath: filePath) // 记录 URL 供后续使用
                    
                    var isDirectory: ObjCBool = false
                    if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory) {
                        fileModel.fileType = PTFileBrowser.shared.getFileType(filePath: fileModel.fileURL)
                        
                        if let fileAttributes = FileManager.pt.fileAttributes(path: filePath) {
                            fileModel.modificationDate = fileAttributes[FileAttributeKey.modificationDate] as? Date ?? Date()
                            if isDirectory.boolValue {
                                fileModel.size = Int64(FileManager.pt.fileOrDirectorySingleSize(filePath: filePath))
                            } else {
                                fileModel.size = fileAttributes[FileAttributeKey.size] as? Int64 ?? 0
                            }
                        }
                        tempFileList.append(fileModel)
                    }
                }
            }
            
            // 数据准备完毕后，切换回主线程更新 UI
            DispatchQueue.main.async {
                self.dataList = tempFileList
                var mSections = [PTSection]()
                
                let rows = self.dataList.map { value in
                    let fusionModel = PTFusionCellModel()
                    fusionModel.leftImage = self.getImage(type: value.fileType)
                    fusionModel.name = value.name
                    
                    // 优化4：直接使用我们在第一步优化中添加的属性，代码大幅简化！
                    fusionModel.desc = "\(value.formattedSize) | \(value.formattedDate)"
                    
                    switch value.fileType {
                    case .folder:
                        fusionModel.accessoryType = .DisclosureIndicator
                        fusionModel.disclosureIndicatorImage = "➡️".emojiToImage(emojiFont: .appfont(size: 14))
                    default:
                        fusionModel.accessoryType = .NoneAccessoryView
                    }

                    return PTRows(title: value.name, ID: PTFusionCell.ID, dataModel: fusionModel)
                }
                
                if !rows.isEmpty {
                    mSections.append(PTSection(rows: rows))
                }
                // 去掉了原先硬编码的 PTGCDManager.gcdAfter(time: 0.5) 人为延迟，提升用户体验
                self.newCollectionView.showCollectionDetail(collectionData: mSections)
            }
        }
    }

    func getImage(type: PTFileType) -> UIImage {
        // ... 原有 switch 逻辑保持不变 ...
        switch type {
        case .unknown: return "📄".emojiToImage(emojiFont: .appfont(size: 24))
        case .folder: return "📁".emojiToImage(emojiFont: .appfont(size: 24))
        case .image: return "🖼️".emojiToImage(emojiFont: .appfont(size: 24))
        case .video: return "🎞️".emojiToImage(emojiFont: .appfont(size: 24))
        case .audio: return "🎶".emojiToImage(emojiFont: .appfont(size: 24))
        case .web: return "🌐".emojiToImage(emojiFont: .appfont(size: 24))
        case .application: return "📱".emojiToImage(emojiFont: .appfont(size: 24))
        case .zip: return "📦".emojiToImage(emojiFont: .appfont(size: 24))
        case .log: return "📝".emojiToImage(emojiFont: .appfont(size: 24))
        case .excel: return "📊".emojiToImage(emojiFont: .appfont(size: 24))
        case .word: return "🧾".emojiToImage(emojiFont: .appfont(size: 24))
        case .ppt: return "📰".emojiToImage(emojiFont: .appfont(size: 24))
        case .pdf: return "📋".emojiToImage(emojiFont: .appfont(size: 24))
        case .system: return "🖥️".emojiToImage(emojiFont: .appfont(size: 24))
        case .txt: return "📜".emojiToImage(emojiFont: .appfont(size: 24))
        case .db: return "💾".emojiToImage(emojiFont: .appfont(size: 24))
        }
    }
}

// MARK: - QuickLook Delegate
extension PTFileBrowserViewController: QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return operateFilePath != nil ? 1 : 0 // 安全判断
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        // 优化6：安全解包，防止发生意料之外的 Crash
        guard let url = operateFilePath else {
            return URL(fileURLWithPath: "") as QLPreviewItem
        }
        return url as QLPreviewItem
    }
}

// MARK: - Router
#if POOTOOLS_ROUTER
extension PTFileBrowserViewController: PTRouterable {
    public static var priority: UInt {
        PTRouterDefaultPriority
    }

    public static var patternString: [String] {
        ["scheme://route/filedocument"]
    }
    
    public static func registerAction(info: [String : Any]) -> Any {
        // 优化5：修复之前错误返回的 PTUserDefultsViewController Bug
        let vc = PTFileBrowserViewController()
        return vc
    }
}
#endif
