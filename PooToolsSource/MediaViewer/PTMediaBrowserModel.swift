//
//  PTMediaBrowserModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 25/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

@MainActor
public final class PTMediaBrowserModel: NSObject {
    public var imageInfo: String = ""
    /// The viewer accepts URLs, local media objects and PhotoKit live photos.
    /// Keep the type-erased value optional so an incomplete data model renders
    /// an error state instead of trapping through an implicitly unwrapped value.
    public var imageURL: Any?
    public var modelEX: String = ""
    
    public override init() {
        super.init()
    }
}
