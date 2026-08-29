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

public class PTLaunchADModel: NSObject {
    public var image: Any?
    public var time: TimeInterval = 0
    public var tapURL: [AnyHashable: Any]?
}

// Immutable launch-ad metadata for crossing an actor boundary.
// Metadatos inmutables del anuncio de lanzamiento para cruzar un límite de actor.
// 用于跨越 actor 边界的不可变启动广告元数据。
public struct PTLaunchADSnapshot: Sendable {
    public let time: TimeInterval
    public let imageURL: URL?
    public let imageData: Data?
    public let imageIdentifier: String?
    public let tapURL: [String: String]
    public let hasTapURL: Bool

    @MainActor
    public init(model: PTLaunchADModel) {
        time = model.time
        if let value = model.image as? Data {
            imageURL = nil
            imageIdentifier = nil
            imageData = value
        } else if let value = model.image as? URL {
            imageURL = value
            imageIdentifier = nil
            imageData = nil
        } else if let value = model.image as? String {
            if value.hasPrefix("/"), !value.isEmpty {
                imageURL = URL(fileURLWithPath: value)
                imageIdentifier = nil
            } else if let url = URL(string: value), url.scheme != nil {
                imageURL = url
                imageIdentifier = nil
            } else {
                imageURL = nil
                imageIdentifier = value
            }
            imageData = nil
        } else if let value = model.image as? UIImage {
            imageURL = nil
            imageIdentifier = nil
            imageData = value.pngData()
        } else {
            imageURL = nil
            imageIdentifier = nil
            imageData = nil
        }

        hasTapURL = model.tapURL != nil
        tapURL = (model.tapURL ?? [:]).reduce(into: [String: String]()) { result, pair in
            let key = String(describing: pair.key)
            let value = String(describing: pair.value)
            result[key] = value
        }
    }
}

public struct CountdownItem<T: Sendable> : Sendable{
    let duration: TimeInterval
    let value: T
    let start: TimeInterval
    let end: TimeInterval
}

/*
 启动页面广告管理器 (优化版)
 针对冷启动场景优化了内存释放与渲染性能
 */
@MainActor
@objcMembers
public class PTLaunchAdMonitor: NSObject {
    public static let share = PTLaunchAdMonitor()
    
    public var imageContentMode: UIView.ContentMode = .scaleAspectFill
    public var adShowed: Bool = false
    public var skipName: String = "Skip"
    
    private var dismissCallBack: PTActionTask?
    private var timeUpCallBack: PTActionTask?
    
    private let baseSkipButtonSize:CGFloat = 44
    
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

    // Keep one cancellable media task and a generation token for the current ad.
    // Mantiene una sola tarea de medios cancelable y un token de generación para el anuncio actual.
    // 只保留一个可取消的媒体任务，并用 generation 标记当前广告。
    private var mediaLoadTask: Task<Void, Never>?
    private var mediaGeneration = 0
    private var currentAdIndex = -1
    private var hasInstalledActionHandlers = false
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()

