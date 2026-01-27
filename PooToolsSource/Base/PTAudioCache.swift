//
//  PTAudioCache.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 27/1/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import AVFoundation

public final class PTAudioCache {

    public static let shared = PTAudioCache()

    private let assetCache = NSCache<NSString, AVURLAsset>()
    private let durationCache = NSCache<NSString, NSNumber>()

    private init() {
        assetCache.countLimit = 100
        durationCache.countLimit = 500
    }

    private func key(for url: URL) -> NSString {
        NSString(string: url.absoluteString)
    }

    // MARK: - 获取 Asset（复用）
    public func asset(for url: URL) -> AVURLAsset {
        let key = key(for: url)

        if let asset = assetCache.object(forKey: key) {
            return asset
        }

        let asset = AVURLAsset(url: url)
        assetCache.setObject(asset, forKey: key)
        return asset
    }

    // MARK: - 异步获取时长（重写版）
    // MARK: - 异步获取时长（官方正确方式）
    public func duration(for url: URL,completion: @escaping (Float) -> Void) {
        let key = key(for: url)

        // 1️⃣ 命中缓存
        if let value = durationCache.object(forKey: key) {
            completion(value.floatValue)
            return
        }

        let asset = asset(for: url)
        let durationKey = "duration"

        asset.loadValuesAsynchronously(forKeys: [durationKey]) { [weak self] in
            var error: NSError?

            let status = asset.statusOfValue(forKey: durationKey, error: &error)

            let seconds: Float
            if status == .loaded {
                seconds = Float(CMTimeGetSeconds(asset.duration))
                self?.durationCache.setObject(
                    NSNumber(value: seconds),
                    forKey: key
                )
            } else {
                seconds = 0
            }

            DispatchQueue.main.async {
                completion(seconds)
            }
        }
    }
    
    // MARK: - 创建 PlayerItem（播放用）
    public func playerItem(for url: URL) -> AVPlayerItem {
        let asset = asset(for: url)
        return AVPlayerItem(asset: asset)
    }
}
