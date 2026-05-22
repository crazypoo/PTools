//
//  PTSoundRecorder.swift
//  PTChatGPT
//
//  Created by 邓杰豪 on 12/3/23.
//  Copyright © 2023 SexyBoy. All rights reserved.
//

import UIKit
import AVFoundation

@MainActor
final class PTSoundRecorder: NSObject, AVAudioRecorderDelegate {
    
    // 假设 OSSSpeech 是你的其他业务逻辑
    let speechKit = OSSSpeech.shared
    
    var audioRecorder: AVAudioRecorder?
    var onUpdate: (([Float]) -> Void)?
    var soundSamples = [Float]()
    
    // 2. 使用 modern Swift 的 Task 来替代 Timer，性能更好且不受 UI 滚动影响
    private var meteringTask: Task<Void, Never>?
    
    func start() {
        // 由于类已经是 @MainActor，这里不需要再包一层 runOnMain
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: URL(fileURLWithPath: "/dev/null"), settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            
            // 3. 性能优化：只需在这里调用一次 record() 即可！
            audioRecorder?.record()
            
            soundSamples.removeAll()
            startTimer()
            
        } catch {
            print("Error starting recording: \(error.localizedDescription)")
        }
    }

    func stop() {
        audioRecorder?.stop()
        stopTimer()
    }
    
    private func startTimer() {
        // 取消旧的任务，防止重复启动
        meteringTask?.cancel()
        
        // 开启一个依附于 MainActor 的异步任务
        meteringTask = Task {
            // 只要任务没有被取消，就一直循环读取音量
            while !Task.isCancelled {
                audioRecorder?.updateMeters()
                
                // 获取分贝值 (范围通常是 -160 到 0)
                let decibels = audioRecorder?.averagePower(forChannel: 0) ?? -160.0
                
                // 性能优化：明确类型为 Double 进行运算，最后转为 Float
                let normalizedValue = Float(pow(10.0, Double(decibels) / 20.0))
                
                soundSamples.append(normalizedValue)
                onUpdate?(soundSamples)
                
                // 暂停 0.05 秒 (50,000,000 纳秒)
                // 使用 Task.sleep 不会阻塞主线程，非常高效
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }
    
    private func stopTimer() {
        // 传递最终数据并清空状态
        onUpdate?(soundSamples)
        soundSamples.removeAll()
        
        // 取消音量监听任务
        meteringTask?.cancel()
        meteringTask = nil
    }
}
