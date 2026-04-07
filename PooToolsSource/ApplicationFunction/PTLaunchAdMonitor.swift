//
//  PTLaunchAdMonitor.swift
//  Diou
//
//  Created by ken lam on 2021/10/9.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import AVKit
import DeviceKit
import SnapKit
import SwifterSwift

public let PLaunchAdDetailDisplayNotification = "PShowLaunchAdDetailNotification"
public let PLaunchAdSkipNotification = "PLaunchAdSkipNotification"

public class PTLaunchADModel: PTBaseModel {
    public var image: Any?
    public var time: TimeInterval = 0
    public var tapURL: [AnyHashable: Any]?
}

public struct CountdownItem<T> {
    let duration: TimeInterval
    let value: T
    let start: TimeInterval
    let end: TimeInterval
}

/*
 启动页面广告管理器 (优化版)
 针对冷启动场景优化了内存释放与渲染性能
 */
@objcMembers
public class PTLaunchAdMonitor: NSObject {
    public static let share = PTLaunchAdMonitor()
    
    public var imageContentMode: UIView.ContentMode = .scaleAspectFill
    public var adShowed: Bool = false
    public var skipName: String = "Skip"
    
    private var dismissCallBack: PTActionTask?
    private var timeUpCallBack: PTActionTask?
    
    // 💡 优化1：使用轻量级的 AVPlayerLayer 代替 AVPlayerViewController，提升冷启动渲染速度
    private var player: AVPlayer?
    private lazy var playerLayer: AVPlayerLayer = {
        let layer = AVPlayerLayer()
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    
    private lazy var skipButton: UIButton = {
        let view = UIButton()
        view.setTitleColor(.white, for: .normal)
        if #available(iOS 26.0, *) {
            // 假设 clearGlass() 是你们项目里的扩展，若报错可改为常规配置
            view.configuration = UIButton.Configuration.clearGlass()
        } else {
            view.setBackgroundColor(color: .DevMaskColor, forState: .normal)
        }
        return view
    }()
    
