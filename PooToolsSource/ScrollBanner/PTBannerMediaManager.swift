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

class PTBannerVideoManager {

    static let shared = PTBannerVideoManager()

    private var cache = NSCache<NSString, UIImage>()

    func loadCover(url: String, completion: @escaping (UIImage?) -> Void) {
        if let img = cache.object(forKey: url as NSString) {
            completion(img)
            return
        }

        DispatchQueue.global().async {
            PTVideoCoverCache.getVideoFirstImage(videoUrl: url) { image in
                if let image = image {
                    self.cache.setObject(image, forKey: url as NSString)
                }
                DispatchQueue.main.async {
                    completion(image)
                }
            }
        }
    }
}

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
