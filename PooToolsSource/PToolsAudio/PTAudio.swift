// English: Small native audio infrastructure for session, recording, playback, and metering.
// Español: Infraestructura de audio nativa y pequeña para sesión, grabación, reproducción y medición.
// 中文：提供音频会话、录音、播放和电平采集的轻量原生基础设施。

import Foundation
import AVFoundation

#if SWIFT_PACKAGE
// English: Reuse the canonical microphone permission service instead of opening a second authorization path.
// Español: Reutiliza el servicio canónico de permiso del micrófono en lugar de abrir una segunda ruta de autorización.
// 中文：复用统一的麦克风权限服务，避免音频模块再维护一套授权路径。
import PTMicPermission
#endif

public enum PTAudioSessionCategory: String, Codable, Hashable, Sendable {
    case playback
    case record
    case playAndRecord
    case voiceChat
    case measurement
}

public struct PTAudioSessionConfiguration: Codable, Hashable, Sendable {
    public let category: PTAudioSessionCategory
    public let mode: String
    public let options: UInt

    public init(category: PTAudioSessionCategory = .playback,
                mode: String = "default",
                options: UInt = 0) {
        self.category = category
        self.mode = mode
        self.options = options
    }
}

public enum PTAudioEvent: Codable, Hashable, Sendable {
    case interruptionBegan
    case interruptionEnded(shouldResume: Bool)
    case routeChanged(reason: UInt, output: String)
    case mediaServicesReset
}

public struct PTAudioMeteringSnapshot: Codable, Hashable, Sendable {
    public let averagePower: Float
    public let peakPower: Float
    public let normalizedLevel: Float

    public init(averagePower: Float, peakPower: Float, normalizedLevel: Float) {
        self.averagePower = averagePower
        self.peakPower = peakPower
        self.normalizedLevel = min(max(normalizedLevel, 0), 1)
    }
}

public struct PTAudioWaveform: Codable, Hashable, Sendable {
    public let samples: [Float]

    public init(samples: [Float]) {
        self.samples = samples.map { min(max($0, 0), 1) }
    }

    public static func from(amplitudes: [Float], sampleCount: Int = 64) -> PTAudioWaveform {
        guard sampleCount > 0, !amplitudes.isEmpty else { return .init(samples: []) }
        let bucketSize = max(1, Int(ceil(Double(amplitudes.count) / Double(sampleCount))))
        var values: [Float] = []
        values.reserveCapacity(min(sampleCount, amplitudes.count))
        var index = 0
        while index < amplitudes.count {
            let end = min(index + bucketSize, amplitudes.count)
            let peak = amplitudes[index..<end].map { abs($0) }.max() ?? 0
            values.append(min(max(peak, 0), 1))
            index = end
        }
        return .init(samples: values)
    }
}

#if !os(macOS)

@MainActor
public final class PTAudioSessionCoordinator: NSObject {
    public static let shared = PTAudioSessionCoordinator()

    public private(set) var configuration = PTAudioSessionConfiguration()
    private let session = AVAudioSession.sharedInstance()
    private var continuations: [UUID: AsyncStream<PTAudioEvent>.Continuation] = [:]

