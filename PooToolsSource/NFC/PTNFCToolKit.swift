//
//  PTNFCToolKit.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/27/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import Foundation
@preconcurrency import CoreNFC

private struct PTNFCSessionAndTagSendableBox: @unchecked Sendable {
    let session: NFCTagReaderSession
    let tag:NFCTag
}

private struct PTNFCSessionSendableBox: @unchecked Sendable {
    let session: NFCTagReaderSession
}

private struct PTNFCSessionAndNDEFSendableBox: @unchecked Sendable {
    let session: NFCTagReaderSession
    let tag:NFCNDEFTag
}

@MainActor
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
    // 注意：如果你的 PTActionTask 不是 @Sendable，Swift 6 可能会提醒。建议定义为 typealias PTActionTask = @Sendable () -> Void
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

// MARK: - Delegate (使用 nonisolated 避免主线程死锁和并发警告)
@available(iOS 13.0, *)
extension PTNFCToolKit: NFCTagReaderSessionDelegate {
    
    nonisolated public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // Session 激活时的回调，保持为空即可
    }
    
    nonisolated public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            self.onError?(error)
            self.clear()
        }
    }

    nonisolated public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else { return }

        let safeBox = PTNFCSessionAndTagSendableBox(session: session,tag:tag)
        
        safeBox.session.connect(to: tag) { error in
            if let error = error {
                // 在后台线程直接操作 session，不跨界
                safeBox.session.invalidate(errorMessage: "連線失敗: \(error.localizedDescription)")
                Task { @MainActor in
                    self.onError?(error)
                    self.clear()
                }
                return
            }
            
            // 连线成功后，切回主线程进行状态处理
            Task { @MainActor in
                self.processDetectedTag(safeBox.tag, session: safeBox.session)
            }
        }
    }
}

// MARK: - Core Logic
@available(iOS 13.0, *)
extension PTNFCToolKit {
    
    @MainActor
    private func processDetectedTag(_ tag: NFCTag, session: NFCTagReaderSession) {
        switch tag {
        case .miFare(let mifareTag):
            let uidString = mifareTag.identifier.map { String(format: "%02x", $0) }.joined()
            // 确保你的 PTNSLogConsole 支持跨并发域，或者它本身就是全局安全的
            print("MiFare UID: \(uidString)")
            session.invalidate(errorMessage: miFareErrorMsg)
            self.clear()

        case .iso7816(let iso7816Tag):
            let safeBox = PTNFCSessionSendableBox(session: session)
            if let command = self.apduCommand {
                // 将可能变化的主线程状态设为本地常量，以便在后台闭包中使用
                let localApduErrorMsg = self.apduErrorMsg
                let localApduSuccessMsg = self.apduSuccessMsg
                
                iso7816Tag.sendCommand(apdu: command) { data, sw1, sw2, error in
                    if let error = error {
                        safeBox.session.invalidate(errorMessage: "\(localApduErrorMsg)：\(error.localizedDescription)")
                        Task { @MainActor in
                            self.onError?(error)
                            self.clear()
                        }
                    } else {
                        safeBox.session.alertMessage = String(format: localApduSuccessMsg, String(sw1), String(sw2))
                        safeBox.session.invalidate()
                        Task { @MainActor in
                            self.apduCompletion?(data)
                            self.clear()
                        }
                    }
                }
            } else {
                self.queryNDEF(tag: iso7816Tag, session: safeBox.session)
            }

        case .iso15693(let iso15693Tag):
            let uidString = iso15693Tag.identifier.map { String(format: "%02x", $0) }.joined()
            print("ISO15693 UID: \(uidString)")
            session.invalidate(errorMessage: nfc15693ErrorMsg)
            self.clear()

        case .feliCa(let felicaTag):
            let idmString = felicaTag.currentIDm.map { String(format: "%02x", $0) }.joined()
            print("FeliCa IDm: \(idmString)")
            session.invalidate(errorMessage: felicaErrorMsg)
            self.clear()
            
        @unknown default:
            session.invalidate(errorMessage: unknowErrorMsg)
            self.clear()
        }
    }

