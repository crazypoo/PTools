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
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif

public class PTFileBrowserViewController: PTBaseViewController {

    var showAction:Bool = false
    
    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return dateFormatter
    }()

    var dataList = [PTFileModel]()
    var extensionDirectoryPath = "" //选择的相对路径
    var operateFilePath: URL?  //操作的文件路径，例如复制、粘贴等
    var currentDirectoryPath: URL { //当前的文件夹
        PTFileBrowser.shared.rootDirectoryPath.appendingPathComponent(extensionDirectoryPath, isDirectory: true)
    }

    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 64
        config.sectionEdges = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0)
        
        let view = PTCollectionView(viewConfig: config)
        view.cellInCollection = { collection,itemSection,indexPath in
            let itemRow = itemSection.rows[indexPath.row]
            let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
            cell.cellModel = (itemRow.dataModel as! PTFusionCellModel)
            
            let cellRealModel = self.dataList[indexPath.row]
            
            var actionSheetDatas = [String]()
            if cellRealModel.fileType == .folder {
                self.operateFilePath = self.currentDirectoryPath.appendingPathComponent(cellRealModel.name, isDirectory: true)
                actionSheetDatas = ["PT Screen share".localized(),"PT File copy".localized(),"PT File move".localized(),"PT Button delete".localized()]
            } else {
                self.operateFilePath = self.currentDirectoryPath.appendingPathComponent(cellRealModel.name, isDirectory: false)
                actionSheetDatas = ["PT Screen share".localized(),"PT File copy".localized(),"PT File move".localized(),"PT Button delete".localized(),"PT File hash".localized()]
            }
            
            let longTap = UILongPressGestureRecognizer { sender in
                self.showAction = !self.showAction
                if self.showAction {
                    UIAlertController.baseActionSheet(title: "PT Media option".localized(), titles: actionSheetDatas, cancelBlock: { sheet in
                        self.showAction = false
                    },otherBlock: { sheet,index in
                        self.showAction = false
                        switch index {
                        case 0:
                            guard let filePath = self.operateFilePath else { return }
                            let activityVC = UIActivityViewController(activityItems: [filePath], applicationActivities: nil)
                            if UIDevice.current.model == "iPad" {
                                activityVC.modalPresentationStyle = UIModalPresentationStyle.popover
                                activityVC.popoverPresentationController?.sourceView = self.view
                                activityVC.popoverPresentationController?.sourceRect = CGRect(x: 10, y: CGFloat.kSCREEN_HEIGHT - 300, width: CGFloat.kSCREEN_WIDTH - 20, height: 300)
                            }
                            self.present(activityVC, animated: true, completion: nil)
                        case 1:
                            let closeBtn = UIButton(type: .custom)
                            closeBtn.setImage("❌".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
                            closeBtn.setTitleColor(.systemBlue, for: .normal)
                            closeBtn.bounds = CGRectMake(0, 0, closeBtn.sizeFor(height: 34).width, 34)
                            closeBtn.addActionHandlers { sender in
                                self.returnFrontVC()
                            }
                            let rightBarItem = UIBarButtonItem(customView: closeBtn)
                            self.navigationItem.rightBarButtonItem = rightBarItem

                            guard let filePath = self.operateFilePath else { return }
                            let manager = FileManager.default
                            //同名
                            let currentPath = self.currentDirectoryPath.appendingPathComponent(filePath.lastPathComponent, isDirectory: false)
                            do {
                                try manager.copyItem(at: filePath, to: currentPath)
                            } catch {
                                PTNSLogConsole(error)
                            }
                            self.loadData()
                        case 2:
                            let closeBtn = UIButton(type: .custom)
                            closeBtn.setImage("❌".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
                            closeBtn.setTitleColor(.systemBlue, for: .normal)
                            closeBtn.bounds = CGRectMake(0, 0, closeBtn.sizeFor(height: 34).width, 34)
                            closeBtn.addActionHandlers { sender in
                                self.returnFrontVC()
                            }
                            let rightBarItem = UIBarButtonItem(customView: closeBtn)
                            self.navigationItem.rightBarButtonItem = rightBarItem

                            guard let filePath = self.operateFilePath else { return }
                            let manager = FileManager.default
                            let currentPath = self.currentDirectoryPath.appendingPathComponent(filePath.lastPathComponent, isDirectory: false)
                            do {
                                try manager.moveItem(at: filePath, to: currentPath)
                            } catch {
                                PTNSLogConsole(error)
                            }
                            self.loadData()
                        case 3:
                            guard let filePath = self.operateFilePath else { return }
                            let manager = FileManager.default
                            do {
                                try manager.removeItem(at: filePath)
                            } catch {
                                PTNSLogConsole(error)
                            }
                            self.loadData()
                        default:
                            guard let filePath = self.operateFilePath else { return }
                            var hashValue = ""
                            do {
                                let data = try Data(contentsOf: filePath)

                                hashValue = "MD5: \n" + data.pt.hashString(hashType: .md5) + "\n\n" + "SHA1: \n" + data.pt.hashString(hashType: .sha1) + "\n\n" + "SHA256: \n" + data.pt.hashString(hashType: .sha256) + "\n\n" + "SHA384: \n" + data.pt.hashString(hashType: .sha384) + "\n\n" + "SHA512: \n" + data.pt.hashString(hashType: .sha512)
                            } catch  {
                                PTNSLogConsole(error)
                                hashValue = error.localizedDescription
                            }
                            
                            UIAlertController.base_alertVC(title: "PT File hash".localized(),msg: hashValue,okBtns: ["PT File copy".localized()],cancelBtn: "PT Button cancel".localized()) {
                                
                            } moreBtn: { index, title in
                                hashValue.copyToPasteboard()
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
        view.collectionDidSelect = { collection,model,indexPath in
            let cellModel = self.dataList[indexPath.row]
            switch cellModel.fileType {
            case .folder:
                self.extensionDirectoryPath = self.extensionDirectoryPath + "/" + cellModel.name
                self.loadData()
            default:
                
                let backBtn = UIButton(type: .custom)
                backBtn.setTitle("PT Nav back".localized(), for: .normal)
                backBtn.setTitleColor(.systemBlue, for: .normal)
                backBtn.bounds = CGRectMake(0, 0, backBtn.sizeFor(height: 34).width, 34)
                backBtn.addActionHandlers { sender in
                    self.returnFrontVC()
                }
                let rightBarItem = UIBarButtonItem(customView: backBtn)
                self.navigationItem.leftBarButtonItem = rightBarItem
                self.operateFilePath = self.currentDirectoryPath.appendingPathComponent(cellModel.name, isDirectory: false)
                //preview
                let previewVC = QLPreviewController()
                previewVC.delegate = self
                previewVC.dataSource = self
                self.navigationController?.pushViewController(previewVC, animated: true)
            }
        }
        return view
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()

        let closeBtn = UIButton(type: .custom)
        closeBtn.setImage("❌".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
        closeBtn.addActionHandlers { sender in
            self.returnFrontVC()
        }
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBar?.addSubview(closeBtn)
        closeBtn.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.bottom.equalToSuperview().inset(5)
        }
#else
        closeBtn.bounds = CGRectMake(0, 0, 34, 34)
        let rightBarItem = UIBarButtonItem(customView: closeBtn)
        navigationItem.rightBarButtonItem = rightBarItem
#endif
        
        view.addSubviews([newCollectionView])
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
#if POOTOOLS_NAVBARCONTROLLER
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
#else
            make.top.equalToSuperview()
#endif
        }
        loadData()
    }
    
    func loadData() {
        if extensionDirectoryPath.isEmpty {
            navigationItem.leftBarButtonItem = nil
        } else {
            let backBtn = UIButton(type: .custom)
            backBtn.setTitle("PT Nav back".localized(), for: .normal)
            backBtn.setTitleColor(.systemBlue, for: .normal)
            backBtn.bounds = CGRectMake(0, 0, backBtn.sizeFor(height: 34).width, 34)
            backBtn.addActionHandlers { sender in
                var array = self.extensionDirectoryPath.components(separatedBy: "/")
                array.removeLast()
                self.extensionDirectoryPath = array.joined(separator: "/")
                self.loadData()
            }
            let leftBarItem = UIBarButtonItem(customView: backBtn)
            navigationItem.leftBarButtonItem = leftBarItem
        }
        dataList.removeAll()
        let manager = FileManager.default
        let fileDirectoryPth = currentDirectoryPath
        if manager.fileExists(atPath: fileDirectoryPth.path), let subPath = try? manager.contentsOfDirectory(atPath: fileDirectoryPth.path) {
            for fileName in subPath {
                let filePath = fileDirectoryPth.path.appending("/\(fileName)")
                //对象
                let fileModel = PTFileModel()
                fileModel.name = fileName
                //属性
                var isDirectory: ObjCBool = false
                if manager.fileExists(atPath: filePath, isDirectory: &isDirectory) {
                    fileModel.fileType = PTFileBrowser.shared.getFileType(filePath: URL(fileURLWithPath: filePath))
                    if let fileAttributes = try? manager.attributesOfItem(atPath: filePath) {
                        fileModel.modificationDate = fileAttributes[FileAttributeKey.modificationDate] as? Date ?? Date()
                        if isDirectory.boolValue {
                            fileModel.size = Double(FileManager.pt.fileOrDirectorySingleSize(filePath: filePath))
                        } else {
                            fileModel.size = fileAttributes[FileAttributeKey.size] as? Double ?? 0
                        }
                    }
                    dataList.append(fileModel)
                }
            }
        }
        
        PTGCDManager.gcdAfter(time: 0.5) {
            var mSections = [PTSection]()
            
            var rows = [PTRows]()
            self.dataList.enumerated().forEach { index,value in
                let fusionModel = PTFusionCellModel()
                fusionModel.leftImage = self.getImage(type: value.fileType)
                fusionModel.name = value.name
                
                var size = "\(Int(value.size))B"
                if value.size > 1024 * 1024 {
                    size = "\(Int(value.size/1024/1024))MB"
                } else if value.size > 1024 {
                    size = "\(Int(value.size/1024))KB"
                }
                
                fusionModel.desc = size + " | " + self.dateFormatter.string(from: value.modificationDate)
                switch value.fileType {
                case .folder:
                    fusionModel.accessoryType = .DisclosureIndicator
                    fusionModel.disclosureIndicatorImage = "➡️".emojiToImage(emojiFont: .appfont(size: 14))
                default:
                    fusionModel.accessoryType = .NoneAccessoryView
                }

                let row = PTRows.init(title: value.name,cls: PTFusionCell.self,ID: PTFusionCell.ID,dataModel: fusionModel)
                rows.append(row)
            }
            let section = PTSection.init(rows: rows)
            mSections.append(section)
            
            self.newCollectionView.layoutIfNeeded()
            self.newCollectionView.showCollectionDetail(collectionData: mSections)
        }
    }

    func getImage(type:PTFileType) -> UIImage {
        switch type {
        case .unknown:
            return "📄".emojiToImage(emojiFont: .appfont(size: 24))
        case .folder:
            return "📑".emojiToImage(emojiFont: .appfont(size: 24))
        case .image:
            return "🖼️".emojiToImage(emojiFont: .appfont(size: 24))
        case .video:
            return "🎞️".emojiToImage(emojiFont: .appfont(size: 24))
        case .audio:
            return "🎶".emojiToImage(emojiFont: .appfont(size: 24))
        case .web:
            return "🌐".emojiToImage(emojiFont: .appfont(size: 24))
        case .application:
            return "📱".emojiToImage(emojiFont: .appfont(size: 24))
        case .zip:
            return "📦".emojiToImage(emojiFont: .appfont(size: 24))
        case .log:
            return "📝".emojiToImage(emojiFont: .appfont(size: 24))
        case .excel:
            return "📊".emojiToImage(emojiFont: .appfont(size: 24))
        case .word:
            return "🧾".emojiToImage(emojiFont: .appfont(size: 24))
        case .ppt:
            return "📰".emojiToImage(emojiFont: .appfont(size: 24))
        case .pdf:
            return "📋".emojiToImage(emojiFont: .appfont(size: 24))
        case .system:
            return "🖥️".emojiToImage(emojiFont: .appfont(size: 24))
        case .txt:
            return "📜".emojiToImage(emojiFont: .appfont(size: 24))
        case .db:
            return "💾".emojiToImage(emojiFont: .appfont(size: 24))
        }
    }
}

extension PTFileBrowserViewController: QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        operateFilePath! as QLPreviewItem
    }
}

#if POOTOOLS_ROUTER
extension PTFileBrowserViewController:PTRouterable {
    public static var patternString: [String] {
        ["scheme://route/filedocument"]
    }
    
    public static func registerAction(info: [String : Any]) -> Any {
        let vc = PTUserDefultsViewController()
        return vc
    }
}
#endif
