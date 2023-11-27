//
//  PTSpeechViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

class PTSpeechViewController: PTBaseViewController {

    let speechKit = OSSSpeech.shared
    var isRecording:Bool = false
    var translateToText:Bool = false
    lazy var soundVisualizerMaskView:PTVoiceActionView = {
        let view = PTVoiceActionView()
        view.backgroundColor = .black.withAlphaComponent(0.65)
        return view
    }()
    lazy var soundRecorder = PTSoundRecorder()

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        soundVisualizerMaskView.removeFromSuperview()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        AppDelegate.appDelegate()?.window?.addSubview(soundVisualizerMaskView)
        soundVisualizerMaskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        soundVisualizerMaskView.alpha = 0
        
        speechKit.voice = OSSVoice(quality: .enhanced, language: .ChineseHongKong)
        speechKit.utterance?.rate = 0.45
        speechKit.onUpdate = { soundSamples in
            self.soundVisualizerMaskView.visualizerView.updateSamples(soundSamples)
        }
        speechKit.delegate = self
        speechKit.srp.requestAuthorization { authStatus in
            let status = OSSSpeechKitAuthorizationStatus(rawValue: authStatus.rawValue) ?? .notDetermined
            PTNSLogConsole(status)
        }
        
        let voiceButton = UIButton(type: .custom)
        voiceButton.backgroundColor = .random
        view.addSubview(voiceButton)
        voiceButton.snp.makeConstraints { make in
            make.size.equalTo(100)
            make.centerX.centerY.equalToSuperview()
        }
        voiceButton.addTarget(self, action: #selector(recordButtonPressed), for: .touchDown)
        voiceButton.addTarget(self, action: #selector(recordButtonReleased), for: .touchUpInside)
        voiceButton.addTarget(self, action: #selector(recordButtonReleased), for: .touchUpOutside)

        let longPressRecognizer = UILongPressGestureRecognizer { senders in
            if self.avCaptureDeviceAuthorize(avMediaType: .audio) {
                let sender = senders as! UILongPressGestureRecognizer
                voiceButton.setTitle("松开发送", for: .normal)
                if self.isRecording {
                    self.speechKit.recordVoice()
                    self.isRecording = false
                }
                self.soundVisualizerMaskView.actionInfoLabel.isHidden = true
                self.soundVisualizerMaskView.actionInfoLabel.text = ""
                switch sender.state {
                case .began:
                    // 開始錄音，顯示錄音的動畫和文字
                    PTNSLogConsole("開始錄音，顯示錄音的動畫和文字")
                    
                    self.soundVisualizerMaskView.alpha = 1
                    
                case .changed:
                    let touchPoint = sender.location(in: voiceButton)
                    if touchPoint.y < -(CGFloat.kTabbarHeight_Total + 34) {
                        PTNSLogConsole("超過閾值，顯示「向上取消」的提示")
                        let screenCenterX = (CGFloat.kSCREEN_WIDTH / 2)
                        let centerX = (screenCenterX - 44)
                        if touchPoint.x < centerX {
                            let newX = (touchPoint.x - centerX)
                            PTNSLogConsole(newX)
                            if abs(newX) >= (screenCenterX / 2) {
                                self.soundVisualizerMaskView.visualizerView.backgroundColor = .red
                                self.soundVisualizerMaskView.visualizerView.snp.updateConstraints { make in
                                    make.width.equalTo(150)
                                    make.centerX.equalToSuperview().offset(-(screenCenterX / 2))
                                }
                                voiceButton.setTitle("PT Button cancel".localized(), for: .normal)
                                self.soundVisualizerMaskView.actionInfoLabel.isHidden = false
                                self.soundVisualizerMaskView.actionInfoLabel.text = "取消发送"
                            } else if abs(newX) <= 44 {
                                self.soundVisualizerMaskView.visualizerView.backgroundColor = self.soundVisualizerMaskView.visualizerViewBaseBackgroundColor
                                self.soundVisualizerMaskView.visualizerView.snp.updateConstraints { make in
                                    make.centerX.equalToSuperview().offset(0)
                                    make.width.equalTo(150)
                                }
                                voiceButton.setTitle("发送", for: .normal)
                                self.soundVisualizerMaskView.actionInfoLabel.isHidden = true
                                self.soundVisualizerMaskView.actionInfoLabel.text = ""
                            } else {
                                self.soundVisualizerMaskView.visualizerView.backgroundColor = .red
                                self.soundVisualizerMaskView.visualizerView.snp.updateConstraints { make in
                                    make.centerX.equalToSuperview().offset(newX)
                                    make.width.equalTo(150)
                                }
                                voiceButton.setTitle("PT Button cancel".localized(), for: .normal)
                                self.soundVisualizerMaskView.actionInfoLabel.isHidden = false
                                self.soundVisualizerMaskView.actionInfoLabel.text = "取消发送"
                            }
                            PTNSLogConsole("在左边")
                            self.translateToText = false
                        } else if touchPoint.x > (screenCenterX + 44) {
                            self.translateToText = true
//                            self.sendTranslateText = true
                            PTNSLogConsole("在右边")
                            self.soundVisualizerMaskView.visualizerView.snp.updateConstraints { make in
                                make.width.equalTo(CGFloat.kSCREEN_WIDTH - 40)
                            }
                            self.soundVisualizerMaskView.actionInfoLabel.isHidden = false
                            self.soundVisualizerMaskView.actionInfoLabel.text = "转换文字"
                        } else {
                            self.translateToText = false
                            PTNSLogConsole("在中间")
                            self.soundVisualizerMaskView.visualizerView.snp.updateConstraints { make in
                                make.centerX.equalToSuperview().offset(0)
                                make.width.equalTo(150)
                            }
                            voiceButton.setTitle("发送", for: .normal)
                            self.soundVisualizerMaskView.actionInfoLabel.isHidden = true
                            self.soundVisualizerMaskView.actionInfoLabel.text = ""
                        }
                        // 超過閾值，顯示「向上取消」的提示
                    } else {
                        // 未超過閾值，顯示「鬆開發送」的提示
                        self.translateToText = false
                        PTNSLogConsole("未超過閾值，顯示「鬆開發送」的提示")
                        self.soundVisualizerMaskView.visualizerView.snp.updateConstraints { make in
                            make.centerX.equalToSuperview().offset(0)
                        }
                        voiceButton.setTitle("发送", for: .normal)
                    }
                case .ended:
                    voiceButton.setTitle("长按录制语音", for: .normal)
                    let touchPoint = sender.location(in: voiceButton)
                    if touchPoint.y < -(CGFloat.kTabbarHeight_Total + 34) {
                        let screenCenterX = (CGFloat.kSCREEN_WIDTH / 2)
                        let centerX = (screenCenterX - 44)
                        if touchPoint.x < centerX {
                            let newX = (touchPoint.x - centerX)
                            PTNSLogConsole(newX)
                            if abs(newX) >= (screenCenterX / 2) {
//                                self.isSendVoice = false
                            } else if abs(newX) <= 44 {
//                                self.isSendVoice = true
                            } else {
//                                self.isSendVoice = false
                            }
                            PTNSLogConsole("在左边")
                        } else if touchPoint.x > (screenCenterX + 44) {
//                            self.isSendVoice = true
                        } else {
//                            self.isSendVoice = true
                        }
                    } else {
//                        self.isSendVoice = true
                    }
                    self.isRecording = false
                    PTGCDManager.gcdMain {
                        self.speechKit.endVoiceRecording()
                        self.translateToText = false
                            self.soundRecorder.stop()
                        self.soundVisualizerMaskView.visualizerView.stop()
                        self.soundVisualizerMaskView.alpha = 0
                        self.soundVisualizerMaskView.visualizerView.backgroundColor = self.soundVisualizerMaskView.visualizerViewBaseBackgroundColor
                        self.soundVisualizerMaskView.visualizerView.snp.updateConstraints { make in
                            make.centerX.equalToSuperview().offset(0)
                            make.width.equalTo(150)
                        }
                    }
                default:
                    break
                }
            }
        }
        longPressRecognizer.minimumPressDuration = 0.3
        voiceButton.addGestureRecognizer(longPressRecognizer)
        voiceButton.viewCorner(radius: 5, borderWidth: 1, borderColor: .black)
        voiceButton.setTitle("长按录制语音", for: .normal)
        voiceButton.setTitleColor(.black, for: .normal)

    }
}

//MARK: OSSSpeechDelegate
extension PTSpeechViewController:OSSSpeechDelegate {
    //MARK: 语音发送操作
    func recordButtonPressed() {
        if avCaptureDeviceAuthorize(avMediaType: .audio) {
            soundVisualizerMaskView.visualizerView.start()
            soundRecorder.start()

            // 開始錄音
            isRecording = true
            PTNSLogConsole("開始錄音")
        }
    }
    
    func recordButtonReleased() {
        if avCaptureDeviceAuthorize(avMediaType: .audio) {
            // 停止錄音
            isRecording = false
            PTNSLogConsole("停止錄音")
            speechKit.endVoiceRecording()
            soundRecorder.stop()
            soundVisualizerMaskView.visualizerView.stop()
            soundVisualizerMaskView.alpha = 0
        }
    }

    func voiceFilePathTranscription(withText text: String) {
        
    }
    
    func deleteVoiceFile(withFinish finish: Bool, withError error: Error?) {
        print("\(finish)  error:\(String(describing: error?.localizedDescription))")
    }
    
    func didFinishListening(withText text: String) {
        PTNSLogConsole("didFinishListening>>>>>>>>>>>>>\(text)")
    }
    
    func authorizationToMicrophone(withAuthentication type: OSSSpeechKitAuthorizationStatus) {
        
    }
    
    func didFailToCommenceSpeechRecording() {
        
    }
    
    func didCompleteTranslation(withText text: String) {
        PTNSLogConsole("Listening>>>>>>>>>>>>>\(text)")
        if translateToText {
            soundVisualizerMaskView.translateLabel.text = text
            soundVisualizerMaskView.translateLabel.isHidden = false
            var textHeight = soundVisualizerMaskView.translateLabel.sizeFor(width: CGFloat.kSCREEN_WIDTH - 40).height + 10
            
            let centerY = CGFloat.kSCREEN_HEIGHT / 2
            let textMaxHeight = (centerY - CGFloat.statusBarHeight() - 44 - 5)
            if textHeight >= textMaxHeight {
                textHeight = textMaxHeight
            }
            
            soundVisualizerMaskView.translateLabel.snp.updateConstraints { make in
                make.height.equalTo(textHeight)
            }
        } else {
            soundVisualizerMaskView.translateLabel.isHidden = true
            soundVisualizerMaskView.translateLabel.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }
    }
    
    func didFailToProcessRequest(withError error: Error?) {
        
    }
    
    func didFinishListening(withAudioFileURL url: URL, withText text: String) {
        PTNSLogConsole("url:\(url) \ntext:\(text)")
//        let date = Date()
//        let voiceURL = URL(fileURLWithPath: url.absoluteString.replacingOccurrences(of: "file://", with: ""))
//        var voiceMessage = PTMessageModel(audioURL: voiceURL, user: PTChatData.share.user, messageId: UUID().uuidString, date: date,sendSuccess: false)
//        voiceMessage.sending = true
//        let saveModel = PTChatModel()
//        if self.sendTranslateText {
//            saveModel.messageType = 0
//        } else {
//            saveModel.messageType = 1
//            saveModel.messageMediaURL = voiceURL.lastPathComponent
//        }
//        saveModel.messageText = text
//        saveModel.messageDateString = date.dateFormat(formatString: "yyyy-MM-dd HH:mm:ss")
//        saveModel.outgoing = true
//        if self.isSendVoice {
//            self.isSendVoice = false
//            if self.sendTranslateText {
//                self.insertMessages([text])
//                self.maskView.translateLabel.text = ""
//            } else {
//                self.insertMessage(voiceMessage) {
//                    self.sendTextFunction(str: text, saveModel: saveModel, sectionIndex: self.messageList.count - 1,flagType: .PASS)
//                }
//            }
//            self.messagesCollectionView.scrollToLastItem(animated: true)
//            self.sendTranslateText = false
//        } else {
//            self.speechKit.deleteVoiceFolderItem(url: URL(fileURLWithPath: url.absoluteString.replacingOccurrences(of: "file://", with: "")))
//        }
    }
}
