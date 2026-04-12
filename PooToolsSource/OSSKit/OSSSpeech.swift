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

/// The authorization status of the Microphone and recording, imitating the native `SFSpeechRecognizerAuthorizationStatus`
public enum OSSSpeechKitAuthorizationStatus: Int {
    /// The app's authorization status has not yet been determined.
    case notDetermined = 0
    /// The user denied your app's request to perform speech recognition.
    case denied = 1
    /// The device prevents your app from performing speech recognition.
    case restricted = 2
    /// The user granted your app's request to perform speech recognition.
    case authorized = 3

    /// A public message that can be displayed to the user.
    public var message: String {
        switch self {
        case .notDetermined:
            return "PT OSS messageNotDetermined".localized()
        case .denied:
            return "PT OSS messageDenied".localized()
        case .restricted:
            return "PT OSS messageRestricted".localized()
        case .authorized:
            return "PT OSS messageAuthorized".localized()
        }
    }
}

/// All of the possible error types that can be thrown by OSSSpeechKit
public enum OSSSpeechKitErrorType: Int {
    /// No microphone access
    case noMicrophoneAccess = -1
    /// An invalid utterance.
    case invalidUtterance = -2
    /// Invalid text - usually an empty string.
    case invalidText = -3
    /// The voice type is invalid.
    case invalidVoice = -4
    /// Speech recognition request is invalid.
    case invalidSpeechRequest = -5
    /// The audio engine is invalid.
    case invalidAudioEngine = -6
    /// Voice recognition is unavailable.
    case recogniserUnavailble = -7
    /// Voice record is invalid
    case invalidRecordVoice = -8
    ///  Voice record file path is Invalid
    case invalidVoiceFilePath = -9
    /// Voice record file path can not delete
    case invalidDeleteVoiceFilePath = -10
    /// Voice record file path can not transcription
    case invalidTranscriptionFilePath = -11

    /// The OSSSpeechKit error message string.
    ///
    /// The error message strings can be altered in the Localized strings file.
    public var errorMessage: String {
        switch self {
        case .noMicrophoneAccess:
            return "PT OSS messageNoMicAccess".localized()
        case .invalidUtterance:
            return "PT OSS messageInvalidUtterance".localized()
        case .invalidText:
            return "PT OSS messageInvalidText".localized()
        case .invalidVoice:
            return "PT OSS messageInvalidVoice".localized()
        case .invalidSpeechRequest:
            return "PT OSS messageInvalidSpeechRequest".localized()
        case .invalidAudioEngine:
            return "PT OSS messageInvalidAudioEngine".localized()
        case .recogniserUnavailble:
            return "PT OSS messageRecogniserUnavailable".localized()
        case .invalidRecordVoice:
            return "PT OSS messageInvalidRecordVoice".localized()
        case .invalidVoiceFilePath:
            return "PT OSS messageInvalidVoiceFolePath".localized()
        case .invalidDeleteVoiceFilePath:
            return "PT OSS messageInvalidDeleteVoiceFilePath".localized()
        case .invalidTranscriptionFilePath:
            return "PT OSS messageInvalidTranscriptionFilePath".localized()
        }
    }

    /// The highlevel type of error that occured.
    ///
    /// A String will be used in the OSSSpeechKitErrorType error: Error? that is returned when an exception is thrown.
    public var errorRequestType: String {
        switch self {
        case .noMicrophoneAccess,
            .invalidAudioEngine,
            .invalidRecordVoice:
            return "PT OSS requestTypeNoMicAccess".localized()
        case .invalidUtterance:
            return "PT OSS requestTypeInvalidUtterance".localized()
        case .invalidText,
             .invalidVoice,
             .invalidSpeechRequest,
             .recogniserUnavailble:
            return "PT OSS requestTypeInvalidSpeech".localized()
        case .invalidVoiceFilePath,.invalidDeleteVoiceFilePath:
            return "PT OSS requestTypeInvalidFilePath".localized()
        case .invalidTranscriptionFilePath:
            return "PT OSS requestTypeInvalidTranscriptionFilePath".localized()
        }
    }

