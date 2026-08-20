//
//  PTVideoEditorToolsViewController+Lifecycle.swift
//  PooTools
//

import AVFoundation
import UIKit

// MARK: - 系统级生命周期与音频管控 (App Lifecycle & Audio Session)
extension PTVideoEditorToolsViewController {
    /// 配置音频会话，突破物理静音键限制。
    func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            PTNSLogConsole("🎬 AVAudioSession 设置失败: \(error.localizedDescription)", levelType: .error, loggerType: .media)
        }
    }

    /// 注册后台运行通知，防止 GPU 后台继续占用资源。
    func setupLifecycleNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc func applicationDidEnterBackground() {
        if playerButton.isSelected {
            playerButton.isSelected = false
            c7Player?.pause()
        }
        PTNSLogConsole("🎬 App进入后台，视频编辑器已安全静默", levelType: .info, loggerType: .media)
    }
}
