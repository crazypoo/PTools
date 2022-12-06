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

@objc public enum TemperatureUnit:Int
{
    case Fahrenheit
    case CentigradeDegree
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

    //MARK: 类似iPhone点击了Home键
    public class func likeTapHome()
    {
        PTUtils.gcdMain {
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        }
    }
    
    ///ALERT真正基类
    public class func base_alertVC(title:String? = "",
                                   titleColor:UIColor? = UIColor.black,
                                   titleFont:UIFont? = UIFont.systemFont(ofSize: 15),
                                   msg:String? = "",
                                   msgColor:UIColor? = UIColor.black,
                                   msgFont:UIFont? = UIFont.systemFont(ofSize: 15),
                                   okBtns:[String]? = [String](),
                                   cancelBtn:String? = "",
                                   showIn:UIViewController,
                                   cancelBtnColor:UIColor? = .systemBlue,
                                   doneBtnColors:[UIColor]? = [UIColor](),
                                   alertBGColor:UIColor? = .white,
                                   alertCornerRadius:CGFloat? = 15,
                                   cancel:(()->Void)? = nil,
                                   moreBtn:((_ index:Int,_ title:String)->Void)?)
    {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        
        if !(cancelBtn!).stringIsEmpty()
        {
            let cancelAction = UIAlertAction(title: cancelBtn, style: .cancel) { (action) in
                if cancel != nil
                {
                    cancel!()
                }
            }
            alert.addAction(cancelAction)
            cancelAction.setValue(cancelBtnColor, forKey: "titleTextColor")
        }
        
        if (okBtns?.count ?? 0) > 0
        {
            var dontArrColor = [UIColor]()
            if doneBtnColors!.count == 0 || okBtns?.count != doneBtnColors?.count || okBtns!.count > (doneBtnColors?.count ?? 0)
            {
                if doneBtnColors!.count == 0
                {
                    okBtns?.enumerated().forEach({ (index,value) in
                        dontArrColor.append(.systemBlue)
                    })
                }
                else if okBtns!.count > (doneBtnColors?.count ?? 0)
                {
                    let count = okBtns!.count - (doneBtnColors?.count ?? 0)
                    dontArrColor = doneBtnColors!
                    for _ in 0..<(count)
                    {
                        dontArrColor.append(.systemBlue)
                    }
                }
                else if okBtns!.count < (doneBtnColors?.count ?? 0)
                {
                    let count = (doneBtnColors?.count ?? 0) - okBtns!.count
                    dontArrColor = doneBtnColors!
                    for _ in 0..<(count)
                    {
                        dontArrColor.removeLast()
                    }
                }
            }
            else
            {
                dontArrColor = doneBtnColors!
            }
            okBtns?.enumerated().forEach({ (index,value) in
                let callAction = UIAlertAction(title: value, style: .default) { (action) in
                    if moreBtn != nil
                    {
                        moreBtn!(index,value)
                    }
                }
                alert.addAction(callAction)
                callAction.setValue(dontArrColor[index], forKey: "titleTextColor")
            })
        }
        
        // KVC修改系统弹框文字颜色字号
        if !(title ?? "").stringIsEmpty()
        {
            let alertStr = NSMutableAttributedString(string: title!)
            let alertStrAttr = [NSAttributedString.Key.foregroundColor: titleColor!, NSAttributedString.Key.font: titleFont!]
            alertStr.addAttributes(alertStrAttr, range: NSMakeRange(0, title!.count))
            alert.setValue(alertStr, forKey: "attributedTitle")
        }
        
        if !(msg ?? "").stringIsEmpty()
        {
            let alertMsgStr = NSMutableAttributedString(string: msg!)
            let alertMsgStrAttr = [NSAttributedString.Key.foregroundColor: msgColor!, NSAttributedString.Key.font: msgFont!]
            alertMsgStr.addAttributes(alertMsgStrAttr, range: NSMakeRange(0, msg!.count))
            alert.setValue(alertMsgStr, forKey: "attributedMessage")
        }

        let subview = alert.view.subviews.first! as UIView
        let alertContentView = subview.subviews.first! as UIView
        if alertBGColor != .white
        {
            alertContentView.backgroundColor = alertBGColor
        }
        alertContentView.layer.cornerRadius = alertCornerRadius!
        
        showIn.present(alert, animated: true, completion: nil)
    }

