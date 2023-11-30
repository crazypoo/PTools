//
//  C7CollectorVideo.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import AVFoundation
import Harbeth

public final class C7CollectorVideo: C7Collector {
    
    private var player: AVPlayer!
    public private(set) var videoOutput: AVPlayerItemVideoOutput!
    
    lazy var displayLink: CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(readBuffer(_:)))
        displayLink.add(to: .current, forMode: RunLoop.Mode.default)
        displayLink.isPaused = true
        return displayLink
    }()
    
    public convenience init(player: AVPlayer, delegate: C7CollectorImageDelegate) {
        self.init(delegate: delegate)
        self.player = player
        setupPlayer(player)
    }
    
    public override func setupInit() {
        super.setupInit()
        setupVideoOutput()
    }
}

extension C7CollectorVideo {
    
    public func play() {
        player.play()
        displayLink.isPaused = false
    }
    
    public func pause() {
        player.pause()
        displayLink.isPaused = true
    }
}

extension C7CollectorVideo {
    
    func setupPlayer(_ player: AVPlayer) {
        if let currentItem = player.currentItem {
            currentItem.add(videoOutput)
        }
    }
    
    func setupVideoOutput() {
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: videoSettings)
    }
    
    @objc func readBuffer(_ sender: CADisplayLink) {
        let time = videoOutput.itemTime(forHostTime: sender.timestamp + sender.duration)
        guard videoOutput.hasNewPixelBuffer(forItemTime: time) else {
            return
        }
        let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil)
        self.processing(with: pixelBuffer)
    }
}