    public override init() {
        super.init()
        installObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public func configure(_ configuration: PTAudioSessionConfiguration) throws {
        let category = Self.category(for: configuration.category)
        let mode = Self.mode(for: configuration)
        try session.setCategory(category, mode: mode, options: AVAudioSession.CategoryOptions(rawValue: configuration.options))
        self.configuration = configuration
    }

    public func activate() throws {
        try session.setActive(true, options: [])
    }

    public func deactivate() throws {
        try session.setActive(false, options: [.notifyOthersOnDeactivation])
    }

    public func events() -> AsyncStream<PTAudioEvent> {
        let id = UUID()
        return AsyncStream { continuation in
            continuations[id] = continuation
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor in self?.continuations[id] = nil }
            }
        }
    }

    public func currentOutputName() -> String? {
        session.currentRoute.outputs.first?.portName
    }

    private func installObservers() {
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector: #selector(handleInterruption(_:)),
                           name: AVAudioSession.interruptionNotification,
                           object: session)
        center.addObserver(self,
                           selector: #selector(handleRouteChange(_:)),
                           name: AVAudioSession.routeChangeNotification,
                           object: session)
        center.addObserver(self,
                           selector: #selector(handleMediaServicesReset(_:)),
                           name: AVAudioSession.mediaServicesWereResetNotification,
                           object: session)
    }

    // English: Snapshot notification values before crossing back to the MainActor.
    // Español: Captura los valores de la notificación antes de volver al MainActor.
    // 中文：在回到 MainActor 前先快照通知值，避免把 Notification 跨并发边界传递。
    @objc private func handleInterruption(_ notification: Notification) {
        let type = (notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt) ?? 0
        let options = (notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt) ?? 0
        Task { @MainActor [weak self] in
            if type == AVAudioSession.InterruptionType.began.rawValue {
                self?.emit(.interruptionBegan)
            } else {
                self?.emit(.interruptionEnded(shouldResume: options & AVAudioSession.InterruptionOptions.shouldResume.rawValue != 0))
            }
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        let reason = (notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt) ?? 0
        let output = session.currentRoute.outputs.first?.portName ?? "unknown"
        Task { @MainActor [weak self] in
            self?.emit(.routeChanged(reason: reason, output: output))
        }
    }

    @objc private func handleMediaServicesReset(_ notification: Notification) {
        _ = notification
        Task { @MainActor [weak self] in
            self?.emit(.mediaServicesReset)
        }
    }

    private func emit(_ event: PTAudioEvent) {
        continuations.values.forEach { $0.yield(event) }
    }

    private static func category(for value: PTAudioSessionCategory) -> AVAudioSession.Category {
        switch value {
        case .playback: return .playback
        case .record, .measurement: return .record
        case .playAndRecord, .voiceChat: return .playAndRecord
        }
    }

    private static func mode(for configuration: PTAudioSessionConfiguration) -> AVAudioSession.Mode {
        switch configuration.category {
        case .voiceChat: return .voiceChat
        case .measurement: return .measurement
        default:
            return AVAudioSession.Mode(rawValue: configuration.mode)
        }
    }
}

#else

@MainActor
public final class PTAudioSessionCoordinator {
    public static let shared = PTAudioSessionCoordinator()
    public private(set) var configuration = PTAudioSessionConfiguration()

    public init() {}

    public func configure(_ configuration: PTAudioSessionConfiguration) throws {
        self.configuration = configuration
    }

    public func activate() throws {}
    public func deactivate() throws {}
    public func events() -> AsyncStream<PTAudioEvent> { AsyncStream { $0.finish() } }
    public func currentOutputName() -> String? { nil }
}

#endif

public struct PTAudioRecordingConfiguration: Codable, Hashable, Sendable {
    public let sampleRate: Double
    public let channels: Int
    public let quality: Int
    public let format: PTAudioRecordingFormat
    public let meteringEnabled: Bool

    public init(sampleRate: Double = 44_100,
                channels: Int = 1,
                quality: Int = 0x60,
                format: PTAudioRecordingFormat = .m4a,
                meteringEnabled: Bool = true) {
        self.sampleRate = sampleRate
        self.channels = max(channels, 1)
        self.quality = quality
        self.format = format
        self.meteringEnabled = meteringEnabled
    }
}

public enum PTAudioRecordingFormat: String, Codable, Hashable, Sendable {
    case m4a
    case caf
    case wav
}

@MainActor
public final class PTAudioRecorder {
    public private(set) var isRecording = false
    private var recorder: AVAudioRecorder?
    private var amplitudes: [Float] = []

    public init() {}

    @discardableResult
    public func record(to url: URL,
                       configuration: PTAudioRecordingConfiguration = .init()) throws -> Bool {
        let recorder = try AVAudioRecorder(url: url, settings: configuration.settings)
        recorder.isMeteringEnabled = configuration.meteringEnabled
        guard recorder.prepareToRecord(), recorder.record() else { return false }
        self.recorder = recorder
        amplitudes.removeAll(keepingCapacity: true)
        isRecording = true
        return true
    }

    public func pause() {
        recorder?.pause()
        isRecording = false
    }

