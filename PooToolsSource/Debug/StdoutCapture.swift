//
//  StdoutCapture.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

struct PTReadCompletionNotificationBox: @unchecked Sendable {
    let value: Notification
}

@MainActor
final class StdoutCapture {

    private static let shared = StdoutCapture()

    // MARK: - Properties

    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var originalDescriptor: Int32?
    private var notificationToken: NSObjectProtocol?
    private var isCapturing = false
    private let queue = DispatchQueue(label: "com.pootools.log.interceptor.queue", qos: .default, attributes: .concurrent)

    let logUrl: URL? = {
        if let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
            let documentsDirectory = URL(fileURLWithPath: path)
            return documentsDirectory.appendingPathComponent("\(Bundle.main.bundleIdentifier ?? "app")-output.log")
        }
        return nil
    }()

    // MARK: - Lifecycle Methods

    static func startCapturing() {
        guard !shared.isCapturing else { return }
        if let logUrl = shared.logUrl {
            shared.rotateLogIfNeeded(at: logUrl)
        }
        if let logUrl = shared.logUrl, !FileManager.default.fileExists(atPath: logUrl.path) {
            do {
                let header =
                    """
                    Start logger
                    DeviceID: \(UIDevice.current.identifierForVendor?.uuidString ?? "none")
                    """
                try header.write(to: logUrl, atomically: true, encoding: .utf8)
            } catch {}
        }

        shared.openConsolePipe()
    }

    private func rotateLogIfNeeded(at url: URL) {
        let maximumSize: UInt64 = 5 * 1024 * 1024
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? NSNumber,
              fileSize.uint64Value >= maximumSize else { return }

        let rotatedURL = url.deletingPathExtension().appendingPathExtension("log.1")
        try? FileManager.default.removeItem(at: rotatedURL)
        try? FileManager.default.moveItem(at: url, to: rotatedURL)
    }

    static func stopCapturing() {
        shared.closeConsolePipe()
    }

    private func openConsolePipe() {
        guard !isCapturing else { return }
        setvbuf(stdout, nil, _IONBF, 0)

        let descriptor = dup(STDOUT_FILENO)
        guard descriptor >= 0 else { return }
        originalDescriptor = descriptor

        // open a new Pipe to consume the messages on STDOUT and STDERR
        inputPipe = Pipe()
        outputPipe = Pipe()

        guard let inputPipe, let outputPipe else {
            close(descriptor)
            return
        }

        let pipeReadHandle = inputPipe.fileHandleForReading

        /// from documentation
        /// dup2() makes newfd (new file descriptor) be the copy of oldfd
        /// (old file descriptor), closing newfd first if necessary.

        /// here we are copying the STDOUT file descriptor into our output
        /// pipe's file descriptor this is so we can write the strings back
        /// to STDOUT, so it can show up on the xcode console
        dup2(descriptor, outputPipe.fileHandleForWriting.fileDescriptor)

        /// In this case, the newFileDescriptor is the pipe's file descriptor
        /// and the old file descriptor is STDOUT_FILENO and STDERR_FILENO
        dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

        // listen in to the readHandle notification
        notificationToken = NotificationCenter.default.addObserver(forName: FileHandle.readCompletionNotification, object: pipeReadHandle, queue: .main) { [weak self] notification in
            let box = PTReadCompletionNotificationBox(value: notification)
            PTMainActorBridge.perform { [weak self] in
                self?.handlePipeNotification(notification: box.value)
            }
        }

        // state that you want to be notified of any data coming across the pipe
        pipeReadHandle.readInBackgroundAndNotify()
        isCapturing = true
    }

    private func closeConsolePipe() {
        guard isCapturing else { return }
        isCapturing = false
        if let notificationToken {
            NotificationCenter.default.removeObserver(notificationToken)
            self.notificationToken = nil
        }
        if let originalDescriptor {
            dup2(originalDescriptor, STDOUT_FILENO)
            close(originalDescriptor)
            self.originalDescriptor = nil
        }
        inputPipe?.fileHandleForReading.closeFile()
        inputPipe?.fileHandleForWriting.closeFile()
        outputPipe?.fileHandleForReading.closeFile()
        outputPipe?.fileHandleForWriting.closeFile()
        inputPipe = nil
        outputPipe = nil
    }

    @objc
    func handlePipeNotification(notification: Notification) {
        guard isCapturing else { return }
        inputPipe?.fileHandleForReading.readInBackgroundAndNotify()

        if let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data,
           let str = String(data: data, encoding: String.Encoding.utf8),
           let logUrl {
            /// write the data back into the output pipe. the output pipe's write
            /// file descriptor points to STDOUT. this allows the logs to show up
            /// on the xcode console
            outputPipe?.fileHandleForWriting.write(data)

            queue.async(flags: .barrier) {
                do {
                    try str.appendLineToURL(logUrl)
                } catch {}
            }
        }
    }
}

extension String {
    fileprivate func appendLineToURL(_ fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL)
    }

    fileprivate func appendToURL(_ fileURL: URL) throws {
        if let data = data(using: .utf8) {
            try data.appendToURL(fileURL)
        }
    }
}

extension Data {
    fileprivate func appendToURL(_ fileURL: URL) throws {
        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: fileURL, options: .atomic)
        }
    }
}