    // Reuse the company label so repeated showAd calls do not duplicate views and constraints.
    // Reutiliza la etiqueta de la empresa para que las llamadas repetidas a showAd no dupliquen vistas ni restricciones.
    // 复用公司名称标签，避免重复调用 showAd 时重复创建视图和约束。
    private lazy var companyLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        label.textAlignment = .center
        return label
    }()
    
    private var adLaunchSnapshots: [PTLaunchADSnapshot] = []
    private var bottomViewHeight: CGFloat = 0
    
    // MARK: 初始化广告界面
    @MainActor public func showAd(adModels: [PTLaunchADModel],
                                  onView: Any,
                                  skipFont: UIFont = .appfont(size: 16),
                                  ltdString: String = "",
                                  comNameFont: UIFont = .appfont(size: 12),
                                  callBack: PTActionTask? = nil,
                                  timeUp: PTActionTask? = nil) {
        skipButton.cancelCountdown()
        cancelMediaLoad()
        resetMediaStates()
        contentView.alpha = 1
        contentView.isUserInteractionEnabled = true
        dismissCallBack = callBack
        timeUpCallBack = timeUp
        adLaunchSnapshots = adModels.map { PTLaunchADSnapshot(model: $0) }
        
        guard !adLaunchSnapshots.isEmpty else { return }
        setupBaseUI(onView: onView, ltdString: ltdString, comNameFont: comNameFont, skipFont: skipFont)
        startAdSequence(snapshots: adLaunchSnapshots)
    }
    
    // MARK: - 私有方法：基础 UI 设置
    @MainActor private func setupBaseUI(onView: Any, ltdString: String, comNameFont: UIFont, skipFont: UIFont) {
        let hostView: UIView?
        if let onWindow = onView as? UIWindow {
            hostView = onWindow
            if contentView.superview !== onWindow {
                contentView.removeFromSuperview()
                onWindow.addSubview(contentView)
            }
            onWindow.bringSubviewToFront(contentView)
#if POOTOOLS_DEBUG
            let share = LocalConsole.shared
            if share.isVisiable, let terminal = share.terminal {
                onWindow.bringSubviewToFront(terminal)
            }
#endif
        } else if let onViews = onView as? UIView {
            hostView = onViews
            if contentView.superview !== onViews {
                contentView.removeFromSuperview()
                onViews.addSubview(contentView)
            }
            onViews.bringSubviewToFront(contentView)
        } else {
            hostView = nil
        }

        guard hostView != nil else { return }
        contentView.snp.remakeConstraints { $0.edges.equalToSuperview() }
        
        skipButton.setTitle(skipName, for: .normal)
        skipButton.titleLabel?.font = skipFont
        if !hasInstalledActionHandlers {
            // Avoid stacking UIControl closures when the monitor is shown more than once.
            // Evita acumular cierres de UIControl cuando el monitor se muestra más de una vez.
            // 避免监控器多次显示时不断叠加 UIControl 闭包。
            skipButton.addActionHandlers { [weak self] sender in
                self?.hideView(sender: sender)
            }
            actionButton.addActionHandlers { [weak self] sender in
                self?.showDetail(sender: sender)
            }
            hasInstalledActionHandlers = true
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
            
            if companyLabel.superview !== contentView {
                contentView.addSubview(companyLabel)
            }
            companyLabel.isHidden = false
            companyLabel.font = comNameFont
            companyLabel.textColor = .black
            companyLabel.text = ltdString
            companyLabel.snp.remakeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(bottomViewHeight)
            }
        } else {
            companyLabel.removeFromSuperview()
        }
        
        // Attach reusable views and constraints exactly once per hierarchy.
        // Añade las vistas reutilizables y las restricciones una sola vez por jerarquía.
        // 在每个视图层级中只添加一次可复用视图和约束。
        for view in [loadImageView, actionButton, skipButton] where view.superview !== contentView {
            contentView.addSubview(view)
        }
        if playerLayer.superlayer !== contentView.layer {
            playerLayer.removeFromSuperlayer()
            contentView.layer.insertSublayer(playerLayer, below: loadImageView.layer)
        }
        
        loadImageView.snp.remakeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(bottomViewHeight)
        }
        
        actionButton.snp.remakeConstraints { make in
            make.edges.equalTo(loadImageView)
        }
        
        skipButton.snp.remakeConstraints { make in
            make.height.equalTo(self.baseSkipButtonSize)
            make.width.equalTo(self.baseSkipButtonSize)
            make.right.equalToSuperview().inset(10)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
        }
        
        self.skipButton.layoutIfNeeded()
        self.skipButton.viewCorner(radius: baseSkipButtonSize / 2,capsule: true)
        contentView.layoutIfNeeded()
        self.playerLayer.frame = self.loadImageView.frame
    }
    
    private func resetSkipWidth() {
        var buttonWidth = skipButton.sizeFor().width + 15
        if baseSkipButtonSize > buttonWidth {
            buttonWidth = baseSkipButtonSize
        }
        skipButton.snp.updateConstraints { make in
            make.width.equalTo(buttonWidth)
        }
    }
    
    // MARK: - 私有方法：启动广告序列
    @MainActor private func startAdSequence(snapshots: [PTLaunchADSnapshot]) {
        let result = buildCountdownTimeline(items: snapshots.enumerated().map { index, snapshot in
            let duration = snapshot.time.isFinite ? max(0, snapshot.time) : 0
            return (duration, index)
        })
        let timeline = result.timeline
        let totalTime = result.totalTime
        currentAdIndex = -1
                
        let totalString = String(format: "%.0f", totalTime)
        skipButton.setTitle(totalString, for: .normal)
        resetSkipWidth()
        skipButton.layoutIfNeeded()
        skipButton.viewCorner(radius: baseSkipButtonSize / 2, capsule: true)
        
        // 💡 优化5：定时器闭包严格使用 [weak self]，确保广告结束后彻底释放资源
        skipButton.buttonTimeRun(timeInterval: totalTime, originalTitle: "", timeFinish: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.adShowed = false
                self.hideView()
            }
        }, timingCallPack: { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.adShowed = true
                
                guard let newIndex = self.currentCountdownIndex(remainTime: time, totalTime: totalTime, timeline: timeline) else { return }
                
                self.resetSkipWidth()
                
                if newIndex != self.currentAdIndex {
                    self.currentAdIndex = newIndex
                    let modelIndex = timeline[newIndex].value
                    guard self.adLaunchSnapshots.indices.contains(modelIndex) else { return }
                    self.handleAdDisplay(snapshot: self.adLaunchSnapshots[modelIndex])
                }
            }
        })
    }
    
    // Keep media and tap metadata in immutable, Sendable values before starting asynchronous work.
    // Mantiene los metadatos de medios y toque en valores inmutables y Sendable antes del trabajo asíncrono.
    // 在开始异步工作前，将媒体和点击元数据冻结为不可变的 Sendable 值。
    private func handleAdDisplay(snapshot: PTLaunchADSnapshot) {
        cancelMediaLoad()
        resetMediaStates()
        let generation = mediaGeneration
        notifiData = snapshot.tapURL.reduce(into: [AnyHashable: Any]()) { result, pair in
            result[pair.key] = pair.value
        }
        actionButton.isUserInteractionEnabled = snapshot.hasTapURL
        let mediaSource: PTLaunchAdMediaSource?
        if let imageURL = snapshot.imageURL {
            mediaSource = .url(imageURL)
        } else if let imageData = snapshot.imageData {
            mediaSource = .data(imageData)
        } else if let imageIdentifier = snapshot.imageIdentifier {
            mediaSource = .named(imageIdentifier)
        } else {
            mediaSource = nil
        }
        
        mediaLoadTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let (type, media, gifTime) = await self.loadImage(source: mediaSource)
            guard !Task.isCancelled, self.mediaGeneration == generation else { return }
            self.applyMedia(type: type, media: media, gifTime: gifTime)
            self.mediaLoadTask = nil
        }
    }

    // Apply a completed media snapshot only on MainActor.
    // Aplica una instantánea de medios completada únicamente en MainActor.
    // 只在 MainActor 上应用已经完成的媒体快照。
    private func applyMedia(type: PTLaunchAdMediaType, media: Any?, gifTime: TimeInterval) {
        switch type {
        case .Image:
            guard let medias = media as? [UIImage], !medias.isEmpty else { return }
            loadImageView.isHidden = false
            if medias.count > 1 {
                loadImageView.animationImages = medias
                loadImageView.animationDuration = gifTime
                loadImageView.startAnimating()
            } else if let firstImage = medias.first {
                loadImageView.image = firstImage
                loadImageView.contentMode = imageContentMode
            }
        case .Video:
            guard let videoUrl = media as? URL else { return }
            playerLayer.isHidden = false
            player = AVPlayer(url: videoUrl)
            playerLayer.player = player
            player?.play()
        }
    }
    
    // 💡 优化6：统一管理媒体的停止与释放逻辑，避免后台偷跑
    private func resetMediaStates() {
        loadImageView.stopAnimating()
        loadImageView.animationImages = nil
        loadImageView.image = nil
        loadImageView.isHidden = true
        
        player?.pause()
        player = nil
        playerLayer.player = nil
        playerLayer.isHidden = true
    }
    
    enum PTLaunchAdMediaType {
        case Image, Video
    }

    private enum PTLaunchAdMediaSource: Sendable {
        case url(URL)
        case data(Data)
        case named(String)
    }

    private func loadImage(source: PTLaunchAdMediaSource?) async -> (PTLaunchAdMediaType, Any?, TimeInterval) {
        guard let source else { return (.Image, nil, 0) }

        if case .url(let url) = source, url.pt_isVideoResource {
            return (.Video, url, 0)
        }

        let imageSource: PTImageSource
        switch source {
        case .url(let url):
            imageSource = .url(url)
        case .data(let data):
            imageSource = .data(data)
        case .named(let name):
            imageSource = .named(name)
        }
        let result = await PTLoadImageFunction.loadImage(source: imageSource)
        return (.Image, result.allImages, result.loadTime)
    }

    // Cancel pending decoding and invalidate callbacks from the previous ad.
    // Cancela la decodificación pendiente e invalida los callbacks del anuncio anterior.
    // 取消待处理的解码任务，并使上一个广告的回调失效。
    private func cancelMediaLoad() {
        mediaGeneration &+= 1
        mediaLoadTask?.cancel()
        mediaLoadTask = nil
    }
    
    @MainActor fileprivate func hideView(sender: UIButton? = nil) {
        cancelMediaLoad()
        resetMediaStates()
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
        cancelMediaLoad()
        resetMediaStates()
        let targetView = contentView
        targetView.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.25, animations: {
            targetView.alpha = 0
        }) { [weak self] _ in
            guard let self = self else { return }
            self.adShowed = false
            targetView.removeFromSuperview()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: PLaunchAdDetailDisplayNotification), object: self.notifiData)
        }
    }
    
    @MainActor func buildCountdownTimeline<T>(items: [(TimeInterval, T)]) -> (timeline: [CountdownItem<T>], totalTime: TimeInterval) {
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