    @discardableResult
    public func stop() -> URL? {
        let url = recorder?.url
        recorder?.stop()
        recorder = nil
        isRecording = false
        return url
    }

    public func meteringSnapshot() -> PTAudioMeteringSnapshot? {
        guard let recorder else { return nil }
        recorder.updateMeters()
        let average = recorder.averagePower(forChannel: 0)
        let peak = recorder.peakPower(forChannel: 0)
        let normalized = Self.normalize(decibels: peak)
        amplitudes.append(normalized)
        return PTAudioMeteringSnapshot(averagePower: average,
                                       peakPower: peak,
                                       normalizedLevel: normalized)
    }

    public func waveform(sampleCount: Int = 64) -> PTAudioWaveform {
        PTAudioWaveform.from(amplitudes: amplitudes, sampleCount: sampleCount)
    }

    private static func normalize(decibels: Float) -> Float {
        guard decibels.isFinite else { return 0 }
        return min(max(pow(10, decibels / 20), 0), 1)
    }
}

private extension PTAudioRecordingConfiguration {
    var settings: [String: Any] {
        let formatID: AudioFormatID
        switch format {
        case .m4a: formatID = kAudioFormatMPEG4AAC
        case .caf: formatID = kAudioFormatAppleIMA4
        case .wav: formatID = kAudioFormatLinearPCM
        }
        return [
            AVFormatIDKey: formatID,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVEncoderAudioQualityKey: quality
        ]
    }
}

public enum PTAudioPlaybackState: String, Codable, Sendable {
    case idle
    case playing
    case paused
    case finished
}

public struct PTAudioPlaybackSnapshot: Codable, Hashable, Sendable {
    public let state: PTAudioPlaybackState
    public let currentTime: TimeInterval
    public let duration: TimeInterval

    public init(state: PTAudioPlaybackState,
                currentTime: TimeInterval,
                duration: TimeInterval) {
        self.state = state
        self.currentTime = currentTime
        self.duration = duration
    }
}

@MainActor
public final class PTAudioPlayer {
    public private(set) var state: PTAudioPlaybackState = .idle
    private var player: AVAudioPlayer?

    public init() {}

    public func load(fileURL: URL) throws {
        player = try AVAudioPlayer(contentsOf: fileURL)
        state = .paused
    }

    public func load(data: Data) throws {
        player = try AVAudioPlayer(data: data)
        state = .paused
    }

    public func load(resource name: String,
                     withExtension: String,
                     bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: name, withExtension: withExtension) else {
            throw NSError(domain: "PToolsAudio", code: 1)
        }
        try load(fileURL: url)
    }

    @discardableResult
    public func play() -> Bool {
        let didPlay = player?.play() ?? false
        if didPlay { state = .playing }
        return didPlay
    }

    public func pause() {
        player?.pause()
        state = .paused
    }

    public func stop() {
        player?.stop()
        player?.currentTime = 0
        state = .idle
    }

    public func seek(to time: TimeInterval) {
        player?.currentTime = min(max(time, 0), player?.duration ?? 0)
    }

    public func snapshot() -> PTAudioPlaybackSnapshot {
        let current = player?.currentTime ?? 0
        let duration = player?.duration ?? 0
        if state == .playing, let player, !player.isPlaying, current >= duration, duration > 0 {
            state = .finished
        }
        return PTAudioPlaybackSnapshot(state: state, currentTime: current, duration: duration)
    }
}

@MainActor
public enum PTAudioPermission {
    public static func requestMicrophoneAccess() async -> Bool {
#if os(iOS) || os(tvOS)
#if SWIFT_PACKAGE
        // English: Keep permission status and the completion bridge on MainActor through the existing permission type.
        // Español: Mantiene el estado del permiso y el puente de completion en MainActor mediante el tipo de permisos existente.
        // 中文：通过现有权限类型让权限状态和 completion 桥接始终在 MainActor 上执行。
        let permission = PTPermissionMic()
        guard permission.status != .authorized else { return true }
        return await withCheckedContinuation { continuation in
            permission.request {
                Task { @MainActor in
                    continuation.resume(returning: PTPermissionMic().status == .authorized)
                }
            }
        }
#else
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
#endif
#else
        return false
#endif
    }
}
