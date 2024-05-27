//
//  PTApplicationDirectories.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

final class PTApplicationDirectories {
    static let shared = PTApplicationDirectories()

    var support: URL {
        guard let supportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first
        else {
            fatalError("Unable to retrieve application support directory.")
        }
        return supportDirectory
    }
}
