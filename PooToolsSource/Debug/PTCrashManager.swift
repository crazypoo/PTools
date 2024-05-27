//
//  PTCrashManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

enum PTCrashManager {

    static func register() {
        PTCrashHandler.shared.prepare()
    }

    static func save(crash: PTCrashModel) {
        let filePath = getDocumentsDirectory().appendingPathComponent(crash.type.fileName)
        
        if !FileManager.pt.judgeFileOrFolderExists(filePath: filePath.absoluteString.replacingOccurrences(of: "file:///", with: "/")) {
            FileManager.pt.createFile(filePath: filePath.absoluteString.replacingOccurrences(of: "file:///", with: "/"))
        }
        // Try to load existing crashes from file
        var existingCrashes: [PTCrashModel] = []
        if let existingData = try? Data(contentsOf: URL(fileURLWithPath: filePath.absoluteString.replacingOccurrences(of: "file:///", with: "/"))) {
            existingCrashes = (try? JSONDecoder().decode([PTCrashModel].self, from: existingData)) ?? []
        }

        // Append the new crash
        existingCrashes.append(crash)

        // Save the updated crashes array
        do {
            let jsonData = try JSONEncoder().encode(existingCrashes)
            try jsonData.write(to: URL(fileURLWithPath: filePath.absoluteString.replacingOccurrences(of: "file:///", with: "/")))
        } catch {
            PTNSLogConsole("Error saving crash data: \(error)")
        }
    }    

    static func recover(ofType type: PTCrashType) -> [PTCrashModel] {
        let filePath = getDocumentsDirectory().appendingPathComponent(type.fileName)
        if !FileManager.pt.judgeFileOrFolderExists(filePath: filePath.absoluteString.replacingOccurrences(of: "file:///", with: "/")) {
            let createFile = FileManager.pt.createFile(filePath: filePath.absoluteString.replacingOccurrences(of: "file:///", with: "/")).isSuccess
            if !createFile {
                return []
            }
        }
        do {
            let existingData = try Data(contentsOf: URL(fileURLWithPath: filePath.absoluteString.replacingOccurrences(of: "file:///", with: "/")))
            return try JSONDecoder().decode([PTCrashModel].self, from: existingData)
        } catch {
            PTNSLogConsole("Error recovering crash data: \(error)")
            return []
        }
    }

    static func delete(crash: PTCrashModel) {
        let filePath = getDocumentsDirectory().appendingPathComponent(crash.type.fileName)

        // Try to load existing crashes from file
        var existingCrashes: [PTCrashModel] = []
        if let existingData = try? Data(contentsOf: filePath) {
            existingCrashes = (try? JSONDecoder().decode([PTCrashModel].self, from: existingData)) ?? []
        }

        // Find and remove the specified crash
        existingCrashes.removeAll { $0 == crash }

        // Save the updated crashes array
        do {
            let jsonData = try JSONEncoder().encode(existingCrashes)
            try jsonData.write(to: filePath)
        } catch {
            PTNSLogConsole("Error saving crash data: \(error)")
        }
    }

    static func deleteAll(ofType type: PTCrashType) {
        let filePath = getDocumentsDirectory().appendingPathComponent(type.fileName)

        do {
            // Remove the file to delete all crash reports
            try FileManager.default.removeItem(at: filePath)
        } catch {
            PTNSLogConsole("Error deleting all crash reports: \(error)")
        }
    }

    private static func getDocumentsDirectory() -> URL {
        FileManager.pt.getFileDirectory(type: .Documnets)
    }
}

enum PTCrashType: String, Codable {
    case nsexception
    case signal

    var fileName: String { "\(rawValue)_crashes.json" }
}
