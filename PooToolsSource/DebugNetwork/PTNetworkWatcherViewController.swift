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

// MARK: - 抓包监控主列表控制器
class PTNetworkWatcherViewController: PTBaseViewController {

    private let viewModel = PTNetworkViewModel()
    let titleViewContainerWidth = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 3 - 88
    
    lazy var searchBar: PTSearchBar = {
        let view = PTSearchBar()
        view.delegate = self
        view.searchBarOutViewColor = .clear
        view.searchTextFieldBackgroundColor = .lightGray
        view.searchBarTextFieldCornerRadius = 0
        view.searchBarTextFieldBorderWidth = 0
        view.searchPlaceholderColor = .gray
        view.searchPlaceholder = "Search"
        view.viewCorner(radius: 17)
        view.frame = CGRect(origin: .zero, size: CGSizeMake(self.titleViewContainerWidth - CGSize.SwitchSize.width - 100, 34))
        return view
    }()
    
    private lazy var titleViewContailer: PTNavTitleContainer = {
        let view = PTNavTitleContainer()
        view.addSubviews([searchBar])
        searchBar.snp.makeConstraints { make in make.edges.equalToSuperview() }
        view.snp.makeConstraints { make in
            make.width.equalTo(self.titleViewContainerWidth)
            make.height.equalTo(32)
        }
        return view
    }()

    lazy var valueSwitch: PTSwitch = {
        let view = PTSwitch()
        view.isOn = PTNetworkHelper.shared.isNetworkEnable
        view.valueChangeCallBack = { sender in
            Task { @MainActor in
                if sender {
                    PTNetworkHelper.shared.enable()
                } else {
                    PTNetworkHelper.shared.disable()
                }
            }
        }
        view.bounds = CGRect(origin: .zero, size: CGSize.SwitchSize)
        return view
    }()
    
    lazy var newCollectionView: PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 64
        config.refreshWithoutAnimation = true
        
        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTNetworkWatcherCell.ID: PTNetworkWatcherCell.self])
        view.cellInCollection = { collection, itemSection, indexPath in
            if let itemRow = itemSection.rows?[indexPath.row], let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTNetworkWatcherCell, let cellModel = itemRow.dataModel as? PTHttpModel {
                cell.cellModel = cellModel
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { [weak self] collection, model, indexPath in
            if let itemRow = model.rows?[indexPath.row], let cellModel = itemRow.dataModel as? PTHttpModel {
                let vc = PTNetworkWatcherDetailViewController(viewModel: cellModel)
                self?.navigationController?.pushViewController(vc)
            }
        }
        return view
    }()

    var floatingView: PFloatingButton?
    lazy var speedLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .black
        label.textColor = .white
        label.numberOfLines = 0
        label.font = .appfont(size: 10)
        label.textAlignment = .center
        return label
    }()
    
    lazy var backButton: UIButton = {
        let button = baseButtonCreate(image: UIImage(.arrow.uturnLeftCircle))
        button.addActionHandlers { [weak self] _ in self?.dismissAnimated() }
        return button
    }()
    
    lazy var deleteButton: UIButton = {
        let deleteButton = baseButtonCreate(image: UIImage(.trash))
        deleteButton.addActionHandlers { [weak self] _ in
            self?.viewModel.handleClearAction()
            self?.loadListModel()
        }
        return deleteButton
    }()
    
    func testAction() {
        // 1. 开启一个绑定到主线程的异步 Task，为使用 await 提供环境
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            let networkSpeedMonitor = PTNetworkSpeedTestMonitor()
            
            // 2. 异步调用 actor 的方法启动测速
            await networkSpeedMonitor.startMonitoring()
            self.floatingButtonCreate()
            
            // 3. 现代 Swift 6 轮询方案：使用 for 循环 + Task.sleep 代替 Timer
            for _ in 1...10 {
                // 暂停 1 秒 (1_000_000_000 纳秒 = 1 秒)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                // 防御性编程：如果用户在这 10 秒内退出了当前页面，直接中断循环避免内存泄漏
                guard !Task.isCancelled else { break }
                
                // 4. 安全地跨越并发边界，从 actor 获取最新速度
                let currentDownloadSpeed = await networkSpeedMonitor.downloadSpeed
                let currentUploadSpeed = await networkSpeedMonitor.uploadSpeed
                
                // 终极修复：正确换算至 MB/s 级别
                let downloadSpeedMB = currentDownloadSpeed / 1048576.0
                let uploadSpeedMB = currentUploadSpeed / 1048576.0

                self.speedLabel.text = String(format: "↑ %.2f MB/s\n↓ %.2f MB/s", uploadSpeedMB, downloadSpeedMB)
            }
            
            // 5. 10 秒循环自然结束，执行清理逻辑
            if let floatingView = self.floatingView {
                floatingView.removeFromSuperview()
                self.floatingView = nil
            }
            
            // 异步停止测速器
            await networkSpeedMonitor.stopMonitoring()
        }
    }
    
    lazy var testButton: UIButton = {
        let testButton = baseButtonCreate(image: UIImage(.sparkles))
        testButton.addActionHandlers { [weak self] _ in
            self?.testAction()
        }
        return testButton
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCustomBackButtonView(backButton)
        setCustomRightButtons(buttons: [deleteButton, valueSwitch, testButton])
        setCustomTitleView(titleViewContailer)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let collectionInset: CGFloat = CGFloat.kTabbarSaveAreaHeight
        let collectionInset_Top: CGFloat = CGFloat.kNavBarHeight_Total
        
        newCollectionView.contentCollectionView.contentInsetAdjustmentBehavior = .never
        newCollectionView.contentCollectionView.contentInset.top = collectionInset_Top
        newCollectionView.contentCollectionView.contentInset.bottom = collectionInset
        newCollectionView.contentCollectionView.verticalScrollIndicatorInsets.bottom = collectionInset

        view.addSubviews([newCollectionView])
        newCollectionView.snp.makeConstraints { make in make.edges.equalToSuperview() }
        
        loadListModel()
        setup()
    }
    
    func loadListModel() {
        var sections = [PTSection]()
        let rows = viewModel.models.map { PTRows(ID: PTNetworkWatcherCell.ID, dataModel: $0) }
        sections.append(PTSection(rows: rows))
        newCollectionView.showCollectionDetail(collectionData: sections)
    }
    
    func setup() { observers() }
    
    func observers() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "reloadHttp_PooTools"), object: nil, queue: .main) { [weak self] notification in
            if let success = notification.object as? Bool {
                Task { @MainActor in
                    self?.reloadHttp(needScrollToEnd: self?.viewModel.reachEnd ?? true, success: success)
                }
            }
        }
    }
    
    func reloadHttp(needScrollToEnd: Bool = false, success: Bool = true) {
        guard viewModel.reloadDataFinish else { return }
        viewModel.applyFilter()
        loadListModel()
        if needScrollToEnd { scrollToBottom() }
    }

    private func scrollToBottom() {
        if viewModel.models.count > 0 {
            newCollectionView.contentCollectionView.scrollToBottom()
        }
    }
    
    private func floatingButtonCreate() {
        if floatingView == nil {
            floatingView = PFloatingButton(inView: AppWindows, frame: CGRect(x: PTAppBaseConfig.share.defaultViewSpace, y: CGFloat.statusBarHeight() + 30, width: 100, height: 40))
            floatingView?.tag = PTNetworkTestFloatingTap
            floatingView?.autoDocking = false
            floatingView?.addSubview(speedLabel)
            speedLabel.snp.makeConstraints { make in make.edges.equalToSuperview() }
        }
    }
}

