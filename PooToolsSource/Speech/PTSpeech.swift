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

public enum PTSpeechErrorType:Int
{
    case UnsupportedLocale
    case RecognitionDenied
    case IsBusy
}

public class PTSpeech: NSObject {
    public static let share = PTSpeech()
    
    public var errorBlock:ErrorBlock?
    public var finishBlock:FinishBlock?
    
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
        self.requestAuthorization()
        self.setup()
    }
    
    func errorFunction(code:Int,desc:String)->NSError
    {
        return NSError(domain: NSStringFromClass(type(of: self)), code: code,userInfo: [NSLocalizedDescriptionKey:desc])
    }
    
    func createError(errorType:PTSpeechErrorType)->NSError
    {
        switch errorType {
        case .UnsupportedLocale:
            return self.errorFunction(code: -999, desc: "不支持当前语言环境")
        case .RecognitionDenied:
            return self.errorFunction(code: 100, desc: "识别不出用户语音")
        case .IsBusy:
            return self.errorFunction(code: 500, desc: "识别中")
        }
    }
    
    func requestAuthorization()
    {
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .notDetermined:
                self.requestAuthorization()
            case .denied:
                if self.errorBlock != nil
                {
                    self.errorBlock!(self.createError(errorType: .RecognitionDenied))
                }
            default:
                break
            }
        }
    }
    
    func setup()
    {
        if self.recognizer != nil
        {
            self.recognizer?.defaultTaskHint = SFSpeechRecognitionTaskHint.dictation
            self.request.interactionIdentifier = "com.Jax.interactionIdentifier"
            let node = self.audioEndine.inputNode
            let recordingFormat = node.outputFormat(forBus: 0)
            node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
                self.request.append(buffer)
            }
        }
        else
        {
            if self.errorBlock != nil
            {
                self.errorBlock!(self.createError(errorType: .UnsupportedLocale))
            }
        }
    }
    
    func isTaskInProgress()->Bool
    {
        return self.currentTask.state == .running
    }
    
    func performRecognition()
    {
        self.audioEndine.prepare()
        
        do {
            try self.audioEndine.start()
            self.currentTask = self.recognizer?.recognitionTask(with: self.request, delegate: self)
        } catch {
            if self.errorBlock != nil
            {
                self.errorBlock!(error as NSError)
            }
        }
    }
    
    public func startRecognize(handleBlock:((_ success:Bool)->Void)?)
    {
        let isRunning = self.isTaskInProgress()
        if isRunning
        {
            if self.errorBlock != nil
            {
                self.errorBlock!(self.createError(errorType: .IsBusy))
            }
        }
        else
        {
            self.performRecognition()
        }
        
        if handleBlock != nil
        {
            handleBlock!(isRunning)
        }
    }
    
    public func stopRecognize()
    {
        if self.isTaskInProgress()
        {
            self.currentTask.finish()
            self.audioEndine.stop()
        }
    }
}

extension PTSpeech:SFSpeechRecognitionTaskDelegate
{
    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        self.buffer = recognitionResult.bestTranscription.formattedString
    }
    
    public func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        if !successfully
        {
            if self.errorBlock != nil
            {
                self.errorBlock!(task.error! as NSError)
            }
        }
        else
        {
            if self.finishBlock != nil
            {
                self.finishBlock!(self.buffer)
            }
        }
    }
}
