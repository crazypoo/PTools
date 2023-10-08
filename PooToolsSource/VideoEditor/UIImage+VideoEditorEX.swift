//
//  UIImage+VideoEditorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

public extension UIImage {
    static func podBundleImage(_ imageName:String)->UIImage {
        let bundle = Bundle.main
        let image = UIImage(named: imageName, in: bundle, compatibleWith: nil)
        return image ?? UIImage()
    }
}