    public class func base_textfiele_alertVC(title:String? = "",
                                             titleColor:UIColor? = UIColor.black,
                                             titleFont:UIFont? = UIFont.systemFont(ofSize: 15),
                                             okBtn:String,
                                             cancelBtn:String,
                                             showIn:UIViewController,
                                             cancelBtnColor:UIColor? = .black,
                                             doneBtnColor:UIColor? = .systemBlue,
                                             placeHolders:[String],
                                             textFieldTexts:[String],
                                             keyboardType:[UIKeyboardType]?,
                                             textFieldDelegate:Any? = nil,
                                             alertBGColor:UIColor? = .white,
                                             alertCornerRadius:CGFloat? = 15,
                                             cancel:(()->Void)? = nil,
                                             doneBtn:((_ result:[String:String])->Void)?)
    {
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: cancelBtn, style: .cancel) { (action) in
            if cancel != nil
            {
                cancel!()
            }
        }
        alert.addAction(cancelAction)
        cancelAction.setValue(cancelBtnColor, forKey: "titleTextColor")

        if placeHolders.count == textFieldTexts.count
        {
            placeHolders.enumerated().forEach({ (index,value) in
                alert.addTextField { (textField : UITextField) -> Void in
                    textField.placeholder = value
                    textField.delegate = (textFieldDelegate as! UITextFieldDelegate)
                    textField.tag = index
                    textField.text = textFieldTexts[index]
                    if keyboardType?.count == placeHolders.count
                    {
                        textField.keyboardType = keyboardType![index]
                    }
                }
            })
        }
        
        let doneAction = UIAlertAction(title: okBtn, style: .default) { (action) in
            var resultDic = [String:String]()
            alert.textFields?.enumerated().forEach({ (index,value) in
                resultDic[value.placeholder!] = value.text
            })
            if doneBtn != nil
            {
                doneBtn!(resultDic)
            }
        }
        alert.addAction(doneAction)
        doneAction.setValue(doneBtnColor, forKey: "titleTextColor")

        // KVC修改系统弹框文字颜色字号
        if !(title ?? "").stringIsEmpty()
        {
            let alertStr = NSMutableAttributedString(string: title!)
            let alertStrAttr = [NSAttributedString.Key.foregroundColor: titleColor!, NSAttributedString.Key.font: titleFont!]
            alertStr.addAttributes(alertStrAttr, range: NSMakeRange(0, title!.count))
            alert.setValue(alertStr, forKey: "attributedTitle")
        }

