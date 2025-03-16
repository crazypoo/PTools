//
//  PTSpeech.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/12.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Speech
import AVFoundation

public typealias ErrorBlock = (_ error:NSError) -> Void
public typealias FinishBlock = (_ text:String) -> Void

@objc public enum PTSpeechErrorType:Int {
    case UnsupportedLocale
    case RecognitionDenied
    case IsBusy
}

@objcMembers
public class PTSpeech: NSObject {
    public static let share = PTSpeech()
    
    open var errorBlock:ErrorBlock?
    open var finishBlock:FinishBlock?
    
    lazy var recognizer:SFSpeechRecognizer? = {
        let re = SFSpeechRecognizer(locale: Locale.current)
        return re
    }()
    
    lazy var request:SFSpeechAudioBufferRecognitionRequest = {
        let re = SFSpeechAudioBufferRecognitionRequest()
        return re
    }()
    
    lazy var audioEndine:AVAudioEngine = {
        let re = AVAudioEngine()
        return re
    }()
    
    var currentTask:SFSpeechRecognitionTask!
    var buffer:String = ""
    
    public override init() {
        super.init()
        requestAuthorization()
        setup()
    }
    
    func errorFunction(code:Int,desc:String)->NSError {
        NSError(domain: NSStringFromClass(type(of: self)), code: code, userInfo: [NSLocalizedDescriptionKey: desc])
    }
    
    func createError(errorType:PTSpeechErrorType)->NSError {
        switch errorType {
        case .UnsupportedLocale:
            return errorFunction(code: -999, desc: "PT Speech not support".localized())
        case .RecognitionDenied:
            return errorFunction(code: 100, desc: "PT Speech denied".localized())
        case .IsBusy:
            return errorFunction(code: 500, desc: "PT Speech speeching".localized())
        }
    }
    
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .notDetermined:
                self.requestAuthorization()
            case .denied:
                self.errorBlock?(self.createError(errorType: .RecognitionDenied))
            default:
                break
            }
        }
    }
    
    func setup() {
        if recognizer != nil {
            recognizer?.defaultTaskHint = SFSpeechRecognitionTaskHint.dictation
            request.interactionIdentifier = "com.Jax.interactionIdentifier"
            let node = audioEndine.inputNode
            let recordingFormat = node.outputFormat(forBus: 0)
            node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
                self.request.append(buffer)
            }
        } else {
            errorBlock?(createError(errorType: .UnsupportedLocale))
        }
    }
    
    func isTaskInProgress()->Bool {
        currentTask.state == .running
    }
    
    func performRecognition() {
        audioEndine.prepare()
        
        do {
            try audioEndine.start()
            currentTask = recognizer?.recognitionTask(with: request, delegate: self)
        } catch {
            errorBlock?(error as NSError)
        }
    }
    
    public func startRecognize(handleBlock:((_ success:Bool)->Void)?) {
        let isRunning = isTaskInProgress()
        if isRunning {
            errorBlock?(createError(errorType: .IsBusy))
        } else {
            performRecognition()
        }
        
        handleBlock?(isRunning)
    }
    
    public func stopRecognize() {
        if isTaskInProgress() {
            currentTask.finish()
            audioEndine.stop()
        }
    }
}

extension PTSpeech:SFSpeechRecognitionTaskDelegate {
    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        buffer = recognitionResult.bestTranscription.formattedString
    }
    
    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        if !successfully {
            errorBlock?(task.error! as NSError)
        } else {
            finishBlock?(buffer)
        }
    }
}
