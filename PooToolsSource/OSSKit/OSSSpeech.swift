//  Copyright © 2018-2020 App Dev Guy. All rights reserved.
//
//  This code is distributed under the terms and conditions of the MIT license.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

#if canImport(Speech)
import Speech
import Foundation
import AVFoundation

public enum OSSSpeechKitAuthorizationStatus: Int, Sendable {
    case notDetermined = 0
    case denied = 1
    case restricted = 2
    case authorized = 3

    public var message: String {
        // 假设上游包含 String 的 .localized() 扩展
        switch self {
        case .notDetermined: return "PT OSS messageNotDetermined".localized()
        case .denied: return "PT OSS messageDenied".localized()
        case .restricted: return "PT OSS messageRestricted".localized()
        case .authorized: return "PT OSS messageAuthorized".localized()
        }
    }
}

public enum OSSSpeechKitErrorType: Int, Sendable {
    case noMicrophoneAccess = -1
    case invalidUtterance = -2
    case invalidText = -3
    case invalidVoice = -4
    case invalidSpeechRequest = -5
    case invalidAudioEngine = -6
    case recogniserUnavailble = -7
    case invalidRecordVoice = -8
    case invalidVoiceFilePath = -9
    case invalidDeleteVoiceFilePath = -10
    case invalidTranscriptionFilePath = -11

    public var errorMessage: String {
        switch self {
        case .noMicrophoneAccess: return "PT OSS messageNoMicAccess".localized()
        case .invalidUtterance: return "PT OSS messageInvalidUtterance".localized()
        case .invalidText: return "PT OSS messageInvalidText".localized()
        case .invalidVoice: return "PT OSS messageInvalidVoice".localized()
        case .invalidSpeechRequest: return "PT OSS messageInvalidSpeechRequest".localized()
        case .invalidAudioEngine: return "PT OSS messageInvalidAudioEngine".localized()
        case .recogniserUnavailble: return "PT OSS messageRecogniserUnavailable".localized()
        case .invalidRecordVoice: return "PT OSS messageInvalidRecordVoice".localized()
        case .invalidVoiceFilePath: return "PT OSS messageInvalidVoiceFolePath".localized()
        case .invalidDeleteVoiceFilePath: return "PT OSS messageInvalidDeleteVoiceFilePath".localized()
        case .invalidTranscriptionFilePath: return "PT OSS messageInvalidTranscriptionFilePath".localized()
        }
    }

    public var errorRequestType: String {
        switch self {
        case .noMicrophoneAccess, .invalidAudioEngine, .invalidRecordVoice:
            return "PT OSS requestTypeNoMicAccess".localized()
        case .invalidUtterance: return "PT OSS requestTypeInvalidUtterance".localized()
        case .invalidText, .invalidVoice, .invalidSpeechRequest, .recogniserUnavailble:
            return "PT OSS requestTypeInvalidSpeech".localized()
        case .invalidVoiceFilePath, .invalidDeleteVoiceFilePath:
            return "PT OSS requestTypeInvalidFilePath".localized()
        case .invalidTranscriptionFilePath:
            return "PT OSS requestTypeInvalidTranscriptionFilePath".localized()
        }
    }

    public var error: Error? {
        return NSError(domain: "au.com.appdevguy.ossspeechkit",
                       code: rawValue,
                       userInfo: ["message": errorMessage, "request": errorRequestType])
    }
}

public enum OSSSpeechRecognitionTaskType: Int, Sendable {
    case undefined = 0
    case dictation = 1
    case search = 2
    case confirmation = 3

    public var taskType: SFSpeechRecognitionTaskHint {
        switch self {
        case .undefined: return .unspecified
        case .dictation: return .dictation
        case .search: return .search
        case .confirmation: return .confirmation
        }
    }
}

/// 推荐在 Swift 6 中继承自 Sendable，确保 Delegate 实例本身跨域传递安全
public protocol OSSSpeechDelegate: AnyObject, Sendable {
    func didFinishListening(withText text: String)
    func didFinishListening(withAudioFileURL url: URL, withText text: String)
    func authorizationToMicrophone(withAuthentication type: OSSSpeechKitAuthorizationStatus)
    func didFailToCommenceSpeechRecording()
    func didCompleteTranslation(withText text: String)
    func didFailToProcessRequest(withError error: Error?)
    func deleteVoiceFile(withFinish finish: Bool, withError error: Error?)
    func voiceFilePathTranscription(withText text: String)
}