    /// An error that is used to capture details of the error event.
    public var error: Error? {
        let err = NSError(domain: "au.com.appdevguy.ossspeechkit",
                          code: rawValue,
                          userInfo: ["message": errorMessage, "request": errorRequestType])
        return err
    }
}

/// The speech recognition task type.
public enum OSSSpeechRecognitionTaskType: Int {
    /// Undefined is the standard recognition type and allows the system to decide which type of task is best.
    case undefined = 0
    /// Use captured speech for text entry purposes.
    ///
    /// Use this when doing a similar task that of the keyboard voice to text function.
    case dictation = 1
    /// Use this short speechs that have specific words or terms.
    case search = 2
    /// Use this for short speechs such as "Yes", "No", "Thanks", etc.
    case confirmation = 3

    /// Returns a speech recognition hint based on the enum value.
    public var taskType: SFSpeechRecognitionTaskHint {
        switch self {
        case .undefined:
            return .unspecified
        case .dictation:
            return .dictation
        case .search:
            return .search
        case .confirmation:
            return .confirmation
        }
    }
}

/// Delegate to handle events such as failed authentication for microphone among many more.
public protocol OSSSpeechDelegate: AnyObject {
    /// When the microphone has finished accepting audio, this delegate will be called with the final best text output.
    func didFinishListening(withText text: String)
    ///When the microphone has finished accepting recording, this function will be called with the final best text output or voice file path.
    func didFinishListening(withAudioFileURL url: URL,withText text: String)
    /// Handle returning authentication status to user - primary use is for non-authorized state.
    func authorizationToMicrophone(withAuthentication type: OSSSpeechKitAuthorizationStatus)
    /// If the speech recogniser and request fail to set up, this method will be called.
    func didFailToCommenceSpeechRecording()
    /// Method for real time recpetion of translated text.
    func didCompleteTranslation(withText text: String)
    /// Error handling function.
    func didFailToProcessRequest(withError error: Error?)
    /// When delete some voice file,this delegate will be return success or not
    func deleteVoiceFile(withFinish finish: Bool ,withError error: Error?)
    /// Get the content according to the path of the voice file
    func voiceFilePathTranscription(withText text:String)
}


/// Speech is the primary interface. To use, set the voice and then call `.speak(string: "your string")`
public class OSSSpeech: NSObject {

    // MARK: - Private Properties

    private var audioRecorder: AVAudioRecorder?
    // 【优化】移除强制解包 !，改为可选型 ? 保证安全
    private var audioFileURL: URL?
    public var saveRecord: Bool = true
    private var soundSamples = [Float]()
    private var levelTimer: Timer?
    public var onUpdate: (([Float]) -> Void)?

