//
//  ConsoleOutput.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

enum ConsoleOutput {
    static var printAndNSLogOutput = [String]()
    static var errorOutput = [String]()

    static func removeAll() {
        printAndNSLogOutput.removeAll()
    }

    static func printAndNSLogOutputFormatted() -> String {
        printAndNSLogOutput.clean()
    }

    static func errorOutputFormatted() -> String {
        errorOutput.clean()
    }
}

extension [String] {
    fileprivate func clean() -> String {
        filter { !$0.contains("[PooTools] 🚀") }.reversed().joined(separator: "\n\n")
    }
}