/// 核心引擎，继承自 NSObject 以遵循后台 AV 代理协议。
/// 使用 @unchecked Sendable 搭配内部状态锁机制，完全适配 Swift 6 并发模型。
public class OSSSpeech: NSObject, @unchecked Sendable {

    // MARK: - 内部线程安全存储
    private let lock = NSRecursiveLock()
    
    private var _audioRecorder: AVAudioRecorder?
    private var _audioFileURL: URL?
    private var _saveRecord: Bool = true
    private var _soundSamples = [Float]()
    private var _levelTimer: Timer?
    private var _onUpdate: (([Float]) -> Void)?
    
    private var _voice: OSSVoice?
    private var _shouldUseOnDeviceRecognition = false
    private var _recognitionTaskType = OSSSpeechRecognitionTaskType.undefined
    private var _utterance: OSSUtterance?
    private weak var _delegate: OSSSpeechDelegate?
    private var _spokenText: String = ""
    
    private var _audioEngine: AVAudioEngine?
    private var _speechRecognizer: SFSpeechRecognizer?
    private var _request: SFSpeechAudioBufferRecognitionRequest?
    private var _recognitionTask: SFSpeechRecognitionTask?

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH:mm:ss"
        return formatter
    }()

    private let speechSynthesizer = AVSpeechSynthesizer()
    public var srp = SFSpeechRecognizer.self

#if !os(macOS)
    private var _session: AVAudioSession?
    public var audioSession: AVAudioSession {
        get { lock.withLock { _session ?? AVAudioSession.sharedInstance() } }
        set { lock.withLock { _session = newValue } }
    }
