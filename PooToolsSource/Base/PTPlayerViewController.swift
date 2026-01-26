//
//  PTPlayerViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2025/10/14.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import SnapKit
import SwifterSwift

open class PTPlayerViewController: PTBaseViewController {

    private var playerLayer: AVPlayerLayer?
    
    private let playPauseButton = UIButton(type: .custom)
    private let slider = UISlider()
    private let currentTimeLabel = UILabel()
    private let durationLabel = UILabel()
    private lazy var closeButton:UIButton = {
        let view = UIButton(type: .custom)
        if #available(iOS 26, *) {
            view.configuration = UIButton.Configuration.clearGlass()
        }
        view.setImage(PTAppBaseConfig.share.playerBackItemImage, for: .normal)
        view.bounds = .init(origin: .zero, size: .init(width: 34, height: 34))
        view.addActionHandlers(handler: { _ in
            self.closeTapped()
        })
        return view
    }()
    
    private var timeObserverToken: Any?
    
    // MARK: - Public
    public var videoPlayer: AVPlayer?
    public var onCloseTapped: PTActionTask? // 🔹 你可以拦截返回逻辑
    
    lazy var videoNavBar:PTNavBar = {
        let view = PTNavBar()
        view.setLeftButtons([closeButton])
        return view
    }()
    
    open override func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        return .solid(.clear)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        applyNavigationBarStyle()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyNavigationBarStyle()
        changeStatusBar(type: .Dark)
    }
    
    // MARK: - Lifecycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPlayer()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }
    
    deinit {
        if let token = timeObserverToken {
            videoPlayer?.removeTimeObserver(token)
        }
        videoPlayer?.pause()
        videoPlayer = nil
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        // 播放/暂停按钮
        playPauseButton.setImage(PTAppBaseConfig.share.playerPlayItemPlayImage, for: .normal)
        playPauseButton.setImage(PTAppBaseConfig.share.playerPlayItemPauseImage, for: .selected)
        playPauseButton.isSelected = true
        playPauseButton.addActionHandlers { sender in
            self.togglePlay()
        }
        if #available(iOS 26.0, *) {
            playPauseButton.configuration = UIButton.Configuration.clearGlass()
        }
        
        // 进度条
        slider.minimumTrackTintColor = .white
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        
        // 时间标签
        [currentTimeLabel, durationLabel].forEach {
            $0.textColor = .white
            $0.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        }
        
        // 关闭按钮
        
        // 添加子视图
        view.addSubviews([videoNavBar,playPauseButton, slider, currentTimeLabel, durationLabel])
        videoNavBar.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
            make.left.right.equalToSuperview()
            make.height.equalTo(CGFloat.kNavBarHeight)
        }
        
        playPauseButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.size.equalTo(24)
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + 20)
        }
        
        durationLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.centerY.equalTo(self.playPauseButton)
        }
        
        currentTimeLabel.snp.makeConstraints { make in
            make.right.equalTo(self.durationLabel.snp.left).offset(-8)
            make.centerY.equalTo(self.playPauseButton)
        }
        
        slider.snp.makeConstraints { make in
            make.centerY.equalTo(self.playPauseButton)
            make.left.equalTo(self.playPauseButton.snp.right).offset(10)
            make.right.equalTo(self.currentTimeLabel.snp.left).offset(-10)
        }
    }
    
    private func setupPlayer() {
        guard let player = videoPlayer else { return }
        
#if POOTOOLS_VIDEOCACHE
        if PTAppBaseConfig.share.videoCache {
            var observer: NSKeyValueObservation?
            observer = playerItem.observe(\.status, options: [.new, .initial]) { item, _ in
                if item.status == .readyToPlay {
                    DispatchQueue.main.async {
                        player.play()
                    }
                    observer?.invalidate()
                } else if item.status == .failed {
                    observer?.invalidate()
                }
            }
        } else {
            playerPlay(player: player)
        }
#else
        playerPlay(player: player)
#endif
    }
    
    func playerPlay(player:AVPlayer) {
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspect
        view.layer.insertSublayer(playerLayer!, at: 0)
        
        addPeriodicTimeObserver()
        addPlayerObservers()
        
        player.play()
    }
    
    // MARK: - Observers
    private func addPeriodicTimeObserver() {
        guard let player = videoPlayer else { return }
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self,
                  let duration = player.currentItem?.duration.seconds,
                  duration > 0 else { return }
            let current = time.seconds
            self.slider.value = Float(current / duration)
            self.currentTimeLabel.text = self.formatTime(current)
            self.durationLabel.text = self.formatTime(duration)
        }
    }
    
    private func addPlayerObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: videoPlayer?.currentItem
        )
    }
    
    // MARK: - Actions
    @objc private func togglePlay() {
        guard let player = videoPlayer else { return }
        if player.timeControlStatus == .playing {
            player.pause()
            playPauseButton.isSelected = false
        } else {
            player.play()
            playPauseButton.isSelected = true
        }
    }
    
    @objc private func sliderValueChanged() {
        guard let player = videoPlayer,
              let duration = player.currentItem?.duration.seconds else { return }
        let targetTime = CMTime(seconds: Double(slider.value) * duration, preferredTimescale: 600)
        player.seek(to: targetTime)
    }
    
    @objc private func playerDidFinishPlaying() {
        playPauseButton.isSelected = false
        videoPlayer?.seek(to: .zero)
    }
    
    @objc private func closeTapped() {
        // ✅ 这里你可以完全拦截返回逻辑
        self.videoPlayer?.pause()
        if let _ = onCloseTapped {
            onCloseTapped?()  // 由外部控制是否真的关闭
        } else {
            if let _ = self.sheetViewController {
                if self.navigationController?.viewControllers.last == self {
                    self.navigationController?.popViewController()
                } else {
                    self.returnFrontVC()
                }
            } else {
                self.returnFrontVC()
            }
        }
    }
    
    // MARK: - Utils
    private func formatTime(_ time: Double) -> String {
        guard !time.isNaN else { return "00:00" }
        let minutes = Int(time / 60)
        let seconds = Int(time.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
