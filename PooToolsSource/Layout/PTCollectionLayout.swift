//
//  PTCollectionLayout.swift
//  Diou
//
//  Created by ken lam on 2021/10/11.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

@objcMembers
public class PTCollectionLayout: NSObject {
    
    @MainActor class public func createLayout(itemSize:CGSize,
                                   paddingY:CGFloat,
                                   paddingX:CGFloat,
                                   sd:UICollectionView.ScrollDirection)->UICollectionViewFlowLayout {
        let inset = UIEdgeInsets(top: paddingY, left: paddingX, bottom: paddingY, right: paddingX)
        return PTCollectionLayout.createLayoutBase(itemSize: itemSize, inset: inset, minimumLineSpaceing: paddingY, minimumInteritemSpacing: 0, sd: sd)
    }
    
    @MainActor class public func createLayoutBase(itemSize:CGSize,
                                       inset:UIEdgeInsets,
                                       minimumLineSpaceing:CGFloat,
                                       minimumInteritemSpacing:CGFloat,
                                       sd:UICollectionView.ScrollDirection)->UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = itemSize
        layout.scrollDirection = sd
        layout.sectionInset = inset
        layout.minimumLineSpacing = minimumLineSpaceing
        layout.minimumInteritemSpacing = minimumInteritemSpacing
        return layout
    }
    
    @MainActor class public func createLayoutNormal(sd:UICollectionView.ScrollDirection)->UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = sd
        return layout
    }
}
