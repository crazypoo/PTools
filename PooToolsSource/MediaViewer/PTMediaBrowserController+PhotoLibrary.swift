//
//  PTMediaBrowserController+PhotoLibrary.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

extension PTMediaBrowserController {
    @objc func save(videoPath: String, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        viewSaveImageBlock?(error == nil)
    }
}