        let subview = alert.view.subviews.first! as UIView
        let alertContentView = subview.subviews.first! as UIView
        if alertBGColor != .white
        {
            alertContentView.backgroundColor = alertBGColor
        }
        alertContentView.layer.cornerRadius = alertCornerRadius!
        showIn.present(alert, animated: true, completion: nil)
    }

    public class func showNetworkActivityIndicator(_ show:Bool)
    {
        PTUtils.gcdMain {
            UIApplication.shared.isNetworkActivityIndicatorVisible = show
        }
    }
    
    public class func gcdAfter(time:TimeInterval,
                             block:@escaping (()->Void))
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + time, execute: block)
    }
    
    public class func gcdMain(block:@escaping (()->Void))
    {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.sync(execute: block)
        }
    }
    
    public class func getTimeStamp()->String
    {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        _ = NSTimeZone.init(name: "Asia/Shanghai")
        return String(format: "%.0f", date.timeIntervalSince1970 * 1000)
    }
    
    public class func timeRunWithTime_base(customQueName:String,timeInterval:TimeInterval,finishBlock:@escaping ((_ finish:Bool,_ time:Int)->Void))
    {
        let customQueue = DispatchQueue(label: customQueName)
        var newCount = Int(timeInterval) + 1
        PTUtils.share.timer = DispatchSource.makeTimerSource(flags: [], queue: customQueue)
        PTUtils.share.timer!.schedule(deadline: .now(), repeating: .seconds(1))
        PTUtils.share.timer!.setEventHandler {
            DispatchQueue.main.async {
                newCount -= 1
                finishBlock(false,newCount)
                if newCount < 1 {
                    DispatchQueue.main.async {
                        finishBlock(true,0)
                    }
                    PTUtils.share.timer!.cancel()
                    PTUtils.share.timer = nil
                }
            }
        }
        PTUtils.share.timer!.resume()
    }
    
    public class func timeRunWithTime(timeInterval:TimeInterval,
                                    sender:UIButton,
                                    originalTitle:String,
                                    canTap:Bool,
                                timeFinish:(()->Void)?)
    {
        PTUtils.timeRunWithTime_base(customQueName:"TimeFunction",timeInterval: timeInterval) { finish, time in
            if finish
            {
                sender.setTitle(originalTitle, for: sender.state)
                sender.isUserInteractionEnabled = canTap
                if timeFinish != nil
                {
                    timeFinish!()
                }
            }
            else
            {
                let strTime = String.init(format: "%.2d", time)
                let buttonTime = String.init(format: "%@", strTime)
                sender.setTitle(buttonTime, for: sender.state)
                sender.isUserInteractionEnabled = false
            }
        }
    }
    
    public class func contentTypeForUrl(url:String)->PTUrlStringVideoType
    {
        let pathEX = url.pathExtension.lowercased()
        
        if pathEX.contains("mp4")
        {
            return .MP4
        }
        else if pathEX.contains("mov")
        {
            return .MOV
        }
        else if pathEX.contains("3gp")
        {
            return .ThreeGP
        }
        return .UNKNOW
    }
        
    public class func sizeFor(string:String,
                              font:UIFont,
                              lineSpacing:CGFloat? = nil,
                              height:CGFloat,
                              width:CGFloat)->CGSize
    {
        var dic = [NSAttributedString.Key.font:font] as! [NSAttributedString.Key:Any]
        if lineSpacing != nil
        {
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineSpacing = lineSpacing!
            dic[NSAttributedString.Key.paragraphStyle] = paraStyle
        }
        let size = string.boundingRect(with: CGSize.init(width: width, height: height), options: [.usesLineFragmentOrigin,.usesDeviceMetrics], attributes: dic, context: nil).size
        return size
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
    
    public class func getCurrentVC(anyClass:UIViewController? = UIViewController())->UIViewController
    {
        let currentVC = PTUtils.getCurrentVCFrom(rootVC: (AppWindows?.rootViewController ?? anyClass!))
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
    
    @available(iOS 11.0, *)
    public class func color(name:String,traitCollection:UITraitCollection,bundle:Bundle? = PTUtils.cgBaseBundle())->UIColor
    {
        return UIColor(named: name, in: bundle!, compatibleWith: traitCollection) ?? .randomColor
    }
    
    public class func image(name:String,traitCollection:UITraitCollection,bundle:Bundle? = PTUtils.cgBaseBundle())->UIImage
    {
        return UIImage(named: name, in: bundle!, compatibleWith: traitCollection) ?? UIColor.randomColor.createImageWithColor()
    }
    
    public class func darkModeImage(name:String,bundle:Bundle? = PTUtils.cgBaseBundle())->UIImage
    {
        return PTUtils.image(name: name, traitCollection: (UIApplication.shared.delegate?.window?!.rootViewController!.traitCollection)!,bundle: bundle!)
    }
        
    //MARK:SDWebImage的加载失误图片方式(全局控制)
    ///SDWebImage的加载失误图片方式(全局控制)
    public class func gobalWebImageLoadOption()->SDWebImageOptions
    {
        #if DEBUG
        let userDefaults = UserDefaults.standard.value(forKey: "sdwebimage_option")
        let devServer:Bool = userDefaults == nil ? true : (userDefaults as! Bool)
        if devServer
        {
            return .retryFailed
        }
        else
        {
            return .lowPriority
        }
        #else
        return .retryFailed
        #endif
    }
    
    //MARK: 弹出框
    class open func gobal_drop(title:String?,titleFont:UIFont? = UIFont.appfont(size: 16),titleColor:UIColor? = .black,subTitle:String? = nil,subTitleFont:UIFont? = UIFont.appfont(size: 16),subTitleColor:UIColor? = .black,bannerBackgroundColor:UIColor? = .white,notifiTap:(()->Void)? = nil)
    {
        var titleStr = ""
        if title == nil || (title ?? "").stringIsEmpty()
        {
            titleStr = ""
        }
        else
        {
            titleStr = title!
        }
        
        var subTitleStr = ""
        if subTitle == nil || (subTitle ?? "").stringIsEmpty()
        {
            subTitleStr = ""
        }
        else
        {
            subTitleStr = subTitle!
        }
                
        let banner = FloatingNotificationBanner(title:titleStr,subtitle: subTitleStr)
        banner.duration = 1.5
        banner.backgroundColor = bannerBackgroundColor!
        banner.subtitleLabel?.textAlignment = PTUtils.sizeFor(string: subTitleStr, font: subTitleFont!, height:44, width: CGFloat(MAXFLOAT)).width > (kSCREEN_WIDTH - 36) ? .left : .center
        banner.subtitleLabel?.font = subTitleFont
        banner.subtitleLabel?.textColor = subTitleColor!
        banner.titleLabel?.textAlignment = PTUtils.sizeFor(string: titleStr, font: titleFont!, height:44, width: CGFloat(MAXFLOAT)).width > (kSCREEN_WIDTH - 36) ? .left : .center
        banner.titleLabel?.font = titleFont
        banner.titleLabel?.textColor = titleColor!
        banner.show(queuePosition: .front, bannerPosition: .top ,cornerRadius: 15)
        banner.onTap = {
            if notifiTap != nil
            {
                notifiTap!()
            }
        }
    }

    //MARK: 生成CollectionView的Group
    @available(iOS 13.0, *)
    class open func gobal_collection_gird_layout(data:[AnyObject],
                                                 size:CGSize? = CGSize.init(width: (kSCREEN_WIDTH - 10 * 2)/3, height: (kSCREEN_WIDTH - 10 * 2)/3),
                                                 originalX:CGFloat? = 10,
                                                 mainWidth:CGFloat? = kSCREEN_WIDTH,
                                                 cellRowCount:NSInteger? = 3,
                                                 sectionContentInsets:NSDirectionalEdgeInsets? = NSDirectionalEdgeInsets.init(top: 0, leading: 0, bottom: 0, trailing: 0),
                                                 contentTopAndBottom:CGFloat? = 0,
                                                 cellLeadingSpace:CGFloat? = 0,
                                                 cellTrailingSpace:CGFloat? = 0)->NSCollectionLayoutGroup
    {
        let bannerItemSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.fractionalWidth(1), heightDimension: NSCollectionLayoutDimension.fractionalHeight(1))
        let bannerItem = NSCollectionLayoutItem.init(layoutSize: bannerItemSize)
        var bannerGroupSize : NSCollectionLayoutSize

        var customers = [NSCollectionLayoutGroupCustomItem]()
        var groupH:CGFloat = 0

        let itemH = size!.height
        let itemW = size!.width

        var x:CGFloat = originalX!,y:CGFloat = 0 + contentTopAndBottom!
        data.enumerated().forEach { (index,value) in
            if index < cellRowCount!
            {
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: x, y: y, width: itemW, height: itemH), zIndex: 1000+index)
                customers.append(customItem)
                x += itemW + cellLeadingSpace!
                if index == (data.count - 1)
                {
                    groupH = y + itemH + contentTopAndBottom!
                }
            }
            else
            {
                x += itemW + cellLeadingSpace!
                if index > 0 && (index % cellRowCount! == 0)
                {
                    x = originalX!
                    y += itemH + cellTrailingSpace!
                }

                if index == (data.count - 1)
                {
                    groupH = y + itemH + contentTopAndBottom!
                }
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: x, y: y, width: itemW, height: itemH), zIndex: 1000+index)
                customers.append(customItem)
            }
        }

        bannerItem.contentInsets = sectionContentInsets!
        bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(mainWidth!-originalX!*2), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
        return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
            customers
        })
    }
    
    //MARK: 计算CollectionView的Group高度
    class open func gobal_collection_gird_layout_content_height(data:[AnyObject],
                                                                size:CGSize? = CGSize.init(width: (kSCREEN_WIDTH - 10 * 2)/3, height: (kSCREEN_WIDTH - 10 * 2)/3),
                                                                cellRowCount:NSInteger? = 3,
                                                                originalX:CGFloat? = 10,
                                                                contentTopAndBottom:CGFloat? = 0,
                                                                cellLeadingSpace:CGFloat? = 0,
                                                                cellTrailingSpace:CGFloat? = 0)->CGFloat
    {
        var groupH:CGFloat = 0
        let itemH = size!.height
        let itemW = size!.width
        var x:CGFloat = originalX!,y:CGFloat = 0 + contentTopAndBottom!
        data.enumerated().forEach { (index,value) in
            if index < cellRowCount!
            {
                x += itemW + cellLeadingSpace!
                if index == (data.count - 1)
                {
                    groupH = y + itemH + contentTopAndBottom!
                }
            }
            else
            {
                x += itemW + cellLeadingSpace!
                if index > 0 && (index % cellRowCount! == 0)
                {
                    x = originalX!
                    y += itemH + cellTrailingSpace!
                }

                if index == (data.count - 1)
                {
                    groupH = y + itemH + contentTopAndBottom!
                }
            }
        }
        return groupH
    }

    //MARK: 获取一个输入内最大的一个值
    ///获取一个输入内最大的一个值
    class open func maxOne<T:Comparable>( _ seq:[T]) -> T{

        assert(seq.count>0)
        return seq.reduce(seq[0]){
            max($0, $1)
        }
    }
    
    //MARK: 华氏摄氏度转普通摄氏度/普通摄氏度转华氏摄氏度
    ///华氏摄氏度转普通摄氏度/普通摄氏度转华氏摄氏度
    class open func temperatureUnitExchangeValue(value:CGFloat,changeToType:TemperatureUnit) ->CGFloat
    {
        switch changeToType {
        case .Fahrenheit:
            return 32 + 1.8 * value
        case .CentigradeDegree:
            return (value - 32) / 1.8
        default:
            return 0
        }
    }
    
    //MARK: 判断是否白天
    /// 判断是否白天
    class open func isNowDayTime()->Bool
    {
        let date = NSDate()
        let cal :NSCalendar = NSCalendar.current as NSCalendar
        let components : NSDateComponents = cal.components(.hour, from: date as Date) as NSDateComponents
        if components.hour >= 19 || components.hour < 6
        {
            return false
        }
        else
        {
            return true
        }
    }
        
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
    
    class open func createNoneInterpolatedUIImage(image:CIImage,imageSize:CGFloat)->UIImage
    {
        let extent = CGRectIntegral(image.extent)
        let scale = min(imageSize / extent.width, imageSize / extent.height)
        
        let width = extent.width * scale
        let height = extent.height * scale
        let cs = CGColorSpaceCreateDeviceGray()
        let bitmapRef:CGContext = CGContext(data: nil , width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.none.rawValue)!
        let context = CIContext.init()
        let bitmapImage = context.createCGImage(image, from: extent)
        bitmapRef.interpolationQuality = .none
        bitmapRef.scaleBy(x: scale, y: scale)
        bitmapRef.draw(bitmapImage!, in: extent)
        
        let scaledImage = bitmapRef.makeImage()
        let newImage = UIImage(cgImage: scaledImage!)
        return newImage
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
        
    class open func getIntPartUper(digit:Int)->NSString
    {
        let normalGrade = digit % 10000
        let tenThousandGrade = digit / 10000 % 10000
        let hundredMillionGrade = digit / 100000000
        let normalGradeStr = PTUtils.dealDigit(digit: normalGrade, type: .normal)
        let tenThousandGradeStr = PTUtils.dealDigit(digit: tenThousandGrade, type: .TenThousand)
        let hundredMillionGradeStr = PTUtils.dealDigit(digit: hundredMillionGrade, type: .HundredMillion)
        let tmpStr = NSMutableString(format: "%@%@%@元", hundredMillionGradeStr,tenThousandGradeStr,normalGradeStr)
        if (tmpStr.substring(to: 1) as NSString).isEqual(to: "零")
        {
            let str1:NSString = tmpStr.substring(from: 1) as NSString
            if (str1.substring(to: 2) as NSString).isEqual(to: "壹拾")
            {
                return str1.substring(from: 1) as NSString
            }
            else
            {
                return str1
            }
        }
        else
        {
            return tmpStr
        }
    }
    
    class open func getPartAfterDot(digitStr:NSString)->NSString
    {
        if digitStr.length > 0
        {
            let uperArray = ["零","壹","贰","叁","肆","伍","陆","柒","捌","玖"]
            var digitStr1:NSString = ""
            if digitStr.length == 1
            {
                digitStr1 = NSString(format: "%@0", digitStr)
                let digit = (digitStr1.substring(to: 2) as NSString).integerValue
                let one = digit / 10
                let two = digit % 10
                if one != 0 && two != 0
                {
                    return NSString(format: "%@角%@分", uperArray[one],uperArray[two])
                }
                else if one == 0 && two != 0
                {
                    return NSString(format: "%@分", uperArray[two])
                }
                else if one != 0 && two == 0
                {
                    return NSString(format: "%@角", uperArray[one])
                }
                else
                {
                    return "零"
                }
            }
            else
            {
                let digit = (digitStr.substring(to: 2) as NSString).integerValue
                let one = digit / 10
                let two = digit % 10
                if one != 0 && two != 0
                {
                    return NSString(format: "%@角%@分", uperArray[one],uperArray[two])
                }
                else if one == 0 && two != 0
                {
                    return NSString(format: "%@分", uperArray[two])
                }
                else if one != 0 && two == 0
                {
                    return NSString(format: "%@角", uperArray[one])
                }
                else
                {
                    return "零"
                }
            }
        }
        return "零"
    }
    
    class open func dealDigit(digit:Int,type:GradeType)->NSString
    {
        if digit > 0
        {
            let uperArray = ["零","壹","贰","叁","肆","伍","陆","柒","捌","玖"]
            let uperUnitArray = ["","拾","佰","仟"]

            let normal = NSString(format: "%d", digit % 10)
            let ten = NSString(format: "%d", digit % 100 / 10)
            let hundred = NSString(format: "%d", digit % 1000 / 100)
            let thousand = NSString(format: "%d", digit / 1000)
            let tempArray = [normal,ten,hundred,thousand]
            let saveStrArray = NSMutableArray()
            var lastIsZero = true
            for i in 0..<tempArray.count
            {
                let tmp = tempArray[i].integerValue
                if tmp == 0
                {
                    if !lastIsZero
                    {
                        saveStrArray.add("")
                        lastIsZero = true
                    }
                }
                else
                {
                    saveStrArray.add(NSString(format: "%@%@", uperArray[tmp],uperUnitArray[i]))
                    lastIsZero = false
                }
            }
            
            let destStr = NSMutableString()
            for i in stride(from: saveStrArray.count - 1, through: 0, by: -1) {
                destStr.append(saveStrArray[i] as! String)
            }
            
            switch type {
            case .normal:
                return destStr
            case .TenThousand:
                return NSString(format: "%@万", destStr)
            default:
                return NSString(format: "%@亿", destStr)
            }
        }
        return "零"
    }
    
    class open func digitUppercase(numberStr:NSString)->NSString
    {
        let numberals = numberStr.doubleValue
        let numberchar = ["零","壹","贰","叁","肆","伍","陆","柒","捌","玖"]
        let inunitchar = ["","拾","佰","仟"]
        let unitname = ["","万","亿","万亿"]
        //金额乘以100转换成字符串（去除圆角分数值）
        let valStr = NSString(format: "%.2f", numberals)
        var prefix:NSString = ""
        var suffix:NSString = ""
        if valStr.length <= 2
        {
            prefix = "零元"
            if valStr.length == 0
            {
                suffix = "零角零分"
            }
            else if valStr.length == 1
            {
                suffix = NSString(format: "@分", numberchar[valStr.integerValue])
            }
            else
            {
                let head:NSString = valStr.substring(to: 1) as NSString
                let foot:NSString = valStr.substring(from: 1) as NSString
                suffix = NSString(format: "%@角%@分", numberchar[head.integerValue],numberchar[foot.integerValue])
            }
        }
        else
        {
            prefix = ""
            suffix = ""
            let flag = valStr.length - 2
            let head:NSString = valStr.substring(to: flag - 1) as NSString
            let foot:NSString = valStr.substring(from: flag) as NSString
            if head.length > 13
            {
                return "数值太大（最大支持13位整数），无法处理"
            }
            //处理整数部分
            let ch = NSMutableArray()
            for i in 0..<head.length
            {
                let str = NSString(format: "%x", head.character(at: i) - 0)
                ch.add(str)
            }
            var zeronum:Int = 0
            for i in 0..<ch.count
            {
                let index = (ch.count - i - 1) % 4
                let indexloc = (ch.count - i - 1) / 4

                if (ch[i] as! NSString).isEqual(to: "0")
                {
                    zeronum += 1
                }
                else
                {
                    if zeronum != 0
                    {
                        if index != 3
                        {
                            prefix = prefix.appending("零") as NSString
                        }
                        zeronum = 0
                    }
                    prefix = prefix.appending(numberchar[(ch[i] as! NSString).integerValue]) as NSString
                    prefix = prefix.appending(inunitchar[index]) as NSString
                }
                if index == 0 && zeronum < 4
                {
                    prefix = prefix.appending(unitname[indexloc]) as NSString
                }
            }
            prefix = prefix.appending("元") as NSString
            if foot.isEqual(to: "00")
            {
                suffix = suffix.appending("整") as NSString
            }
            else if foot.hasPrefix("0")
            {
                let footch = NSString(format: "%x", (foot.character(at: 1) - 0))
                suffix = NSString(format: "%@分", numberchar[footch.integerValue])
            }
            else
            {
                let headch = NSString(format: "%x", (foot.character(at: 0) - 0))
                let footch = NSString(format: "%x", (foot.character(at: 1) - 0))
                suffix = NSString(format: "%@角%@分", numberchar[headch.integerValue],numberchar[footch.integerValue])
            }
        }
        return prefix.appending(suffix as String) as NSString
    }
}

