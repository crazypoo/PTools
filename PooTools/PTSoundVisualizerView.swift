//
//  PTSoundVisualizerView.swift
//  PTChatGPT
//
//  Created by 邓杰豪 on 12/3/23.
//  Copyright © 2023 SexyBoy. All rights reserved.
//

import UIKit

class PTSoundVisualizerView: UIView {

    private var sampleCount = 0
    private var currentSampleIndex = 0
    private var displayLink: CADisplayLink?
    
    public var lineColor: UIColor = .blue {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var lineWidth: CGFloat = 1.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private var samples: [Float] = [] {
        didSet {
            sampleCount = samples.count
            currentSampleIndex = 0
            setNeedsDisplay()
        }
    }
    
    func updateSamples(_ samples: [Float]) {
        self.samples = samples
    }
    
    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        samples.removeAll()
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context!.setStrokeColor(lineColor.cgColor)
        context!.setLineWidth(lineWidth)
        let height = bounds.height
        let width = bounds.width
        let step = width / CGFloat(sampleCount)
        var x: CGFloat = 0
        if samples.count > 0 {
            context!.move(to: CGPoint(x: x, y: height / 2))
        }
        for i in 0..<samples.count {
            let sample = samples[i]
            let y = (1 - CGFloat(sample)) * height
            let point = CGPoint(x: x, y: y)
            context!.addLine(to: point)
            x += step
        }
        context!.strokePath()
    }

    @objc private func update() {
        currentSampleIndex += 1
        if currentSampleIndex >= sampleCount {
            currentSampleIndex = 0
        }
        setNeedsDisplay()
    }
}
