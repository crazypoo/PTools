//
//  PTUtils.swift
//  Diou
//
//  Created by ken lam on 2021/10/8.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import AVFoundation
import NotificationBannerSwift
import SwiftDate

@inline(__always) private func isIPhoneXSeries() -> Bool {
    var iPhoneXSeries = false
    if UIDevice.current.userInterfaceIdiom != .phone {
        return iPhoneXSeries
    }

    let mainWindow:UIView = UIApplication.shared.delegate!.window!!
    if (mainWindow.safeAreaInsets.bottom) > 0.0 {
        iPhoneXSeries = true
    }

    return iPhoneXSeries
}

@objc public enum PTUrlStringVideoType:Int {
    case MP4
    case MOV
    case ThreeGP
    case UNKNOW
}

@objc public enum PTAboutImageType:Int {
    case JPEG
    case JPEG2000
    case PNG
    case GIF
    case TIFF
    case WEBP
    case BMP
    case ICO
    case ICNS
    case UNKNOW
}

@objc public enum GradeType:Int
{
    case normal
    case TenThousand
    case HundredMillion
}

@objcMembers
public class PTUtils: NSObject {
        
    public static let share = PTUtils()
    public var timer:DispatchSourceTimer?
    
    @available(iOS, introduced: 2.0, deprecated: 13.0, message: "這個方法在iOS13之後不能使用了")
    public class func showNetworkActivityIndicator(_ show:Bool)
    {
        PTGCDManager.gcdMain {
            UIApplication.shared.isNetworkActivityIndicatorVisible = show
        }
    }
                
    public class func getCurrentVCFrom(rootVC:UIViewController)->UIViewController
    {
        var currentVC : UIViewController?
        
        if rootVC is UITabBarController
        {
            currentVC = PTUtils.getCurrentVCFrom(rootVC: (rootVC as! UITabBarController).selectedViewController!)
        }
        else if rootVC is UINavigationController
        {
            currentVC = PTUtils.getCurrentVCFrom(rootVC: (rootVC as! UINavigationController).visibleViewController!)
        }
        else
        {
            currentVC = rootVC
        }
        return currentVC!
    }
    
    public class func getCurrentVC(anyClass:UIViewController = UIViewController())->UIViewController
    {
        let currentVC = PTUtils.getCurrentVCFrom(rootVC: (AppWindows?.rootViewController ?? anyClass))
        return currentVC
    }
    
    public class func returnFrontVC()
    {
        let vc = PTUtils.getCurrentVC()
        if vc.presentingViewController != nil
        {
            vc.dismiss(animated: true, completion: nil)
        }
        else
        {
            vc.navigationController?.popViewController(animated: true, nil)
        }
    }
    
    public class func cgBaseBundle()->Bundle
    {
        let bundle = Bundle.init(for: self)
        return bundle
    }
                
    //MARK: 获取一个输入内最大的一个值
    ///获取一个输入内最大的一个值
    class open func maxOne<T:Comparable>( _ seq:[T]) -> T{

        assert(seq.count>0)
        return seq.reduce(seq[0]){
            max($0, $1)
        }
    }
                
    //MARK: 找出某view的superview
    ///找出某view的superview
    class open func findSuperViews(view:UIView)->[UIView]
    {
        var temp = view.superview
        let result = NSMutableArray()
        while temp != nil {
            result.add(temp!)
            temp = temp!.superview
        }
        return result as! [UIView]
    }
    
    //MARK: 找出某views的superview
    ///找出某views的superview
    class open func findCommonSuperView(firstView:UIView,other:UIView)->[UIView]
    {
        let result = NSMutableArray()
        let sOne = self.findSuperViews(view: firstView)
        let sOther = self.findSuperViews(view: other)
        var i = 0
        while i < min(sOne.count, sOther.count) {
            if sOne == sOther
            {
                result.add(sOne)
                i += 1
            }
            else
            {
                break
            }
        }
        return result as! [UIView]
    }
        
    //MARK: 这个方法可以用于UITextField中,检测金额输入
    class open func textInputAmoutRegex(text:NSString,range:NSRange,replacementString:NSString)->Bool
    {
        let len = (range.length > 0) ? (text.length - range.length) : (text.length + replacementString.length)
        if len > 20
        {
            return false
        }
        let str = NSString(format: "%@%@", text,replacementString)
        return (str as String).isMoneyString()
    }
    
    //MARK: 查找某字符在字符串的位置
    class open func rangeOfSubString(fullStr:NSString,subStr:NSString)->[String]
    {
        var rangeArray = [String]()
        for i in 0..<fullStr.length
        {
            let temp:NSString = fullStr.substring(with: NSMakeRange(i, subStr.length)) as NSString
            if temp.isEqual(to: subStr as String)
            {
                let range = NSRange(location: i, length: subStr.length)
                rangeArray.append(NSStringFromRange(range))
            }
        }
        return rangeArray
    }            
}

//MARK: OC-FUNCTION
extension PTUtils
{
    public class func oc_isiPhoneSeries()->Bool
    {
        return isIPhoneXSeries()
    }    
}