    private lazy var loadImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        return view
    }()
    
    // 💡 优化2：复用透明按钮承载点击事件，避免每次切换广告时重复创建手势或按钮
    private lazy var actionButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .clear
        return btn
    }()
    
    private var notifiData: [AnyHashable: Any]?
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    private var adLaunchModels: [PTLaunchADModel] = []
    private var bottomViewHeight: CGFloat = 0
    
    // MARK: 初始化广告界面
    @MainActor public func showAd(adModels: [PTLaunchADModel],
                                  onView: Any,
                                  skipFont: UIFont = .appfont(size: 16),
                                  ltdString: String = "",
                                  comNameFont: UIFont = .appfont(size: 12),
                                  callBack: PTActionTask? = nil,
                                  timeUp: PTActionTask? = nil) {
        
        dismissCallBack = callBack
        timeUpCallBack = timeUp
        adLaunchModels = adModels
        
        setupBaseUI(onView: onView, ltdString: ltdString, comNameFont: comNameFont, skipFont: skipFont)
        startAdSequence(adModels: adModels)
    }
    
    // MARK: - 私有方法：基础 UI 设置
    @MainActor private func setupBaseUI(onView: Any, ltdString: String, comNameFont: UIFont, skipFont: UIFont) {
        if let onViews = onView as? UIView {
            onViews.addSubview(contentView)
            onViews.bringSubviewToFront(contentView)
            contentView.snp.makeConstraints { $0.edges.equalToSuperview() }
        } else if let onWindow = onView as? UIWindow {
            onWindow.addSubview(contentView)
            onWindow.bringSubviewToFront(contentView)
            contentView.snp.makeConstraints { $0.edges.equalToSuperview() }
            
#if POOTOOLS_DEBUG
            let share = LocalConsole.shared
            if share.isVisiable, let terminal = share.terminal {
                onWindow.bringSubviewToFront(terminal)
            }
#endif
        }
        
        skipButton.setTitle(skipName, for: .normal)
        skipButton.titleLabel?.font = skipFont
        // 💡 优化3：使用 [weak self] 防止闭包引起的单例内存泄漏
        skipButton.addActionHandlers { [weak self] sender in
            self?.hideView(sender: sender)
        }
        
        let comLabelExists = !ltdString.stringIsEmpty()
        let device = UIDevice.current
        bottomViewHeight = 0
        
        if comLabelExists {
            switch device.orientation {
            case .landscapeLeft, .landscapeRight:
                bottomViewHeight = 50
            default:
                bottomViewHeight = 100
            }
            
            let label = UILabel()
            label.backgroundColor = .white
            label.numberOfLines = 0
            label.lineBreakMode = .byCharWrapping
            label.font = comNameFont
            label.textColor = .black
            label.text = ltdString
            label.textAlignment = .center
            contentView.addSubview(label)
            label.snp.makeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(bottomViewHeight)
            }
        }
        
        // 💡 优化4：一次性添加所有视图，后续仅通过数据更新和 isHidden 控制显示，大幅降低 CPU 开销
        contentView.addSubviews([loadImageView, actionButton, skipButton])
        contentView.layer.insertSublayer(playerLayer, below: loadImageView.layer)
        
        loadImageView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(bottomViewHeight)
        }
        
        actionButton.snp.makeConstraints { make in
            make.edges.equalTo(loadImageView)
        }
        
        actionButton.addActionHandlers { [weak self] sender in
            self?.showDetail(sender: sender)
        }
        
        skipButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.right.equalToSuperview().inset(10)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
        }
        
        PTGCDManager.gcdMain {
            self.skipButton.viewCorner(radius: 22)
            self.playerLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - self.bottomViewHeight)
        }
    }
    
    // MARK: - 私有方法：启动广告序列
    @MainActor private func startAdSequence(adModels: [PTLaunchADModel]) {
        let totalTime: TimeInterval = adModels.reduce(0) { $0 + $1.time }
        let result = buildCountdownTimeline(items: adModels.map { ($0.time, $0) })
        let timeline = result.timeline
        var currentIndex = -1
        
        skipButton.setTitle("\(totalTime)", for: .normal)
        let buttonWidth = skipButton.sizeFor().width + 15
        skipButton.snp.updateConstraints { make in
            make.size.equalTo(buttonWidth)
        }
        skipButton.viewCorner(radius: buttonWidth / 2, capsule: true)
        
        // 💡 优化5：定时器闭包严格使用 [weak self]，确保广告结束后彻底释放资源
        skipButton.buttonTimeRun(timeInterval: totalTime, originalTitle: "", timeFinish: { [weak self] in
            guard let self = self else { return }
            self.adShowed = false
            self.hideView()
        }, timingCallPack: { [weak self] time in
            guard let self = self else { return }
            self.adShowed = true
            
            guard let newIndex = self.currentCountdownIndex(remainTime: time, totalTime: totalTime, timeline: timeline) else { return }
            
            if newIndex != currentIndex {
                currentIndex = newIndex
                let model = timeline[newIndex].value
                self.handleAdDisplay(model: model)
            }
        })
    }
    
    private func handleAdDisplay(model: PTLaunchADModel) {
        let mediaHaveData: Bool = model.tapURL != nil
        notifiData = model.tapURL
        actionButton.isUserInteractionEnabled = mediaHaveData
        
        loadImageAtPath(path: model.image as Any) { [weak self] type, media, gifTime in
            guard let self = self else { return }
            PTGCDManager.gcdMain {
                self.resetMediaStates()
                
                switch type {
                case .Image:
                    self.loadImageView.isHidden = false
                    if let medias = media as? [UIImage] {
                        if medias.count > 1 {
                            self.loadImageView.animationImages = medias
                            self.loadImageView.animationDuration = gifTime
                            self.loadImageView.startAnimating()
                        } else if let firstImage = medias.first {
                            self.loadImageView.image = firstImage
                            self.loadImageView.contentMode = self.imageContentMode
                        }
                    }
                case .Video:
                    if let videoUrl = media as? URL {
                        self.playerLayer.isHidden = false
                        self.player = AVPlayer(url: videoUrl)
                        self.playerLayer.player = self.player
                        self.player?.play()
                    }
                }
            }
        }
    }
    
    // 💡 优化6：统一管理媒体的停止与释放逻辑，避免后台偷跑
    private func resetMediaStates() {
        loadImageView.stopAnimating()
        loadImageView.animationImages = nil
        loadImageView.image = nil
        loadImageView.isHidden = true
        
        player?.pause()
        playerLayer.player = nil
        playerLayer.isHidden = true
    }
    
    enum PTLaunchAdMediaType {
        case Image, Video
    }
    
    private func loadImageAtPath(path: Any, completion: @escaping (PTLaunchAdMediaType, Any?, TimeInterval) -> Void) {
        Task {
            if let imagePath = path as? String, imagePath.contentTypeForUrl() == PTUrlStringVideoType.MP4 {
                let videoUrl = (imagePath as NSString).range(of: "/var").length > 0 ? URL(fileURLWithPath: imagePath) : URL(string: imagePath)
                completion(.Video, videoUrl, 0)
            } else {
                let result = await PTLoadImageFunction.loadImage(contentData: path)
                completion(.Image, result.allImages, result.loadTime)
            }
        }
    }
    
    @MainActor fileprivate func hideView(sender: UIButton? = nil) {
        let targetView = sender?.superview ?? self.contentView
        targetView.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.25, animations: {
            targetView.alpha = 0
        }) { [weak self] _ in
            guard let self = self else { return }
            self.resetMediaStates()
            targetView.removeFromSuperview()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: PLaunchAdSkipNotification), object: nil)
            
            if sender != nil {
                self.skipButton.cancelCountdown()
                self.dismissCallBack?()
            } else {
                self.timeUpCallBack?()
            }
        }
    }
    
    @MainActor fileprivate func showDetail(sender: UIView) {
        let targetView = contentView
        targetView.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.25, animations: {
            targetView.alpha = 0
        }) { [weak self] _ in
            guard let self = self else { return }
            self.adShowed = false
            targetView.removeFromSuperview()
            self.player?.pause()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: PLaunchAdDetailDisplayNotification), object: self.notifiData)
        }
    }
    
    func buildCountdownTimeline<T>(items: [(TimeInterval, T)]) -> (timeline: [CountdownItem<T>], totalTime: TimeInterval) {
        var current: TimeInterval = 0
        let timeline = items.map { duration, value in
            let item = CountdownItem(duration: duration, value: value, start: current, end: current + duration)
            current += duration
            return item
        }
        return (timeline, current)
    }
    
    func currentCountdownIndex<T>(remainTime: TimeInterval, totalTime: TimeInterval, timeline: [CountdownItem<T>]) -> Int? {
        let elapsed = max(0, totalTime - remainTime)
        return timeline.firstIndex { elapsed >= $0.start && elapsed < $0.end }
    }
}
