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
        
        PTGCDManager.shared.delayOnMain(time: 0.1) {
            Task { @MainActor in
                do {
                    var track: AVAssetTrack!
                    if #available(iOS 16.0, *) {
                        track = try await self.asset.loadTracks(withMediaType: AVMediaType.video).first
                    } else {
                        track = self.asset.tracks(withMediaType: AVMediaType.video).first
                    }
                    
                    guard let validTrack = track else { return }
                    
                    let assetSize = validTrack.naturalSize.applying(validTrack.preferredTransform)
                    let ratio = abs(assetSize.width) / abs(assetSize.height)
                    let bounds = self.trimmingControlView.bounds
                    let frameWidth = bounds.height * ratio
                    let count = Int(bounds.width / frameWidth) + 1
                    
                    // 【修改点】：直接调用我们封装好的 Service！
                    // 根据 bounds 动态计算最大分辨率，保护内存
                    let scale = UIScreen.main.scale
                    let maxSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
                    
                    let cgImages = try await PTVideoTimelineService.generateVideoTimeline(
                        for: self.asset,
                        numberOfFrames: count,
                        maximumSize: maxSize
                    )
                    
                    // 切换回主线程更新 UI
                    await MainActor.run {
                        self.updateVideoTimeline(with: cgImages, assetAspectRatio: ratio)
                    }
                    
                } catch {
                    await MainActor.run {
                        PTAlertTipsViewController.tipsAlertShow(title: "PT Alert Opps".localized(), subtitle: error.localizedDescription, icon: .Error)
                    }
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
}
