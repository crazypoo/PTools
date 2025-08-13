//
//  PTNFCToolKit.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/27/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import Foundation
import CoreNFC

@available(iOS 13.0, *)
public class PTNFCToolKit: NSObject {
    public static let shared = PTNFCToolKit()

    public var plzNearReadingMsg = "請將設備靠近 NFC 標籤"
    public var plzNearWritingMsg = "請將設備靠近欲寫入的 NFC 標籤"
    public var plzNear7816Msg = "請靠近支援 ISO7816 的卡片"
    public var miFareErrorMsg = "MiFare 標籤尚未支援寫入/讀取"
    public var connectErrorMsg = "連線失敗: "
    public var apduErrorMsg = "APDU 錯誤: "
    public var apduSuccessMsg = "APDU 回應成功 SW1=%@, SW2=%@"
    public var nfc15693ErrorMsg = "ISO15693 尚未支援"
    public var felicaErrorMsg = "FeliCa 尚未支援"
    public var unknowErrorMsg = "未知標籤"
    public var findErrorMsg = "查詢失敗: "
    public var notSupportNDEFMsg = "不支援 NDEF"
    public var unknowStateMsg = "未知的狀態"
    public var readErrorMsg = "讀取失敗: "
    public var readSuccessMsg = "讀取成功"
    public var unFindMsg = "未發現有效資料"
    public var writingErrorMsg = "寫入失敗: "
    public var writingSuccessMsg = "寫入成功"
    public var lockErrorMsg = "無法鎖定: "
    public var onlyReadMsg = "標籤已鎖定為唯讀"

    private var readerSession: NFCTagReaderSession?
    private var onReadSuccess: (([NFCNDEFPayload]) -> Void)?
    private var onWriteSuccess: PTActionTask?
    private var onError: ((Error) -> Void)?
    private var apduCommand: NFCISO7816APDU?
    private var apduCompletion: ((Data) -> Void)?
    private var writeMessage: NFCNDEFMessage?
    private var shouldLockAfterWrite: Bool = false

    // MARK: - Public API

