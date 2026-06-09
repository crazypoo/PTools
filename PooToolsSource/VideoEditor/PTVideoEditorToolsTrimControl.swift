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

private struct PTSafeMediaBox<T>: @unchecked Sendable {
    let mediaItem: T
}

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
                    let tracks = try await self.asset.loadTracks(withMediaType: .video)
                    guard let validTrack = tracks.first else { return }
                    
                    // 🌟 核心修正：放弃 async let，避免非 Sendable 对象的跨线程传递
                    // 因为 track 已经加载完毕，这两个顺序 await 也是瞬间完成的
                    let naturalSize = try await validTrack.load(.naturalSize)
                    let preferredTransform = try await validTrack.load(.preferredTransform)
                    
                    let assetSize = naturalSize.applying(preferredTransform)
                    
                    // 增加防御性校验，避免极端情况除以 0
                    guard assetSize.height != 0 else { return }
                    let ratio = abs(assetSize.width) / abs(assetSize.height)
                    
                    let bounds = self.trimmingControlView.bounds
                    let frameWidth = bounds.height * ratio
                    let count = Int(bounds.width / frameWidth) + 1
                    
                    let scale: CGFloat = (UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene)?.screen.scale ?? 2.0
                    let maxSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
                    let newAsset = PTSafeMediaBox(mediaItem: self.asset)
                    
                    // 后台去疯狂截帧，主线程在这里暂停等待
                    let cgImages = try await PTVideoTimelineService.generateVideoTimeline(
                        for: newAsset.mediaItem!,
                        numberOfFrames: count,
                        maximumSize: maxSize
                    )
                    
                    // 拿到 cgImages 后，自动恢复在主线程更新 UI
                    self.updateVideoTimeline(with: cgImages, assetAspectRatio: ratio)
                    
                } catch {
                    // 出错时也同样自动处于主线程，直接弹窗
                    PTAlertTipsViewController.tipsAlertShow(title: "PT Alert Opps".localized(),
                                                            subtitle: error.localizedDescription,
                                                            icon: .Error)
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
