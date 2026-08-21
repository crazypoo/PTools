//
//  PTVideoThumbnailService.swift
//  PooTools
//
//  Canonical video first-frame generation boundary.
//

import AVFoundation
import UIKit

public enum PTVideoThumbnailService {
    public static func image(for url: URL,
                             at seconds: Double = 1,
                             preferredTimescale: CMTimeScale = 10,
                             maximumSize: CGSize? = nil,
                             appliesPreferredTrackTransform: Bool = true) -> UIImage? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = appliesPreferredTrackTransform
        if let maximumSize {
            generator.maximumSize = maximumSize
        }
        let time = CMTime(seconds: seconds, preferredTimescale: preferredTimescale)
        guard let image = try? generator.copyCGImage(at: time, actualTime: nil) else {
            return nil
        }
        return UIImage(cgImage: image)
    }

    public static func image(for asset: AVAsset,
                             maximumSize: CGSize = CGSize(width: 1000, height: 1000),
                             completion: @escaping @MainActor @Sendable (UIImage?) -> Void) {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = maximumSize
        let time = CMTime(value: 0, timescale: 600)

        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, imageRef, _, result, _ in
            let imageReference = result == .succeeded ? imageRef : nil
            Task { @MainActor in
                completion(imageReference.map(UIImage.init(cgImage:)))
            }
        }
    }

    public static func image(for url: URL,
                             maximumSize: CGSize = CGSize(width: 1000, height: 1000),
                             completion: @escaping @MainActor @Sendable (UIImage?) -> Void) {
        image(for: AVAsset(url: url), maximumSize: maximumSize, completion: completion)
    }

}
