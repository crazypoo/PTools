//
//  PTNetworkWatcherViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import SafeSFSymbols
import Network
import ObjectiveC

let PTNetworkTestFloatingTap = 9997

class PTNetworkWatcherViewController: PTBaseViewController {

    private let viewModel = PTNetworkViewModel()

    lazy var fakeNav:PTNavBar = {
        let view = PTNavBar()
        return view
    }()
    
    lazy var searchBar:PTSearchBar = {
        let view = PTSearchBar()
        view.delegate = self
        view.searchBarOutViewColor = .clear
        view.searchTextFieldBackgroundColor = .lightGray
        view.searchBarTextFieldCornerRadius = 0
        view.searchBarTextFieldBorderWidth = 0
        view.searchPlaceholderColor = .gray
        view.searchPlaceholder = "Search"
        view.viewCorner(radius: 17)
        view.frame = CGRect(origin: .zero, size: CGSizeMake(320, 34))
        return view
    }()
    
    lazy var valueSwitch:PTSwitch = {
        let view = PTSwitch()
        view.isOn = PTNetworkHelper.shared.isNetworkEnable
        view.valueChangeCallBack = { sender in
            if sender {
                PTNetworkHelper.shared.enable()
            } else {
                PTNetworkHelper.shared.disable()
            }
        }
        view.bounds = CGRect(origin: .zero, size: CGSize.SwitchSize)
        return view
    }()
    
    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 64
        config.refreshWithoutAnimation = true
        
        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTNetworkWatcherCell.ID:PTNetworkWatcherCell.self])
        view.cellInCollection = { collection,itemSection,indexPath in
            if let itemRow = itemSection.rows?[indexPath.row],let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTNetworkWatcherCell,let cellModel = itemRow.dataModel as? PTHttpModel {
                cell.cellModel = cellModel
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { collection,model,indexPath in
            if let itemRow = model.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTHttpModel {
                let vc = PTNetworkWatcherDetailViewController(viewModel: cellModel)
                self.navigationController?.pushViewController(vc)
            }
        }
        return view
    }()

    var floatingView : PFloatingButton?
    lazy var speedLabel : UILabel = {
        let label = UILabel()
        label.backgroundColor = .black
        label.textColor = .white
        label.numberOfLines = 0
        label.font = .appfont(size: 10)
        label.textAlignment = .center
        return label
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let collectionInset:CGFloat = CGFloat.kTabbarSaveAreaHeight
        let collectionInset_Top:CGFloat = CGFloat.kNavBarHeight
        
        newCollectionView.contentCollectionView.contentInsetAdjustmentBehavior = .never
        newCollectionView.contentCollectionView.contentInset.top = collectionInset_Top
        newCollectionView.contentCollectionView.contentInset.bottom = collectionInset
        newCollectionView.contentCollectionView.verticalScrollIndicatorInsets.bottom = collectionInset

        view.addSubviews([newCollectionView,fakeNav])
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(self.sheetViewController?.options.pullBarHeight ?? 0)
        }

        fakeNav.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.newCollectionView)
            make.height.equalTo(CGFloat.kNavBarHeight)
        }
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(.arrow.uturnLeftCircle), for: .normal)
        if #available(iOS 26.0, *) {
            button.configuration = UIButton.Configuration.clearGlass()
        }

        let deleteButton = UIButton(type: .custom)
        deleteButton.setImage(UIImage(.trash), for: .normal)
        if #available(iOS 26.0, *) {
            deleteButton.configuration = UIButton.Configuration.clearGlass()
        }

        let testButton = UIButton(type: .custom)
        testButton.setImage(UIImage(.sparkles), for: .normal)
        if #available(iOS 26.0, *) {
            testButton.configuration = UIButton.Configuration.clearGlass()
        }
        fakeNav.setLeftButtons([button])
        fakeNav.titleView = searchBar
        fakeNav.titleViewMode = .auto
        fakeNav.setRightButtons([deleteButton,valueSwitch,testButton])
        button.addActionHandlers { sender in
            self.dismissAnimated()
        }

        deleteButton.addActionHandlers { sender in
            self.viewModel.handleClearAction()
            self.loadListModel()
        }
                        
        testButton.addActionHandlers { sender in
            let networkSpeedMonitor = PTNetworkSpeedTestMonitor()
            networkSpeedMonitor.startMonitoring()
            self.floatingButtonCreate()
            var count = 0
            Timer.scheduledTimer(timeInterval: 1, repeats: true) { timers in
                count += 1
                let downloadSpeed = networkSpeedMonitor.downloadSpeed / 1024 / 1024 / 1024 / 1024
                let uploadSpeed = networkSpeedMonitor.uploadSpeed / 1024 / 1024 / 1024 / 1024

                self.speedLabel.text = String(format: "↑ %.2f MB/s\n↓ %.2f MB/s",uploadSpeed, downloadSpeed)
                if count > 10 {
                    timers.invalidate()
                    if let floatingView = self.floatingView {
                        floatingView.removeFromSuperView()
                        self.floatingView = nil
                    }
                    networkSpeedMonitor.stopMonitoring()
                }
            }
        }
                
        loadListModel()
        setup()
    }
    
    func loadListModel() {
        var sections = [PTSection]()
        
        let rows = viewModel.models.map { PTRows(ID: PTNetworkWatcherCell.ID, dataModel: $0) }
        let section = PTSection(rows: rows)
        sections.append(section)
        newCollectionView.showCollectionDetail(collectionData: sections)
    }
    
    func setup() {
        observers()
    }
    
    func observers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "reloadHttp_PooTools"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let success = notification.object as? Bool {
                self?.reloadHttp(
                    needScrollToEnd: self?.viewModel.reachEnd ?? true,
                    success: success
                )
            }
        }
    }
    
    func reloadHttp(needScrollToEnd: Bool = false, success: Bool = true) {
        guard viewModel.reloadDataFinish else { return }

        viewModel.applyFilter()
        loadListModel()

        if needScrollToEnd {
            scrollToBottom()
        }
    }

    private func scrollToBottom() {
        if viewModel.models.count > 0 {
            newCollectionView.contentCollectionView.scrollToBottom()
        }
    }
    
    private func floatingButtonCreate() {
        if floatingView == nil {
            floatingView = PFloatingButton(view: AppWindows as Any, frame: CGRect(x: PTAppBaseConfig.share.defaultViewSpace, y: CGFloat.statusBarHeight() + 30, width: 100, height: 40))
            floatingView?.tag = PTNetworkTestFloatingTap
            floatingView?.autoDocking = false
            floatingView?.addSubview(speedLabel)
            speedLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}

extension PTNetworkWatcherViewController:UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.networkSearchWord = searchText
        viewModel.applyFilter()
        loadListModel()
    }
}