    @MainActor
    private func queryNDEF(tag: NFCISO7816Tag, session: NFCTagReaderSession) {
        let ndefTag = tag as NFCNDEFTag
        
        // 1. 移除 localWriteMessage 的提前捕获
        // 只保留那些确实是 Sendable 的基本类型（如 String）的捕获
        let localFindErrorMsg = self.findErrorMsg
        let localNotSupportMsg = self.notSupportNDEFMsg
        let localUnknowStateMsg = self.unknowStateMsg
        
        let safeBox = PTNFCSessionAndNDEFSendableBox(session: session, tag: ndefTag)
        
        // 2. 使用 [weak self] 弱引用传入闭包，避免循环引用，且 Actor 的弱引用是 Sendable 的
        safeBox.tag.queryNDEFStatus { [weak self] status, _, error in
            if let error = error {
                safeBox.session.invalidate(errorMessage: "\(localFindErrorMsg)\(error.localizedDescription)")
                Task { @MainActor in
                    self?.onError?(error)
                    self?.clear()
                }
                return
            }

            switch status {
            case .readOnly, .readWrite:
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    // 3. 核心修复：直接在已经受到 @MainActor 保护的作用域内，读取 self.writeMessage
                    // 因为此时已经在主线程，所以根本不存在跨越边界的问题，不会触发 Data Race
                    if let safeWriteMessage = self.writeMessage {
                        self.writeNDEF(to: safeBox.tag, message: safeWriteMessage, session: safeBox.session)
                    } else {
                        self.readNDEF(from: safeBox.tag, session: safeBox.session)
                    }
                }
            case .notSupported:
                safeBox.session.invalidate(errorMessage: localNotSupportMsg)
                Task { @MainActor in self?.clear() }
            @unknown default:
                safeBox.session.invalidate(errorMessage: localUnknowStateMsg)
                Task { @MainActor in self?.clear() }
            }
        }
    }

    @MainActor
    private func readNDEF(from tag: NFCNDEFTag, session: NFCTagReaderSession) {
        let localReadErrorMsg = self.readErrorMsg
        let localReadSuccessMsg = self.readSuccessMsg
        let localUnFindMsg = self.unFindMsg
        let safeBox = PTNFCSessionSendableBox(session: session)

        // 增加 [weak self] 防止循环引用
        tag.readNDEF { [weak self] message, error in
            if let error = error {
                safeBox.session.invalidate(errorMessage: "\(localReadErrorMsg)\(error.localizedDescription)")
                Task { @MainActor in
                    self?.onError?(error)
                    self?.clear()
                }
                return
            }

            if let records = message?.records {
                safeBox.session.alertMessage = localReadSuccessMsg
                safeBox.session.invalidate()
                
                // 【核心修复】使用 nonisolated(unsafe) 包装非 Sendable 的 records
                // 这明确告诉 Swift 6 编译器：我们将安全地把这个对象转移给主线程，后台不再触碰它
                nonisolated(unsafe) let safeRecords = records
                
                Task { @MainActor in
                    // 在主线程中使用包装好的 safeRecords
                    self?.onReadSuccess?(safeRecords)
                    self?.clear()
                }
            } else {
                safeBox.session.invalidate(errorMessage: localUnFindMsg)
                Task { @MainActor in self?.clear() }
            }
        }
    }

    @MainActor
    private func writeNDEF(to tag: NFCNDEFTag, message: NFCNDEFMessage, session: NFCTagReaderSession) {
        let localWritingErrorMsg = self.writingErrorMsg
        let localWritingSuccessMsg = self.writingSuccessMsg
        let localShouldLock = self.shouldLockAfterWrite // 捕获锁状态
        
        let safeBox = PTNFCSessionAndNDEFSendableBox(session: session, tag: tag)

        safeBox.tag.writeNDEF(message) { error in
            if let error = error {
                safeBox.session.invalidate(errorMessage: "\(localWritingErrorMsg)\(error.localizedDescription)")
                Task { @MainActor in
                    self.onError?(error)
                    self.clear()
                }
                return
            }

            if localShouldLock {
                Task { @MainActor in
                    self.lockTag(tag: safeBox.tag, session: safeBox.session)
                }
            } else {
                safeBox.session.alertMessage = localWritingSuccessMsg
                safeBox.session.invalidate()
                Task { @MainActor in
                    self.onWriteSuccess?()
                    self.clear()
                }
            }
        }
    }

    @MainActor
    private func lockTag(tag: NFCNDEFTag, session: NFCTagReaderSession) {
        let localLockErrorMsg = self.lockErrorMsg
        let localOnlyReadMsg = self.onlyReadMsg
        let safeBox = PTNFCSessionSendableBox(session: session)

        tag.writeLock { error in
            if let error = error {
                safeBox.session.invalidate(errorMessage: "\(localLockErrorMsg)\(error.localizedDescription)")
                Task { @MainActor in
                    self.onError?(error)
                    self.clear()
                }
            } else {
                safeBox.session.alertMessage = localOnlyReadMsg
                safeBox.session.invalidate()
                Task { @MainActor in
                    self.onWriteSuccess?()
                    self.clear()
                }
            }
        }
    }
}