#endif

    // MARK: - 公开属性 (通过锁提供线程安全访问)
    public weak var delegate: OSSSpeechDelegate? {
        get { lock.withLock { _delegate } }
        set { lock.withLock { _delegate = newValue } }
    }
    public var voice: OSSVoice? {
        get { lock.withLock { _voice } }
        set { lock.withLock { _voice = newValue } }
    }
    public var shouldUseOnDeviceRecognition: Bool {
        get { lock.withLock { _shouldUseOnDeviceRecognition } }
        set { lock.withLock { _shouldUseOnDeviceRecognition = newValue } }
    }
    public var recognitionTaskType: OSSSpeechRecognitionTaskType {
        get { lock.withLock { _recognitionTaskType } }
        set { lock.withLock { _recognitionTaskType = newValue } }
    }
    public var utterance: OSSUtterance? {
        get { lock.withLock { _utterance } }
        set { lock.withLock { _utterance = newValue } }
    }
    public var saveRecord: Bool {
        get { lock.withLock { _saveRecord } }
        set { lock.withLock { _saveRecord = newValue } }
    }
    public var onUpdate: (([Float]) -> Void)? {
        get { lock.withLock { _onUpdate } }
        set { lock.withLock { _onUpdate = newValue } }
    }

    // MARK: - 单例
    public static let shared = OSSSpeech()
    private override init() { super.init() }

    // MARK: - 【Swift 6 优化】安全的主线程派发器
    private func notifyDelegateOnMain(_ block: @escaping @MainActor @Sendable () -> Void) {
        Task { @MainActor in
            block()
        }
    }
    
    // MARK: - Public 播报接口
    public func speakText(_ text: String? = nil) {
        lock.withLock {
            if _utterance == nil {
                guard let speechText = text, !speechText.isEmpty else {
                    let err = OSSSpeechKitErrorType.invalidUtterance.error
                    notifyDelegateOnMain { self.delegate?.didFailToProcessRequest(withError: err) }
                    return
                }
                _utterance = OSSUtterance(string: speechText)
            }
            if let speechText = text, !speechText.isEmpty {
                _utterance?.speechString = speechText
            }
        }
        internalSpeak()
    }

    public func speakAttributedText(attributedText: NSAttributedString) {
        if attributedText.string.isEmpty {
            let err = OSSSpeechKitErrorType.invalidText.error
            notifyDelegateOnMain { self.delegate?.didFailToProcessRequest(withError: err) }
            return
        }
        lock.withLock {
            if _utterance == nil {
                _utterance = OSSUtterance(attributedString: attributedText)
            }
            if _utterance?.attributedSpeechString.string != attributedText.string {
                _utterance?.attributedSpeechString = attributedText
            }
        }
        internalSpeak()
    }

    public func pauseSpeaking() {
        if speechSynthesizer.isSpeaking { speechSynthesizer.pauseSpeaking(at: .immediate) }
    }
    public func continueSpeaking() {
        if speechSynthesizer.isPaused { speechSynthesizer.continueSpeaking() }
    }
    public func stopSpeaking() {
        if speechSynthesizer.isSpeaking || speechSynthesizer.isPaused {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    private func internalSpeak() {
        let (targetVoice, targetUtterance) = lock.withLock { (_voice ?? OSSVoice(), _utterance) }
        let validString = targetUtterance?.speechString ?? "error"
        let newUtterance = AVSpeechUtterance(string: validString)
        newUtterance.voice = targetVoice

        if let valid = targetUtterance {
            newUtterance.rate = valid.rate
            newUtterance.pitchMultiplier = valid.pitchMultiplier
            newUtterance.volume = valid.volume
        }

        setSession(isRecording: false)
        stopSpeaking()
        speechSynthesizer.speak(newUtterance)
    }

    @discardableResult private func setSession(isRecording: Bool) -> Bool {
#if !os(macOS)
        do {
            let category: AVAudioSession.Category = isRecording ? .playAndRecord : .playback
            try audioSession.setCategory(category, options: isRecording ? .defaultToSpeaker : .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            return true
        } catch {
            notifyDelegateOnMain {
                if isRecording { self.delegate?.didFailToCommenceSpeechRecording() }
                self.delegate?.didFailToProcessRequest(withError: error)
            }
            return false
        }
#else
        return false
#endif
    }

    // MARK: - 语音识别录音机制
    public func recordVoice(requestMicPermission requested: Bool = true) {
#if !os(macOS)
        if requested, audioSession.recordPermission != .granted {
            requestMicPermission()
            return
        }
#endif
        getMicroPhoneAuthorization()
    }

    public func endVoiceRecording() {
        cancelRecording()
    }

    public func clearSpokenText() {
        lock.withLock { _spokenText = "" }
    }

    private func requestMicPermission() {
#if !os(macOS)
        // 确保闭包标注为 @Sendable
        audioSession.requestRecordPermission { @Sendable [weak self] allowed in
            guard let self = self else { return }
            if !allowed {
                self.notifyDelegateOnMain { self.delegate?.authorizationToMicrophone(withAuthentication: .denied) }
                return
            }
            self.getMicroPhoneAuthorization()
        }
#endif
    }

    private func getMicroPhoneAuthorization() {
        srp.requestAuthorization { @Sendable [weak self] authStatus in
            guard let self = self else { return }
            let status = OSSSpeechKitAuthorizationStatus(rawValue: authStatus.rawValue) ?? .notDetermined
            self.notifyDelegateOnMain { self.delegate?.authorizationToMicrophone(withAuthentication: status) }

            if status == .authorized {
                // 改用现代并发任务启动
                Task {
                    self.recordAndRecognizeSpeech()
                }
            }
        }
    }

    private func resetAudioEngine() {
        lock.withLock {
            if let engine = _audioEngine, engine.isRunning { engine.stop() }
            _audioEngine?.inputNode.removeTap(onBus: 0)
            _audioRecorder?.stop()
            stopVisualizerTimer()
            
            if let node = _audioEngine?.inputNode, node.inputFormat(forBus: 0).channelCount == 0 {
                node.reset()
            }
            _audioEngine?.reset()
        }
    }

    private func cancelRecording() {
        lock.withLock {
            _request?.endAudio()
            _request = nil
            _recognitionTask?.finish()
        }
        resetAudioEngine()
    }

    private func engineSetup() {
        lock.lock()
        if _audioEngine == nil { _audioEngine = AVAudioEngine() }
        guard let engine = _audioEngine else {
            lock.unlock()
            notifyEngineError()
            return
        }
        let input = engine.inputNode
        let recordingFormat = input.outputFormat(forBus: 0)
        guard let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 8000, channels: 1, interleaved: true),
              let converter = AVAudioConverter(from: recordingFormat, to: outputFormat) else {
            lock.unlock()
            notifyEngineError()
            return
        }
        lock.unlock()

        // 【Swift 6 规范】定义一个内部引用类型容器来持有状态，并标记为 @unchecked Sendable
        // 因为 Tap 回调本身在单一音频线程按顺序同步触发，内部状态修改是绝对安全的。
        final class ConverterState: @unchecked Sendable {
            var hasData: Bool = true
        }

        input.installTap(onBus: 0, bufferSize: 8192, format: recordingFormat) { @Sendable [weak self] (buffer, _) in
            // 使用 let 声明容器实例，完美通过逃逸闭包的捕获校验
            let state = ConverterState()
            
            let inputCallback: AVAudioConverterInputBlock = { _, outStatus in
                if state.hasData {
                    outStatus.pointee = .haveData
                    state.hasData = false
                    return buffer
                } else {
                    outStatus.pointee = .noDataNow
                    return nil
                }
            }
            
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(outputFormat.sampleRate) * buffer.frameLength / AVAudioFrameCount(buffer.format.sampleRate)) else { return }
            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)

            if status == .error {
                self?.notifyEngineError(error)
                return
            }
            self?.lock.withLock { self?._request?.append(convertedBuffer) }
        }

        engine.prepare()
        do { try engine.start() } catch { notifyEngineError(error) }
    }

    private func notifyEngineError(_ error: Error? = nil) {
        notifyDelegateOnMain {
            self.delegate?.didFailToCommenceSpeechRecording()
            self.delegate?.didFailToProcessRequest(withError: error ?? OSSSpeechKitErrorType.invalidAudioEngine.error)
        }
    }

    private func recordAndRecognizeSpeech() {
        lock.lock()
        if let recognizer = _speechRecognizer, !recognizer.isAvailable {
            lock.unlock()
            cancelRecording()
            setSession(isRecording: false)
            lock.lock()
        }
        if speechSynthesizer.isSpeaking { stopSpeaking() }
        lock.unlock()

        guard setSession(isRecording: true) else { return }

        lock.lock()
        _request = SFSpeechAudioBufferRecognitionRequest()
        let identifier = _voice?.voiceType.rawValue ?? OSSVoiceEnum.UnitedStatesEnglish.rawValue
        _speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier))
        let targetRec = _speechRecognizer
        let targetReq = _request
        let targetShouldUseOnDevice = _shouldUseOnDeviceRecognition
        let targetTaskHint = _recognitionTaskType.taskType
        let isRecValid = targetRec?.isAvailable ?? false
        let isSaveRecord = _saveRecord
        lock.unlock()

        guard let recognizer = targetRec, isRecValid else {
            let errType: OSSSpeechKitErrorType = targetRec == nil ? .invalidSpeechRequest : .recogniserUnavailble
            notifyDelegateOnMain {
                self.delegate?.didFailToCommenceSpeechRecording()
                self.delegate?.didFailToProcessRequest(withError: errType.error)
            }
            return
        }

        engineSetup()

        if let audioRequest = targetReq {
            if recognizer.supportsOnDeviceRecognition {
                audioRequest.requiresOnDeviceRecognition = targetShouldUseOnDevice
            }
            recognizer.defaultTaskHint = targetTaskHint
            lock.withLock {
                _recognitionTask = recognizer.recognitionTask(with: audioRequest, delegate: self)
            }
        }

        if isSaveRecord { readyToRecord() }
    }

    private func readyToRecord() {
        let dateString = lock.withLock { dateFormatter.string(from: Date()) }
        let url = getDocumentsDirectory().appendingPathComponent("\(dateString)-osKit.m4a")
        
        lock.withLock { _audioFileURL = url }

        let audioSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let recorder = try AVAudioRecorder(url: url, settings: audioSettings)
            recorder.isMeteringEnabled = true
            recorder.delegate = self
            recorder.prepareToRecord()
            recorder.record()
            
            lock.withLock {
                _audioRecorder = recorder
                _soundSamples.removeAll()
            }
            visualizerTimer()
        } catch {
            notifyDelegateOnMain { self.delegate?.didFailToProcessRequest(withError: OSSSpeechKitErrorType.invalidRecordVoice.error) }
        }
    }

    private func visualizerTimer() {
        let interval: Double = 0.01
        lock.withLock { _ = _audioRecorder?.record(forDuration: interval) }

        // 使用 Task 结合 MainActor 保证 Timer 完美运行在主线程生命周期
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                let (decibels, cbUpdate) = self.lock.withLock { () -> (Float, (([Float]) -> Void)?) in
                    self._audioRecorder?.updateMeters()
                    let db = self._audioRecorder?.averagePower(forChannel: 0) ?? -160
                    let normalized = pow(10, db / 20)
                    self._soundSamples.append(normalized)
                    self._audioRecorder?.record(forDuration: interval)
                    return (db, self._onUpdate)
                }

                // 派发出采集到的样本
                if let cb = cbUpdate {
                    let currentSamples = self.lock.withLock { self._soundSamples }
                    cb(currentSamples)
                }
            }
            self.lock.withLock { self._levelTimer = timer }
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopVisualizerTimer() {
        let (cbUpdate, currentSamples, timer) = lock.withLock { () -> ((([Float]) -> Void)?, [Float], Timer?) in
            let cb = _onUpdate
            let samples = _soundSamples
            let t = _levelTimer
            _soundSamples.removeAll()
            _levelTimer = nil
            return (cb, samples, t)
        }
        
        timer?.invalidate()
        notifyDelegateOnMain { cbUpdate?(currentSamples) }
    }

    public func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    public func deleteVoiceFolderItem(url: URL?) {
        let fileManager = FileManager.default
        let folderURL = getDocumentsDirectory()

        do {
            let contents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for fileURL in contents {
                if let targetURL = url {
                    if fileURL.absoluteString == targetURL.absoluteString {
                        try fileManager.removeItem(at: fileURL)
                        notifyDelegateOnMain { self.delegate?.deleteVoiceFile(withFinish: true, withError: nil) }
                        return
                    }
                } else {
                    if fileURL.lastPathComponent.contains("-osKit.m4a") {
                        try fileManager.removeItem(at: fileURL)
                    }
                }
            }
            if url == nil {
                notifyDelegateOnMain { self.delegate?.deleteVoiceFile(withFinish: true, withError: nil) }
            }
        } catch {
            notifyDelegateOnMain { self.delegate?.deleteVoiceFile(withFinish: false, withError: OSSSpeechKitErrorType.invalidDeleteVoiceFilePath.error) }
        }
    }

    public func recognizeSpeech(filePath: URL, finalBlock: ((_ text: String) -> Void)? = nil) {
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            notifyDelegateOnMain { self.delegate?.didFailToProcessRequest(withError: OSSSpeechKitErrorType.invalidVoiceFilePath.error) }
            return
        }

        let identifier = lock.withLock { _voice?.voiceType.rawValue ?? OSSVoiceEnum.UnitedStatesEnglish.rawValue }
        let localRecognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier))
        lock.withLock { _speechRecognizer = localRecognizer }

        guard let audioFile = try? AVAudioFile(forReading: filePath) else {
            notifyDelegateOnMain { self.delegate?.didFailToProcessRequest(withError: OSSSpeechKitErrorType.invalidVoiceFilePath.error) }
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: audioFile.url)
        localRecognizer?.recognitionTask(with: request) { @Sendable [weak self] (result, error) in
            guard let self = self else { return }
            if let result = result, result.isFinal {
                let transcription = result.bestTranscription.formattedString
                self.notifyDelegateOnMain {
                    if let block = finalBlock {
                        block(transcription)
                    } else {
                        self.delegate?.voiceFilePathTranscription(withText: transcription)
                    }
                }
            } else if error != nil {
                self.notifyDelegateOnMain { self.delegate?.didFailToProcessRequest(withError: OSSSpeechKitErrorType.invalidTranscriptionFilePath.error) }
            }
        }
    }
}

// MARK: - 扩展遵循代理
extension OSSSpeech: SFSpeechRecognitionTaskDelegate, SFSpeechRecognizerDelegate {
    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        let (spoken, isSave, fileURL) = lock.withLock { () -> (String, Bool, URL?) in
            _recognitionTask = nil
            return (_spokenText, _saveRecord, _audioFileURL)
        }
        
        notifyDelegateOnMain {
            self.delegate?.didFinishListening(withText: spoken)
            if isSave, let targetURL = fileURL {
                self.delegate?.didFinishListening(withAudioFileURL: targetURL, withText: spoken)
            }
        }
        setSession(isRecording: false)
    }

    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        let text = transcription.formattedString
        notifyDelegateOnMain { self.delegate?.didCompleteTranslation(withText: text) }
    }

    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        lock.withLock { _spokenText = recognitionResult.bestTranscription.formattedString }
    }

    public func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {}
    public func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {}
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {}
}

extension OSSSpeech: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            lock.withLock { _audioRecorder?.stop() }
            stopVisualizerTimer()
        }
    }
}
#endif
