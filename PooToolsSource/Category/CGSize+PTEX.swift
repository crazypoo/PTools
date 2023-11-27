//
//  CGSize+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/3/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public extension CGSize {
    static func from(archivedData data: Data) throws -> CGSize {
        var sizeObj = CGSize.zero
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = false
        if let size = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? NSValue {
            sizeObj =  size.cgSizeValue
        }
        unarchiver.finishDecoding()
        return sizeObj
    }
    
    static func archiveData() throws -> Data {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
        return data ?? Data()
    }
    
    init(side: CGFloat) {
        self.init(width: side, height: side)
    }

    var aspectRatio: CGFloat {
        guard width != .zero, height != .zero else { return .zero }
        return width / height
    }
    
    var maxDimension: CGFloat { max(width, height) }
    var minDimension: CGFloat { min(width, height) }
    
    func resize(newWidth: CGFloat) -> CGSize {
        let scaleFactor = newWidth / width
        let newHeight = height * scaleFactor
        return CGSize(width: newWidth, height: newHeight)
    }
    
    func resize(newHeight: CGFloat) -> CGSize {
        let scaleFactor = newHeight / height
        let newWidth = width * scaleFactor
        return CGSize(width: newWidth, height: newHeight)
    }

}