    public func startReading(onSuccess: @escaping ([NFCNDEFPayload]) -> Void,
                      onError: @escaping (Error) -> Void) {
        guard NFCTagReaderSession.readingAvailable else {
            onError(NSError(domain: "PTNFCToolKit", code: 0, userInfo: [NSLocalizedDescriptionKey: "設備不支援 NFC"]))
            return
        }

        self.onReadSuccess = onSuccess
        self.onError = onError
        self.writeMessage = nil

        readerSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self, queue: nil)
        readerSession?.alertMessage = plzNearReadingMsg
        readerSession?.begin()
    }

    public func startWriting(message: NFCNDEFMessage,
                      lockAfterWrite: Bool = false,
                      onSuccess: @escaping PTActionTask,
                      onError: @escaping (Error) -> Void) {
        guard NFCTagReaderSession.readingAvailable else {
            onError(NSError(domain: "PTNFCToolKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "設備不支援 NFC"]))
            return
        }

        self.writeMessage = message
        self.shouldLockAfterWrite = lockAfterWrite
        self.onWriteSuccess = onSuccess
        self.onError = onError

        readerSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self, queue: nil)
        readerSession?.alertMessage = plzNearWritingMsg
        readerSession?.begin()
    }

    public func sendAPDU(command: NFCISO7816APDU,
                  onSuccess: @escaping (Data) -> Void,
                  onError: @escaping (Error) -> Void) {
        guard NFCTagReaderSession.readingAvailable else {
            onError(NSError(domain: "PTNFCToolKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "設備不支援 NFC"]))
            return
        }

        self.apduCommand = command
        self.apduCompletion = onSuccess
        self.onError = onError

        readerSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self, queue: nil)
        readerSession?.alertMessage = plzNear7816Msg
        readerSession?.begin()
    }

    private func clear() {
        readerSession = nil
        onReadSuccess = nil
        onWriteSuccess = nil
        onError = nil
        writeMessage = nil
        apduCommand = nil
        apduCompletion = nil
        shouldLockAfterWrite = false
    }
}

@available(iOS 13.0, *)
extension PTNFCToolKit: NFCTagReaderSessionDelegate {
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        onError?(error)
        clear()
    }

    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }

        session.connect(to: tag) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                session.invalidate(errorMessage: "\(self.connectErrorMsg) \(error.localizedDescription)")
                self.onError?(error)
                self.clear()
                return
            }

            switch tag {
            case .miFare(let tag):
                PTNSLogConsole("MiFare UID: \(tag.identifier.map { String(format: "%02x", $0) }.joined())")
                session.invalidate(errorMessage: miFareErrorMsg)
                self.clear()

            case .iso7816(let tag):
                if let command = self.apduCommand {
                    tag.sendCommand(apdu: command) { [weak self] data, sw1, sw2, error in
                        guard let self = self else { return }
                        if let error = error {
                            session.invalidate(errorMessage: "\(self.apduErrorMsg)：\(error.localizedDescription)")
                            self.onError?(error)
                        } else {
                            session.alertMessage = String(format: self.apduSuccessMsg, sw1, sw2)
                            session.invalidate()
                            self.apduCompletion?(data)
                        }
                        self.clear()
                    }
                } else {
                    self.queryNDEF(tag: tag, session: session)
                }

            case .iso15693(let tag):
                PTNSLogConsole("ISO15693 UID: \(tag.identifier.map { String(format: "%02x", $0) }.joined())")
                session.invalidate(errorMessage: nfc15693ErrorMsg)
                self.clear()

            case .feliCa(let tag):
                PTNSLogConsole("FeliCa IDm: \(tag.currentIDm.map { String(format: "%02x", $0) }.joined())")
                session.invalidate(errorMessage: felicaErrorMsg)
                self.clear()
            @unknown default:
                session.invalidate(errorMessage: unknowErrorMsg)
                self.clear()
            }
        }
    }

    private func queryNDEF(tag: NFCISO7816Tag, session: NFCTagReaderSession) {
        let ndefTag = tag as NFCNDEFTag
        ndefTag.queryNDEFStatus { [weak self] status, _, error in
            guard let self = self else { return }
            if let error = error {
                session.invalidate(errorMessage: "\(self.findErrorMsg)\(error.localizedDescription)")
                self.onError?(error)
                self.clear()
                return
            }

            switch status {
            case .readOnly, .readWrite:
                if let writeMessage = self.writeMessage {
                    self.writeNDEF(to: ndefTag, message: writeMessage, session: session)
                } else {
                    self.readNDEF(from: ndefTag, session: session)
                }
            case .notSupported:
                session.invalidate(errorMessage: notSupportNDEFMsg)
                self.clear()
            @unknown default:
                session.invalidate(errorMessage: unknowStateMsg)
                self.clear()
            }
        }
    }

    private func readNDEF(from tag: NFCNDEFTag, session: NFCTagReaderSession) {
        tag.readNDEF { [weak self] message, error in
            if let error = error {
                session.invalidate(errorMessage: "\(self!.readErrorMsg)\(error.localizedDescription)")
                self?.onError?(error)
                self?.clear()
                return
            }

            if let records = message?.records {
                session.alertMessage = self?.readSuccessMsg ?? ""
                session.invalidate()
                self?.onReadSuccess?(records)
            } else {
                session.invalidate(errorMessage: self?.unFindMsg ?? "")
            }
            self?.clear()
        }
    }

    private func writeNDEF(to tag: NFCNDEFTag, message: NFCNDEFMessage, session: NFCTagReaderSession) {
        tag.writeNDEF(message) { [weak self] error in
            if let error = error {
                session.invalidate(errorMessage: "\(self!.writingErrorMsg)\(error.localizedDescription)")
                self?.onError?(error)
                self?.clear()
                return
            }

            if self?.shouldLockAfterWrite == true {
                self?.lockTag(tag: tag, session: session)
            } else {
                Task{ @MainActor in
                    session.alertMessage = self?.writingSuccessMsg ?? ""
                    session.invalidate()
                    self?.onWriteSuccess?()
                    self?.clear()
                }
            }
        }
    }

    private func lockTag(tag: NFCNDEFTag, session: NFCTagReaderSession) {
        tag.writeLock { [weak self] error in
            if let error = error {
                session.invalidate(errorMessage: "\(self!.lockErrorMsg)\(error.localizedDescription)")
                self?.onError?(error)
            } else {
                Task{ @MainActor in
                    session.alertMessage = self?.onlyReadMsg ?? ""
                    session.invalidate()
                    self?.onWriteSuccess?()
                }
            }
            self?.clear()
        }
    }
}
