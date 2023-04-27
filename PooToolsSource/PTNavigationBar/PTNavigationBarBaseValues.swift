//
//  PTNavigationBarBaseValues.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 27/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import DeviceKit

public let PTNavDefalutItemSize:CGFloat = 22
public let PTNavDefalutItemMargin:CGFloat = 10
public let PTNavDefalutItemFontSize:CGFloat = 15
public let PTNavDefalutTitleSize:CGFloat = 17
public let PTNavDefalutSubTitleSize:CGFloat = 10

public let PTNavDefalutBackColor:UIColor = .white
public let PTNavDefalutItemTextColor:UIColor = .black
public let PTNavDefalutTitleColor:UIColor = .black
public let PTNavDefalutLineColor:UIColor = UIColor(red: 220 / 255.0, green: 220 / 255.0, blue: 220 / 255.0, alpha: 0.8)

public let PTHorizontaledSafeArea:CGFloat = ((PTRotationManager.share.orientation == .landscapeLeft || PTRotationManager.share.orientation == .landscapeRight) && Gobal_device_info.isFaceIDCapable) ? (Gobal_device_info.isPad ? 50 : 44) : 0

class PTNavigationBarBaseValues: NSObject {

}
