//
//  StderrCapture.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

enum StderrCapture {
    @MainActor static var isCapturing = false
    @MainActor private static var inputPipe: Pipe?
    @MainActor private static var outputPipe: Pipe?
    @MainActor private static var originalDescriptor: Int32?

    @MainActor static func startCapturing() {
        guard !isCapturing else { return }

        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let descriptor = dup(STDERR_FILENO)
        guard descriptor >= 0 else { return }
        self.inputPipe = inputPipe
        self.outputPipe = outputPipe
        originalDescriptor = descriptor

        inputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            guard !data.isEmpty else { return }

            // Write input back to stderr
            outputPipe.fileHandleForWriting.write(data)
        }
        setvbuf(stderr, nil, _IONBF, 0)

        // Copy STDERR file descriptor to outputPipe for writing strings back to STDERR
        dup2(descriptor, outputPipe.fileHandleForWriting.fileDescriptor)

        // Intercept STDERR with inputPipe
        dup2(inputPipe.fileHandleForWriting.fileDescriptor, FileHandle.standardError.fileDescriptor)

        isCapturing = true
    }

    @MainActor static func syncData() {
        // 可读性回调已经负责消费数据，这里不再主动读取，避免启动时丢日志。
    }

    @MainActor static func stopCapturing() {
        guard isCapturing else { return }

        isCapturing = false
        inputPipe?.fileHandleForReading.readabilityHandler = nil
        if let originalDescriptor {
            dup2(originalDescriptor, STDERR_FILENO)
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
}
