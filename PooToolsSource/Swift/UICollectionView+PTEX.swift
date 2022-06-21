//
//  UICollectionView+PTEX.swift
//  PooTools_Example
//
//  Created by Macmini on 2022/6/21.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public extension UICollectionView
{
    @objc func reloadDataWithOutAnimation(completion:(()->Void)?)
    {
        UIView.performWithoutAnimation {
            self.reloadData {
                if completion != nil
                {
                    completion!()
                }
            }
        }
    }
}
