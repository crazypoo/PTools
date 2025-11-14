//
//  File.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import Foundation
import UIKit

public protocol SnapshotKitProtocol {

    /// Synchronously take a snapshot of the view's visible content
    ///
    /// - Returns: UIImage?
    func takeSnapshotOfVisibleContent() -> UIImage?


    /// Synchronously take a snapshot of the view's full content
    ///
    /// - Important: when the size of the view's full content is small, use this method to take snapshot
    /// - Returns: UIImage?
    func takeSnapshotOfFullContent() -> UIImage?

    /// Asynchronously take a snapshot of the view's full content
    ///
    /// - Important: when the size of the view's full content is large, use this method to take snapshot
    /// - Parameter completion: image?
    func asyncTakeSnapshotOfFullContent(_ completion: @escaping ((_ image: UIImage?) -> Void))
}
