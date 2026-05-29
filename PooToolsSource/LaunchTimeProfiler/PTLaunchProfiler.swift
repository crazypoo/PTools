//
//  PTLaunchProfiler.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 28/5/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import Foundation
import SnapKit
import SwifterSwift

/// 冷启动耗时分析器
@MainActor
public class PTLaunchProfiler {
    
    /// 全局单例
    public static let shared = PTLaunchProfiler()
    
    /// 里程碑数据模型
    public struct Milestone {
        public let name: String
        public let timestamp: TimeInterval
        public let threadName: String
        /// 距离进程启动的相对时间
        public var timeOffsetFromStart: TimeInterval = 0
        /// 距离上一个里程碑的间距时间
        public var timeOffsetFromPrevious: TimeInterval = 0
    }
    
    // MARK: - 私有属性
    private let lock = NSRecursiveLock()
    private var milestones: [Milestone] = []
    
    private var processStartTime: TimeInterval = 0
    private var mainStartTime: TimeInterval = 0
    private var didFinishLaunchingTime: TimeInterval = 0
    private var firstScreenRenderTime: TimeInterval = 0
    
    private var isFinished: Bool = false
    
    // MARK: - 初始化
    private init() {
        // 单例初始化时，立即通过系统内核获取进程启动时间
        self.processStartTime = fetchProcessStartTime()
        
        // 默认自动注入第一个里程碑：进程创建
        appendMilestone(name: "📌 [System] Process Created (Pre-Main Start)")
    }
    
    // MARK: - 核心生命周期打点 API
    
    /// 记录 Main 阶段开始 (建议在 AppDelegate 的 init 中最早调用)
    public func markMainStart() {
        lock.lock(); defer { lock.unlock() }
        guard mainStartTime == 0 else { return }
        mainStartTime = Date().timeIntervalSince1970
        appendMilestone(name: "🎬 [Lifecycle] Main() Started (App Delegate Init)")
    }
    
    /// 记录 didFinishLaunchingWithOptions 结束
    public func markDidFinishLaunching() {
        lock.lock(); defer { lock.unlock() }
        guard didFinishLaunchingTime == 0 else { return }
        didFinishLaunchingTime = Date().timeIntervalSince1970
        appendMilestone(name: "📦 [Lifecycle] Did Finish Launching")
    }
    
    /// 记录首屏渲染完成 (调用后将自动锁死记录并打印完整报告)
    public func markFirstScreenRender() {
        lock.lock(); defer { lock.unlock() }
        guard !isFinished else { return }
        
        firstScreenRenderTime = Date().timeIntervalSince1970
        appendMilestone(name: "📱 [Lifecycle] First Screen Rendered (viewDidAppear)")
        
        isFinished = true
        processAndRenderReport()
    }
    
    // MARK: - 自定义里程碑打点 API
    
    /// 动态添加一个自定义打点标签 (支持任意线程调用)
    /// - Parameter name: 标签名称，如 "SDK_💡_WeChatInit_Start"
    public func addMilestone(named name: String) {
        lock.lock(); defer { lock.unlock() }
        guard !isFinished else { return }
        appendMilestone(name: "🏷️ \(name)")
    }
    
    /// 测量特定代码块的耗时，并自动生成开始/结束的里程碑数据
    /// - Parameters:
    ///   - name: 任务名称
    ///   - block: 需要测量耗时的闭包
    public func measure(named name: String, block: () -> Void) {
        addMilestone(named: "\(name) -> [Start]")
        block()
        addMilestone(named: "\(name) -> [End]")
    }
    
    // MARK: - 获取所有采集数据 (供未来可视化面板使用)
    
    /// 获取当前所有已记录的里程碑数据
    public func getAllMilestones() -> [Milestone] {
        lock.lock(); defer { lock.unlock() }
        return milestones
    }
    
    // MARK: - 私有辅助方法
    
    /// 内部安全的追加里程碑记录
    private func appendMilestone(name: String) {
        let currentThread = Thread.current
        let threadDesc = currentThread.isMainThread ? "Main Thread" : (currentThread.name ?? "Sub Thread-\(Unmanaged.passUnretained(currentThread).toOpaque())")
        
        let milestone = Milestone(name: name, timestamp: Date().timeIntervalSince1970, threadName: threadDesc)
        milestones.append(milestone)
    }
    
    /// 获取进程启动绝对时间（C语言系统底层 API）
    private func fetchProcessStartTime() -> TimeInterval {
        var kinfo = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        
        let result = sysctl(&mib, u_int(mib.count), &kinfo, &size, nil, 0)
        if result == 0 {
            let startTime = kinfo.kp_proc.p_un.__p_starttime
            return TimeInterval(startTime.tv_sec) + TimeInterval(startTime.tv_usec) / 1_000_000.0
        }
        return Date().timeIntervalSince1970
    }
    