//MARK: 速度測試
class PTNetworkSpeedTestMonitor {

    private var connection: NWConnection?
    private var listener: NWListener?
    private var startTime: TimeInterval?
    private var bytesReceived: Int = 0
    private var bytesSent: Int = 0

    var downloadSpeed: Double = 0.0
    var uploadSpeed: Double = 0.0

    func startMonitoring() {
        startListener()
        startConnection()
    }

    func stopMonitoring() {
        connection?.cancel()
        listener?.cancel()
    }

    private func startListener() {
        do {
            listener = try NWListener(using: .tcp, on: 8080)
            listener?.newConnectionHandler = { [weak self] newConnection in
                self?.setupReceive(on: newConnection)
                newConnection.start(queue: .global())
            }
            listener?.start(queue: .global())
        } catch {
            PTNSLogConsole("Failed to create listener: \(error)")
        }
    }

    private func startConnection() {
        connection = NWConnection(host: "127.0.0.1", port: 8080, using: .tcp)
        connection?.start(queue: .global())
        startSendingData()
    }

    private func startSendingData() {
        guard let connection = connection else { return }
        let data = Data(repeating: 0, count: 1024)
        startTime = Date().timeIntervalSince1970

        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if error == nil {
                self?.bytesSent += data.count
                self?.calculateUploadSpeed()
                self?.startSendingData()
            }
        })
    }

    private func setupReceive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, _, error in
            guard let self = self, let data = data, error == nil else { return }
            self.bytesReceived += data.count
            self.calculateDownloadSpeed()
            self.setupReceive(on: connection)
        }
    }

    private func calculateDownloadSpeed() {
        guard let startTime = startTime else { return }
        let elapsedTime = Date().timeIntervalSince1970 - startTime
        downloadSpeed = Double(bytesReceived) / elapsedTime
    }

    private func calculateUploadSpeed() {
        guard let startTime = startTime else { return }
        let elapsedTime = Date().timeIntervalSince1970 - startTime
        uploadSpeed = Double(bytesSent) / elapsedTime
    }
}