    // 【优化】性能提升：将 DateFormatter 提取为复用的 lazy 变量，避免频繁初始化带来的性能开销
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH:mm:ss"
        return formatter
    }()

    private var speechSynthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()

    // MARK: - Variables

    public weak var delegate: OSSSpeechDelegate?
    public var voice: OSSVoice?
    public var shouldUseOnDeviceRecognition = false
    public var recognitionTaskType = OSSSpeechRecognitionTaskType.undefined
    public var utterance: OSSUtterance?

    #if !os(macOS)
    private var session: AVAudioSession?
    public var audioSession: AVAudioSession {
        get { session ?? AVAudioSession.sharedInstance() }
        set { session = newValue }
    }
    #endif

    public var srp = SFSpeechRecognizer.self

    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var spokenText: String = ""

    // MARK: - Lifecycle

    private override init() {
        super.init()
    }

    public static let shared = OSSSpeech()

    // MARK: - Public Methods
    
    // 【辅助方法】确保 Delegate 始终在主线程被调用，防止外部 UI 更新崩溃
    private func safeDelegateCall(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async { block() }
        }
    }

    public func speakText(_ text: String? = nil) {
        if !utteranceIsValid() {
            guard let speechText = text, !speechText.isEmpty else {
                PTNSLogConsole("PT OSS text is empty".localized(), levelType: PTLogMode, loggerType: .speech)
                safeDelegateCall { self.delegate?.didFailToProcessRequest(withError: OSSSpeechKitErrorType.invalidUtterance.error) }
                return
            }
            utterance = OSSUtterance(string: speechText)
        }
        if let speechText = text, !speechText.isEmpty {
            utterance?.speechString = speechText
        }
        speak()
    }

    public func speakAttributedText(attributedText: NSAttributedString) {
        if attributedText.string.isEmpty {
            PTNSLogConsole("PT OSS text is empty".localized(), levelType: PTLogMode, loggerType: .speech)
            safeDelegateCall { self.delegate?.didFailToProcessRequest(withError: OSSSpeechKitErrorType.invalidText.error) }
            return
        }
        if !utteranceIsValid() {
            utterance = OSSUtterance(attributedString: attributedText)
        }
        if utterance?.attributedSpeechString.string != attributedText.string {
            utterance?.attributedSpeechString = attributedText
        }
        speak()
    }

    public func pauseSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.pauseSpeaking(at: .immediate)
        }
    }

    public func continueSpeaking() {
        if speechSynthesizer.isPaused {
            speechSynthesizer.continueSpeaking()
        }
    }

    public func stopSpeaking() {
        if speechSynthesizer.isSpeaking || speechSynthesizer.isPaused {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    // MARK: - Private Methods

    private func utteranceIsValid() -> Bool {
        guard utterance != nil else {
            PTNSLogConsole("PT OSS no utterance".localized(), levelType: PTLogMode, loggerType: .speech)
            return false
        }
        return true
    }

    private func speak() {
        let speechVoice = voice ?? OSSVoice()
        let validString = utterance?.speechString ?? "error"
        let newUtterance = AVSpeechUtterance(string: validString)
        newUtterance.voice = speechVoice
        
        if let validUtterance = utterance {
            newUtterance.rate = validUtterance.rate
            newUtterance.pitchMultiplier = validUtterance.pitchMultiplier
            newUtterance.volume = validUtterance.volume
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
            safeDelegateCall {
                if isRecording { self.delegate?.didFailToCommenceSpeechRecording() }
                self.delegate?.didFailToProcessRequest(withError: error)
            }
            return false
        }
        #else
        return false
        #endif
    }

    // MARK: - Public Voice Recording Methods

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
        spokenText = ""
    }
    
    // MARK: - Private Voice Recording

    private func requestMicPermission() {
        #if !os(macOS)
        audioSession.requestRecordPermission { [weak self] allowed in
            guard let self = self else { return }
            if !allowed {
                PTNSLogConsole("PT OSS messageNoMicAccess".localized(), levelType: PTLogMode, loggerType: .speech)
                self.safeDelegateCall { self.delegate?.authorizationToMicrophone(withAuthentication: .denied) }
                return
            }
            self.getMicroPhoneAuthorization()
        }
        #endif
    }

    private func getMicroPhoneAuthorization() {
        srp.requestAuthorization { [weak self] authStatus in
            guard let self = self else { return }
            let status = OSSSpeechKitAuthorizationStatus(rawValue: authStatus.rawValue) ?? .notDetermined
            self.safeDelegateCall { self.delegate?.authorizationToMicrophone(withAuthentication: status) }
            
            if status == .authorized {
                OperationQueue.main.addOperation {
                    self.recordAndRecognizeSpeech()
                }
            }
        }
    }

    private func resetAudioEngine() {
        guard let engine = audioEngine else { return }
        if engine.isRunning { engine.stop() }
        let node = engine.inputNode
        node.removeTap(onBus: 0)
        
        audioRecorder?.stop()
        stopVisualizerTimer()
        
        if node.inputFormat(forBus: 0).channelCount == 0 {
            node.reset()
        }
        audioEngine?.reset()
    }

    private func cancelRecording() {
        request?.endAudio()
        request = nil
        recognitionTask?.finish()
        resetAudioEngine()
    }

    private func engineSetup() {
        if audioEngine == nil { audioEngine = AVAudioEngine() }
        guard let engine = audioEngine else {
            notifyEngineError()
            return
        }
        
        let input = engine.inputNode
        let recordingFormat = input.outputFormat(forBus: 0)
        guard let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 8000, channels: 1, interleaved: true),
              let converter = AVAudioConverter(from: recordingFormat, to: outputFormat) else {
            notifyEngineError()
            return
        }
        
        input.installTap(onBus: 0, bufferSize: 8192, format: recordingFormat) { [weak self] (buffer, _) in
            var newBufferAvailable = true
            let inputCallback: AVAudioConverterInputBlock = { _, outStatus in
                if newBufferAvailable {
                    outStatus.pointee = .haveData
                    newBufferAvailable = false
                    return buffer
                } else {
                    outStatus.pointee = .noDataNow
                    return nil
                }
            }
            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(outputFormat.sampleRate) * buffer.frameLength / AVAudioFrameCount(buffer.format.sampleRate))!
            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
            
            if status == .error {
                self?.notifyEngineError(error)
                return
            }
            self?.request?.append(convertedBuffer)
        }
        
        engine.prepare()
        do {
            try engine.start()
        } catch {
            notifyEngineError(error)
        }
    }
    
    private func notifyEngineError(_ error: Error? = nil) {
        safeDelegateCall {
            self.delegate?.didFailToCommenceSpeechRecording()
            self.delegate?.didFailToProcessRequest(withError: error ?? OSSSpeechKitErrorType.invalidAudioEngine.error)
        }
    }

    private func recordAndRecognizeSpeech() {
        if let recognizer = speechRecognizer, !recognizer.isAvailable {
            cancelRecording()
            setSession(isRecording: false)
        }
        if speechSynthesizer.isSpeaking { stopSpeaking() }
        
        guard setSession(isRecording: true) else { return }
        
        request = SFSpeechAudioBufferRecognitionRequest()
        engineSetup()
        
        let identifier = voice?.voiceType.rawValue ?? OSSVoiceEnum.UnitedStatesEnglish.rawValue
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier))
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            let errorType: OSSSpeechKitErrorType = speechRecognizer == nil ? .invalidSpeechRequest : .recogniserUnavailble
            safeDelegateCall {
                self.delegate?.didFailToCommenceSpeechRecording()
                self.delegate?.didFailToProcessRequest(withError: errorType.error)
            }
            return
        }
        
        if let audioRequest = request {
            if recognizer.supportsOnDeviceRecognition {
                audioRequest.requiresOnDeviceRecognition = shouldUseOnDeviceRecognition
            }
            recognizer.defaultTaskHint = recognitionTaskType.taskType
            recognitionTask = recognizer.recognitionTask(with: audioRequest, delegate: self)
        }
        
        if saveRecord { readyToRecord() }
    }
    
    private func readyToRecord() {
        let dateString = dateFormatter.string(from: Date())
        let url = getDocumentsDirectory().appendingPathComponent("\(dateString)-osKit.m4a")
        audioFileURL = url // 安全赋值

        let audioSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: audioSettings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            soundSamples.removeAll()
            visualizerTimer()
        } catch {
            safeDelegateCall { self.delegate?.didFailToProcessRequest(withError: OSSSpeechKitErrorType.invalidRecordVoice.error) }
        }
    }

    private func visualizerTimer() {
        let interval: Double = 0.01
        audioRecorder?.record(forDuration: interval)
        
        // 【优化】确保 Timer 添加到主线程的 RunLoop 中，防止在后台线程调度失败
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.levelTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.audioRecorder?.updateMeters()
                let decibels = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
                let normalizedValue = pow(10, decibels / 20)
                self.soundSamples.append(normalizedValue)
                self.safeDelegateCall { self.onUpdate?(self.soundSamples) }
                self.audioRecorder?.record(forDuration: interval)
            }
            RunLoop.main.add(self.levelTimer!, forMode: .common)
        }
    }
    
    private func stopVisualizerTimer() {
        safeDelegateCall { self.onUpdate?(self.soundSamples) }
        soundSamples.removeAll()
        levelTimer?.invalidate()
        levelTimer = nil
    }
        
    public func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
        
    /// Delete one voice file(s)
    public func deleteVoiceFolderItem(url: URL?) {
        let fileManager = FileManager.default
        let folderURL = getDocumentsDirectory()
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for fileURL in contents {
                // 【修复】重写了文件遍历删除逻辑，避免原代码因为提前 return 导致的逻辑断裂
                if let targetURL = url {
                    if fileURL.absoluteString == targetURL.absoluteString {
                        try fileManager.removeItem(at: fileURL)
                        safeDelegateCall { self.delegate?.deleteVoiceFile(withFinish: true, withError: nil) }
                        return // 找到指定文件并删除后，退出即可
                    }
                } else {
                    // url 为 nil，删除所有后缀为 "-osKit.m4a" 的文件
                    if fileURL.lastPathComponent.contains("-osKit.m4a") {
                        try fileManager.removeItem(at: fileURL)
                    }
                }
            }
            
            // 如果 url 为 nil（批量删除模式），循环结束后统一回调成功
            if url == nil {
                safeDelegateCall { self.delegate?.deleteVoiceFile(withFinish: true, withError: nil) }
            }
        } catch {
            safeDelegateCall { self.delegate?.deleteVoiceFile(withFinish: false, withError: OSSSpeechKitErrorType.invalidDeleteVoiceFilePath.error) }
        }
    }
    
    /// Transcription voice file path
    public func recognizeSpeech(filePath: URL, finalBlock: ((_ text: String) -> Void)? = nil) {
        // 【补充】功能完善：必须先校验文件是否存在，否则会由于文件找不到而静默失败
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            safeDelegateCall { self.delegate?.didFailToProcessRequest(withError: OSSSpeechKitErrorType.invalidVoiceFilePath.error) }
            return
        }

        let identifier = voice?.voiceType.rawValue ?? OSSVoiceEnum.UnitedStatesEnglish.rawValue
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier))
        
        guard let audioFile = try? AVAudioFile(forReading: filePath) else {
            safeDelegateCall { self.delegate?.didFailToProcessRequest(withError: OSSSpeechKitErrorType.invalidVoiceFilePath.error) }
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: audioFile.url)
        speechRecognizer?.recognitionTask(with: request) { [weak self] (result, error) in
            guard let self = self else { return }
            if let result = result, result.isFinal {
                let transcription = result.bestTranscription.formattedString
                self.safeDelegateCall {
                    if let block = finalBlock {
                        block(transcription)
                    } else {
                        self.delegate?.voiceFilePathTranscription(withText: transcription)
                    }
                }
            } else if error != nil {
                self.safeDelegateCall { self.delegate?.didFailToProcessRequest(withError: OSSSpeechKitErrorType.invalidTranscriptionFilePath.error) }
            }
        }
    }
}

// MARK: - Extension SFSpeechRecognitionTaskDelegate & SFSpeechRecognizerDelegate
extension OSSSpeech: SFSpeechRecognitionTaskDelegate, SFSpeechRecognizerDelegate {
    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        recognitionTask = nil
        safeDelegateCall {
            self.delegate?.didFinishListening(withText: self.spokenText)
            // 安全解包 audioFileURL
            if self.saveRecord, let fileURL = self.audioFileURL {
                self.delegate?.didFinishListening(withAudioFileURL: fileURL, withText: self.spokenText)
            }
        }
        setSession(isRecording: false)
    }

    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        safeDelegateCall { self.delegate?.didCompleteTranslation(withText: transcription.formattedString) }
    }

    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        spokenText = recognitionResult.bestTranscription.formattedString
    }

    public func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {}
    public func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {}
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {}
}

// MARK: - AVAudioRecorderDelegate
extension OSSSpeech: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            audioRecorder?.stop()
            stopVisualizerTimer()
        }
    }
}
#endif
