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

    @discardableResult
    public func loadCover(url: String,
                          frameNumber: Int = 1,
                          maximumSize: CGSize = PTVideoThumbnailService.defaultMaximumSize,
                          completion: @escaping @MainActor @Sendable (UIImage?) -> Void) -> Task<Void, Never>? {
        guard let url = URL(string: url) else {
            completion(nil)
            return nil
        }
        return loadCover(url: url,
                         frameNumber: frameNumber,
                         maximumSize: maximumSize,
                         completion: completion)
    }

    @discardableResult
    public func loadCover(url: URL,
                          frameNumber: Int = 1,
                          maximumSize: CGSize = PTVideoThumbnailService.defaultMaximumSize,
                          completion: @escaping @MainActor @Sendable (UIImage?) -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            guard !Task.isCancelled else { return }
            let image = await PTVideoCoverCache.image(for: url,
                                                      frameNumber: frameNumber,
                                                      maximumSize: maximumSize)
            guard !Task.isCancelled else { return }
            completion(image)
        }
    }
}

@MainActor
public final class PTBannerPlayerManager {

    public static let shared = PTBannerPlayerManager()

    public var player: AVPlayer?
    public var playerLayer: AVPlayerLayer?
    private weak var currentContainer: UIView?
    private var pipController: AVPictureInPictureController?
    private var playbackEndObserver: NSObjectProtocol?
    public var playEndCallback: PTActionTask?

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
        playbackEndObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                                      object: player.currentItem,
                                                                      queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.replay()
            }
        }
    }

    private func attach(layer: AVPlayerLayer, to view: UIView) {
        layer.removeFromSuperlayer()
        currentContainer?.layer.sublayers?.removeAll(where: { $0 is AVPlayerLayer })

        layer.frame = view.bounds
        view.layer.insertSublayer(layer, at: 0)

        currentContainer = view
    }

    func stop() {
        // 移除播放结束的通知，防止单例导致的通知堆积
        if let playbackEndObserver {
            NotificationCenter.default.removeObserver(playbackEndObserver)
            self.playbackEndObserver = nil
        }
        
        pipController?.stopPictureInPicture()
        pipController = nil
        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        currentURL = nil
        currentContainer = nil
    }

    func stopIfContainerBelongs(to owner: UIView) {
        guard let currentContainer,
              currentContainer === owner || currentContainer.isDescendant(of: owner) else { return }
        stop()
    }

    func updateLayerFrame() {
        playerLayer?.frame = currentContainer?.bounds ?? .zero
    }

    @objc private func replay() {
        playEndCallback?()
        player?.seek(to: .zero)
        player?.play()
    }
}

extension PTBannerPlayerManager {

    public func startPiP() {
        guard let layer = playerLayer else { return }

        if AVPictureInPictureController.isPictureInPictureSupported() {
            pipController?.stopPictureInPicture()
            pipController = AVPictureInPictureController(playerLayer: layer)
            pipController?.startPictureInPicture()
        }
    }
    
    public func pause() {
        player?.pause()
    }

    public func resume() {
        player?.play()
    }
}
