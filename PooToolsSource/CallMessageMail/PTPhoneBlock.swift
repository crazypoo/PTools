//
//  PTPhoneBlock.swift
//  PooTools_Example
//
//  Created by ken lam on 2021/10/26.
//  Copyright © 2021 crazypoo. All rights reserved.
//

import UIKit

public typealias CallBlock = (_ timeInterval:TimeInterval)->Void
public typealias CanCall = (_ ok:Bool)->Void

@objcMembers
public class PTPhoneBlock: NSObject {
    public static let shared = PTPhoneBlock()
    
    private var callStartTime:Date?
    
    open var callBlock:CallBlock?
    open var cancelBlock:PTActionTask?
    open var canCall:CanCall?

    public class func callPhoneNumber(phoneNumber:String,call:@escaping CallBlock,cancel:@escaping PTActionTask,canCall:@escaping CanCall) {
        var canCallSomeOne:Bool? = false
        if PTPhoneBlock.validPhone(phoneNumber: phoneNumber) {
            let share = PTPhoneBlock.shared
            share.setNotifications()
            share.callBlock = call
            share.cancelBlock = cancel
            
            let simplePhoneNumber = (phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted) as NSArray).componentsJoined(by: "")
            let stringURL = ("telprompt://" as NSString).appending(simplePhoneNumber)
            PTAppStoreFunction.jumpLink(url: URL(string: stringURL)!)
            canCallSomeOne = true
        }
        canCall(canCallSomeOne!)
    }
    
    public class func validPhone(phoneNumber:String)->Bool {
        let type = NSTextCheckingResult.phoneNumberCheckingResult(range: NSRange.init(location: 0, length: phoneNumber.charactersArray.count), phoneNumber: phoneNumber).resultType
        return type == NSTextCheckingResult.CheckingType.phoneNumber
    }
    
    func setNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    func applicationDidEnterBackground(notification:NSNotification) {
        callStartTime = Date()
    }
    
    @MainActor func applicationDidBecomeActive(notification:NSNotification) {
        NotificationCenter.default.removeObserver(self)
        
        if callStartTime != nil {
            callBlock?(-(callStartTime!.timeIntervalSinceNow) - 3)
            callStartTime = nil
        }
        cancelBlock?()
    }
}