    /// 数据二次加工与控制台报告打印
    private func processAndRenderReport() {
        guard !milestones.isEmpty else { return }
        
        // 1. 数据计算
        for i in 0..<milestones.count {
            milestones[i].timeOffsetFromStart = milestones[i].timestamp - processStartTime
            if i == 0 {
                milestones[i].timeOffsetFromPrevious = milestones[i].timestamp - processStartTime
            } else {
                milestones[i].timeOffsetFromPrevious = milestones[i].timestamp - milestones[i-1].timestamp
            }
        }
        
        // 2. 阶段总计计算
        let preMainDuration = mainStartTime > 0 ? (mainStartTime - processStartTime) : 0
        let mainDuration = (didFinishLaunchingTime > 0 && mainStartTime > 0) ? (didFinishLaunchingTime - mainStartTime) : 0
        let renderDuration = (firstScreenRenderTime > 0 && didFinishLaunchingTime > 0) ? (firstScreenRenderTime - didFinishLaunchingTime) : 0
        let totalDuration = firstScreenRenderTime - processStartTime
        
        // 3. 打印控制台美化日志
        var reportLines: [String] = []
            
        reportLines.append("\n=========================================================================")
        reportLines.append("🚀 [ptools.LaunchProfiler] APP 冷启动全链路耗时分析报告")
        reportLines.append("=========================================================================")
        reportLines.append(String(format: "📊 启动总耗时: %.4f 秒", totalDuration))
        reportLines.append("-------------------------------------------------------------------------")
        reportLines.append(String(format: "⏳ [阶段 1] Pre-Main (系统及动态库加载) : %.4f 秒", preMainDuration))
        reportLines.append(String(format: "⏳ [阶段 2] Main 业务初始化 (AppD init)  : %.4f 秒", mainDuration))
        reportLines.append(String(format: "⏳ [阶段 3] UI 首屏渲染 (呈现给用户)       : %.4f 秒", renderDuration))
        reportLines.append("-------------------------------------------------------------------------")
        reportLines.append("📋 详细时间线节点流水 (Timeline Milestones):")
        reportLines.append("-------------------------------------------------------------------------")
        
        for (index, entry) in milestones.enumerated() {
            let line = String(format: "[#%02d] 相对起点: +%.4fs  |  距上节点: +%.4fs  |  线程: [%@]  |  事件: %@",
                              index,
                              entry.timeOffsetFromStart,
                              entry.timeOffsetFromPrevious,
                              entry.threadName,
                              entry.name)
            reportLines.append(line)
        }
        reportLines.append("=========================================================================\n")
        
        // 4. 将所有行拼接并一次性打印，避免被其他线程日志打断
        let finalReport = reportLines.joined(separator: "\n")
        PTNSLogConsole(finalReport)
    }
}

/// 可视化管理器：负责悬浮入口及数据看板的展现
@MainActor
public final class LaunchVisualizer {
    
    public static let shared = LaunchVisualizer()
    
    private init() {}
    
    /// 显示可视化入口（通常在首屏渲染完成后调用）
    public func showEntry() {
        EntryWindow.share.show()
        EntryWindow.share.onTap = { [weak self] in
            self?.presentDashboard()
        }
    }
    
    /// 弹出详情数据看板
    private func presentDashboard() {
        guard let topVC = PTUtils.getCurrentVC() else {
            PTNSLogConsole("⚠️ [ptools] 无法找到顶层 ViewController，看板弹出失败")
            return
        }
        let milestones = PTLaunchProfiler.shared.getAllMilestones()
        let dashboard = DashboardViewController(milestones: milestones)
        let nav = PTBaseNavControl(rootViewController: dashboard)
        nav.modalPresentationStyle = .fullScreen
        topVC.present(nav, animated: true)
    }
    
    private func getTopViewController(base: UIViewController? = nil) -> UIViewController? {
        let currentBase: UIViewController?
                    
        if let baseVC = base {
            currentBase = baseVC
        } else {
            // 1. 获取所有 Scene 下的窗口
            let windows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
            
            // 🌟 关键修复：避开悬浮窗！
            // 寻找层级为 normal，并且确确实实挂载了 rootViewController 的主业务窗口
            let mainWindow = windows.first { $0.isKeyWindow && $0.windowLevel == .normal && $0.rootViewController != nil }
                ?? windows.first { $0.windowLevel == .normal && $0.rootViewController != nil }
            
            currentBase = mainWindow?.rootViewController
        }
        
        guard let baseToSearch = currentBase else { return nil }
        
        // 2. 如果是导航控制器 (UINavigationController)，取其可见的顶层
        if let nav = baseToSearch as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)
        }
        
        // 3. 如果是标签控制器 (UITabBarController)，取其当前选中的层
        if let tab = baseToSearch as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)
        }
        
        // 4. 如果当前 VC 已经 present 了其他的弹窗，深入弹窗内部继续查找
        if let presented = baseToSearch.presentedViewController {
            return getTopViewController(base: presented)
        }
        
        // 5. 找到了真正的最顶层
        return baseToSearch
    }
}

