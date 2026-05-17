//
//  PTVideoManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/3/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

@MainActor
class PTBannerVideoManager {

    static let shared = PTBannerVideoManager()

    private var cache = NSCache<NSString, UIImage>()

    public func loadCover(url: String, completion: @escaping @MainActor @Sendable (UIImage?) -> Void) {
        if let img = cache.object(forKey: url as NSString) {
            completion(img)
            return
        }

        // 🌟 修复 2：使用 [weak self] 弱捕获，防止在后台线程强持有 @MainActor 隔离的对象
        PTVideoCoverCache.getVideoFirstImage(videoUrl: url) { [weak self] image in
            // 回到主线程执行 UI 和缓存相关的操作
            Task { @MainActor in
                if let image = image {
                    // 🌟 修复 3：通过可选链安全地访问 self，即使对象在等待期间释放也不会崩溃
                    self?.cache.setObject(image, forKey: url as NSString)
                }
                // 安全地执行标记了 @MainActor 的闭包
                completion(image)
            }
        }
    }
}

@MainActor
public final class PTBannerPlayerManager {

    public static let shared = PTBannerPlayerManager()

    public var player: AVPlayer?
    public var playerLayer: AVPlayerLayer?
    private weak var currentContainer: UIView?

    private var currentURL: String?

    // MARK: 播放
    func play(url: String, in view: UIView) {

        // 相同视频不重复创建
        if currentURL == url, let layer = playerLayer {
            attach(layer: layer, to: view)
            player?.play()
            return
        }

        stop()

        guard var videoURL = URL(string: url) else { return }

        if let findCache = PTVideoFileCache.shared.cachedFileURL(for: videoURL) {
            videoURL = findCache
        }
        
        let player = AVPlayer(url: videoURL)
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill

        self.player = player
        self.playerLayer = layer
        self.currentURL = url

        attach(layer: layer, to: view)

        player.play()
        player.isMuted = true
        // 播放结束
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(replay),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
    }

    private func attach(layer: AVPlayerLayer, to view: UIView) {
        currentContainer?.layer.sublayers?.removeAll(where: { $0 is AVPlayerLayer })

        layer.frame = view.bounds
        view.layer.insertSublayer(layer, at: 0)

        currentContainer = view
    }

    func stop() {
        // 移除播放结束的通知，防止单例导致的通知堆积
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        currentURL = nil
    }

    @objc private func replay() {
        player?.seek(to: .zero)
        player?.play()
    }
}

extension PTBannerPlayerManager {

    public func startPiP() {
        guard let layer = playerLayer else { return }

        if AVPictureInPictureController.isPictureInPictureSupported() {
            let pip = AVPictureInPictureController(playerLayer: layer)
            pip?.startPictureInPicture()
        }
    }
    
    public func pause() {
        player?.pause()
    }

    public func resume() {
        player?.play()
    }
}
