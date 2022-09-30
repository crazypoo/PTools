//
//  Application+PTEX.swift
//  PooTools_Example
//
//  Created by jax on 2022/9/30.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

extension UIApplication: PTProtocolCompatible { }

public extension PTProtocol where Base: UIApplication
{
    //MARK: 获取应用的location
    static var currentApplicationLocal:String
    {
        let locale:NSLocale = NSLocale.current as NSLocale
        let countryCode = locale.object(forKey: NSLocale.Key.countryCode)
        let usLocale = NSLocale.init(localeIdentifier: "en_US")
        let country = usLocale.displayName(forKey: NSLocale.Key.countryCode, value: countryCode!)
        return country!
    }
}
