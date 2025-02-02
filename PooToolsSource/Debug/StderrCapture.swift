//
//  StderrCapture.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

enum StderrCapture {
    static var isCapturing = false
    private static let inputPipe = Pipe()
    private static let outputPipe = Pipe()
    private static var originalDescriptor = FileHandle.standardError.fileDescriptor

    static func startCapturing() {
        guard !isCapturing else { return }

        inputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData

            // Write input back to stderr
            outputPipe.fileHandleForWriting.write(data)
        }
        setvbuf(stderr, nil, _IONBF, 0)

        // Copy STDERR file descriptor to outputPipe for writing strings back to STDERR
        dup2(FileHandle.standardError.fileDescriptor, outputPipe.fileHandleForWriting.fileDescriptor)

        // Intercept STDERR with inputPipe
        dup2(inputPipe.fileHandleForWriting.fileDescriptor, FileHandle.standardError.fileDescriptor)

        isCapturing = true
    }

    static func syncData() {
        guard isCapturing, inputPipe.fileHandleForReading.isReadable else {
            return
        }

        var synchronizeData: DispatchWorkItem!
        synchronizeData = DispatchWorkItem(block: {
            let _ = inputPipe.fileHandleForReading.availableData
        })
        
        synchronizeData.perform()
        _ = synchronizeData.wait(timeout: .now() + .milliseconds(10))
    }

    static func stopCapturing() {
        guard isCapturing else { return }

        isCapturing = false
        freopen("/dev/stderr", "a", stderr)
    }
}