//MARK: OC-FUNCTION
extension PTUtils
{
    public class func oc_alert_base(title:String,msg:String,okBtns:[String],cancelBtn:String,showIn:UIViewController,cancel:@escaping (()->Void),moreBtn:@escaping ((_ index:Int,_ title:String)->Void))
    {
        PTUtils.base_alertVC(title: title, msg: msg, okBtns: okBtns, cancelBtn: cancelBtn, showIn: showIn, cancel: cancel, moreBtn: moreBtn)
    }

    public class func oc_size(string:String,
                              font:UIFont,
                              lineSpacing:CGFloat = CGFloat.ScaleW(w: 3),
                              height:CGFloat,
                              width:CGFloat)->CGSize
    {
        return PTUtils.sizeFor(string: string, font: font,lineSpacing: lineSpacing, height: height, width: width)
    }
    
    class open func oc_font(fontSize:CGFloat)->UIFont
    {
        return UIFont.appfont(size: fontSize)
    }

    //MARK: 时间
    class open func oc_currentTimeFunction(dateFormatter:NSString)->String
    {
        return String.currentDate(dateFormatterString: dateFormatter as String)
    }
    
    class open func oc_currentTimeToTimeInterval(dateFormatter:NSString)->TimeInterval
    {
        return String.currentDate(dateFormatterString: dateFormatter as String).dateStrToTimeInterval(dateFormat: dateFormatter as String)
    }

    class open func oc_dateStringFormat(dateString:String,formatString:String)->NSString
    {
        let regions = Region(calendar: Calendars.republicOfChina,zone: Zones.asiaHongKong,locale: Locales.chineseChina)
        return dateString.toDate(formatString,region: regions)!.toString() as NSString
    }
    
    class open func oc_dateFormat(date:Date,formatString:String)->String
    {
        return date.toFormat(formatString)
    }
}
