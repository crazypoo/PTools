//
//  PTVideoEditorToolsTrimControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import AVFoundation

class PTVideoEditorToolsTrimControl: PTVideoEditorBaseFloatingViewController {

    var trimPosotionsHandler:(((Double, Double))->Void)!
    // MARK: Private Properties
    private lazy var trimmingControlView: PTVideoEditorToolsTrimmingControl = {
        let view = PTVideoEditorToolsTrimmingControl(trimPositions: self.trimPositions)
        return view
    }()
    var asset: AVAsset!
    fileprivate var trimPositions: (Double, Double)!

    init(trimPositions: (Double, Double), asset: AVAsset,typeModel:PTVideoEditorToolsModel) {
        self.trimPositions = trimPositions
        self.asset = asset
        super.init(viewControl: typeModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubviews([trimmingControlView])
        trimmingControlView.snp.makeConstraints { make in
            make.height.equalTo(60)
            make.left.right.equalToSuperview().inset(28)
            make.centerY.equalToSuperview()
        }
        
        PTGCDManager.gcdAfter(time: 0.1) {
            Task {
                do {
                    var track:AVAssetTrack!
                    if #available(iOS 16.0, *) {
                        track = try await self.asset.loadTracks(withMediaType: AVMediaType.video).first
                    } else {
                        track = self.asset.tracks(withMediaType: AVMediaType.video).first
                    }
                    let assetSize = track!.naturalSize.applying(track!.preferredTransform)
                    let ratio = abs(assetSize.width) / abs(assetSize.height)
                    let bounds = self.trimmingControlView.bounds
                    let frameWidth = bounds.height * ratio
                    let count = Int(bounds.width / frameWidth) + 1
                    
                    let cgImages = try await self.videoTimeline(for: self.asset, in: bounds, numberOfFrames: count)
                    self.updateVideoTimeline(with: cgImages, assetAspectRatio: ratio)
                } catch {
                    PTAlertTipControl.present(title:"PT Alert Opps".localized(),subtitle:error.localizedDescription,icon: .Error,style: .Normal)
                }
            }
        }
        
        doneButton.addActionHandlers { sender in
            self.trimPosotionsHandler(self.trimmingControlView.trimPositions)
            self.returnFrontVC()
        }
    }
}

fileprivate extension PTVideoEditorToolsTrimControl {
    
    func updateVideoTimeline(with images: [CGImage], assetAspectRatio: CGFloat) {
        guard !trimmingControlView.isConfigured else { return }
        guard !images.isEmpty else { return }

        trimmingControlView.configure(with: images, assetAspectRatio: assetAspectRatio)
    }
    
    func frameTimes(for asset: AVAsset,
                    numberOfFrames: Int) -> [NSValue] {
        let timeIncrement = (asset.duration.seconds * 1000) / Double(numberOfFrames)
        var timesForThumbnails = [CMTime]()

        for index in 0..<numberOfFrames {
            let cmTime = CMTime(value: Int64(timeIncrement * Float64(index)), timescale: 1000)
            timesForThumbnails.append(cmTime)
        }

        return timesForThumbnails.map(NSValue.init)
    }
        
    func videoTimeline(for asset: AVAsset,
                       in bounds: CGRect,
                       numberOfFrames: Int) async throws -> [CGImage] {
        try await withUnsafeThrowingContinuation { continuation in
            let generator = AVAssetImageGenerator(asset: asset)
            let times = self.frameTimes(for: asset, numberOfFrames: numberOfFrames)
            
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = .zero
            
            let imageStore = ImageStore()
            let errorStore = ErrorStore()
            let group = DispatchGroup()
            
            for time in times {
                group.enter()
                generator.generateCGImagesAsynchronously(forTimes: [time]) { _, cgImage, _, _, error in
                    Task {
                        if let error = error {
                            await errorStore.set(error)
                        } else if let cgImage = cgImage {
                            await imageStore.append(cgImage)
                        }
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                Task {
                    if let error = await errorStore.get() {
                        continuation.resume(throwing: error)
                    } else if await imageStore.count == numberOfFrames {
                        continuation.resume(returning: await imageStore.getImages())
                    } else {
                        continuation.resume(throwing: NSError(domain: "Error while generating CGImages", code: 0))
                    }
                }
            }
        }
    }
}