// MARK: - 内部组件: 悬浮窗入口

private class EntryWindow: UIWindow {
    static let share = EntryWindow()

    var onTap: (() -> Void)?
    
    lazy var gesLabel:UILabel = {
        let label = UILabel()
        label.text = "🚀"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 30)
        label.isUserInteractionEnabled = true
        label.backgroundColor = .random
        return label
    }()
    
    init() {
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {
            super.init(windowScene: scene)
        } else {
            super.init(frame: UIScreen.main.bounds)
        }
        
        windowLevel = .alert + 208
        backgroundColor = .clear
        
        self.addSubview(gesLabel)
        gesLabel.snp.makeConstraints { make in
            make.size.equalTo(64)
            make.center.equalToSuperview()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        gesLabel.addGestureRecognizers([tap,pan])
    }
        
    required init?(coder: NSCoder) { fatalError() }
    
    @objc private func handleTap() { onTap?() }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        hide()
    }
    
    func show() {
        isHidden = false
    }
    
    func hide() {
        isHidden = true
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == gesLabel {
            return view
        }

        // 其余屏幕区域交给 Window 响应以处理 Pan 手势
        return nil
    }
}

// MARK: - 内部组件: 详情看板

private class DashboardViewController: PTBaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let milestones: [PTLaunchProfiler.Milestone]
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    init(milestones: [PTLaunchProfiler.Milestone]) {
        self.milestones = milestones
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private lazy var copyBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitleColor(.random, for: .normal)
        btn.setTitle("Copy Log", for: .normal)
        btn.addTarget(self, action: #selector(copyLog), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.bounds = CGRect(origin: .zero, size: .init(width: btn.sizeFor().width + 5, height: 34))
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.pt_Title = "Launch Performance Profiler"
        self.view.backgroundColor = .systemBackground
        
        setCustomRightButtons(buttons: [copyBtn])
            
        setupTableView()
    }
    
    private func setupTableView() {
        
        let collectionInset:CGFloat = CGFloat.kTabbarSaveAreaHeight
        let collectionInset_Top:CGFloat = CGFloat.kNavBarHeight_Total
        
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.contentInset.top = collectionInset_Top
        tableView.contentInset.bottom = collectionInset
        tableView.verticalScrollIndicatorInsets.bottom = collectionInset

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MilestoneCell.self, forCellReuseIdentifier: "Cell")
    }
    
    @objc private func dismissSelf() { dismiss(animated: true) }
    
    @objc private func copyLog() {
        // 1. 如果没有数据，直接提示
        guard !milestones.isEmpty else {
            let alert = UIAlertController(title: "提示", message: "暂无日志数据可复制", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // 2. 动态拼接真实的日志内容
        var reportLines: [String] = []
        reportLines.append("🚀 [ptools.LaunchProfiler] APP 冷启动耗时日志导出")
        reportLines.append("=========================================================================")
        
        for (index, entry) in milestones.enumerated() {
            let line = String(format: "[#%02d] 相对起点: +%.4fs  |  距上节点: +%.4fs  |  线程: [%@]  |  事件: %@",
                              index,
                              entry.timeOffsetFromStart,
                              entry.timeOffsetFromPrevious,
                              entry.threadName,
                              entry.name)
            reportLines.append(line)
        }
        reportLines.append("=========================================================================")
        
        // 3. 组合成最终字符串并写入系统剪贴板
        let finalLogString = reportLines.joined(separator: "\n")
        UIPasteboard.general.string = finalLogString
        
        // 4. 弹出成功提示
        let alert = UIAlertController(title: "复制成功", message: "完整数据已复制到剪贴板，快去粘贴分享吧！", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - TableView Logic
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { milestones.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! MilestoneCell
        let item = milestones[indexPath.row]
        cell.configure(index: indexPath.row, milestone: item)
        return cell
    }
}

// MARK: - 内部组件: 自定义 Cell

private class MilestoneCell: UITableViewCell {
    let indexLabel = UILabel()
    let nameLabel = UILabel()
    let timeLabel = UILabel()
    let deltaLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        indexLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .bold)
        indexLabel.textColor = .systemBlue
        
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.numberOfLines = 0
        
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        timeLabel.textColor = .secondaryLabel
        
        deltaLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .bold)
        deltaLabel.textColor = .systemGreen
        
        let stack = UIStackView(arrangedSubviews: [indexLabel, nameLabel, timeLabel, deltaLabel])
        stack.axis = .vertical
        stack.spacing = 4
        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(index: Int, milestone: PTLaunchProfiler.Milestone) {
        indexLabel.text = "POINT #\(index)"
        nameLabel.text = milestone.name
        timeLabel.text = "Offset: +\(String(format: "%.4f", milestone.timeOffsetFromStart))s (\(milestone.threadName))"
        deltaLabel.text = "Interval: +\(String(format: "%.4f", milestone.timeOffsetFromPrevious))s"
    }
}
