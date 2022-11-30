//
//  PTBankSimpleInfoNetwork.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/11/22.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public class PTBankSimpleInfoModel:PTBaseModel
{
    var bank:String = ""
    var validated:Bool = false
    var message:[String] = [String]()
    var key:String = ""
    var cardType:String = ""
    var stat:Bool = false
    var logoUrl:String = ""
}

public class PTBankSimpleInfoNetwork: NSObject {
    class public func getBankSimpleInfo(cardNum:NSString,handle:((_ model:PTBankSimpleInfoModel)->Void)?)
    {
        Network.requestApi(needGobal:false,urlStr: cardNum.getBankName() as String) { result, error in
            guard let responseModel = result?.originalString.kj.model(PTBankSimpleInfoModel.self) else { return }
            responseModel.logoUrl = "https://apimg.alipay.com/combo.png?d=cashier&t=" + responseModel.bank
            if handle != nil
            {
                handle!(responseModel)
            }
        }
    }
}