extension PTNetworkWatcherViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.networkSearchWord = searchText
        viewModel.applyFilter()
        loadListModel()
    }
}

// MARK: - 本地极限吞吐量性能压测引擎 (Network.framework 极客架构)
public actor PTNetworkSpeedTestMonitor {

    private var connection: NWConnection?
    private var listener: NWListener?
    private var startTime: TimeInterval?
    private var bytesReceived: Int = 0
    private var bytesSent: Int = 0

    // 2. 对外暴漏实时读数，外部读取时需要使用 await (例如: await monitor.downloadSpeed)
    public private(set) var downloadSpeed: Double = 0.0
    public private(set) var uploadSpeed: Double = 0.0

    public init() {}

    public func startMonitoring() {
        do {
            listener = try NWListener(using: .tcp, on: .any)
            
            // 3. Network 框架的回调不在 actor 隔离区，需使用 Task { await } 桥接回 actor 内部
            listener?.newConnectionHandler = { [weak self] newConnection in
                Task { [weak self] in
                    await self?.handleNewConnection(newConnection)
                }
            }
            
            listener?.stateUpdateHandler = { [weak self] state in
                Task { [weak self] in
                    await self?.handleListenerState(state)
                }
            }
            
            listener?.start(queue: .global())
        } catch {
            // 假设你项目中有这个宏，保持不变
            PTNSLogConsole("Failed to create listener: \(error)")
        }
    }

    public func stopMonitoring() {
        connection?.cancel()
        listener?.cancel()
        connection = nil
        listener = nil
    }

    // 提取出来的方法，在 actor 内部安全执行
    private func handleNewConnection(_ newConnection: NWConnection) {
        setupReceive(on: newConnection)
        newConnection.start(queue: .global())
    }

    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .ready:
            if let port = listener?.port {
                startConnection(to: port)
            }
        default: break
        }
    }

    private func startConnection(to port: NWEndpoint.Port) {
        connection = NWConnection(host: "127.0.0.1", port: port, using: .tcp)
        connection?.start(queue: .global())
        startSendingData()
    }

    private func startSendingData() {
        guard let connection = connection, connection.state == .ready else {
            // 4. Swift 6 异步延迟重试的现代写法，取代 DispatchQueue.asyncAfter
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                startSendingData()
            }
            return
        }
        
        // 5. ⚠️ 性能优化点：将 payload 提升到 1MB，避免极速递归下的 Task 调度开销压垮 CPU
        let data = Data(repeating: 0, count: 1024 * 1024)
        if startTime == nil { startTime = Date().timeIntervalSince1970 }

        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if error == nil {
                Task { [weak self] in
                    await self?.recordSend(bytes: data.count)
                    // 递归发送下一段
                    await self?.startSendingData()
                }
            }
        })
    }

    private func recordSend(bytes: Int) {
        bytesSent += bytes
        calculateUploadSpeed()
    }

    private func setupReceive(on connection: NWConnection) {
        // 接收端的最大长度也同步提升至 1MB
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024 * 1024) { [weak self] data, _, _, error in
            guard let data = data, error == nil else { return }
            
            Task { [weak self] in
                await self?.recordReceive(bytes: data.count)
                // 继续监听接收
                await self?.setupReceive(on: connection)
            }
        }
    }

    private func recordReceive(bytes: Int) {
        bytesReceived += bytes
        calculateDownloadSpeed()
    }

    private func calculateDownloadSpeed() {
        guard let startTime = startTime else { return }
        let elapsedTime = Date().timeIntervalSince1970 - startTime
        guard elapsedTime > 0 else { return }
        downloadSpeed = Double(bytesReceived) / elapsedTime
    }

    private func calculateUploadSpeed() {
        guard let startTime = startTime else { return }
        let elapsedTime = Date().timeIntervalSince1970 - startTime
        guard elapsedTime > 0 else { return }
        uploadSpeed = Double(bytesSent) / elapsedTime
    }
}
