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

@objc public enum PTUrlStringVideoType:Int {
    case MP4
    case MOV
    case ThreeGP
    case UNKNOW
}

@objc public enum PTAboutImageType:Int {
    case JPEG
    case PNG
    case GIF
    case TIFF
    case WEBP
    case UNKNOW
}

extension PTUtils
{
    @objc static func oc_alert_base(title:String,msg:String,okBtns:[String],cancelBtn:String,showIn:UIViewController,cancel:@escaping (()->Void),moreBtn:@escaping ((_ index:Int,_ title:String)->Void))
    {
        PTUtils.base_alertVC(title: title, msg: msg, okBtns: okBtns, cancelBtn: cancelBtn, showIn: showIn, cancel: cancel, moreBtn: moreBtn)
    }
}

@objcMembers
public class PTUtils: NSObject {
    
    //MARK: 判断机型
    ///小
    class open func oneOfSmallDevice()->Bool
    {
        return Gobal_device_info.isOneOf(Gobal_group_of_all_small_device)
    }
    
    ///大
    class open func oneOfPlusDevice()->Bool
    {
        return Gobal_device_info.isOneOf(Gobal_group_of_all_plus_device)
    }

    ///X
    class open func oneOfXDevice()->Bool
    {
        return Gobal_device_info.isOneOf(Gobal_group_of_all_X_device)
    }
    
    class open func oneOfPadDevice()->Bool
    {
        return Gobal_device_info.isOneOf(Gobal_group_of_all_iPad)
    }
    
    ///ALERT真正基类
    public class func base_alertVC(title:String? = NSLocalizedString("OPPS", comment: ""),
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

    public class func base_textfiele_alertVC(title:String? = NSLocalizedString("OPPS", comment: ""),
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

    public class func thumbnailImage(videoURL:String)->UIImage
    {
        if videoURL.isEmpty {
            //默认封面图
            return PTUtils.createImageWithColor(color: UIColor.randomColor)
        }
        let aset = AVURLAsset(url: URL(fileURLWithPath: videoURL), options: nil)
        let assetImg = AVAssetImageGenerator(asset: aset)
        assetImg.appliesPreferredTrackTransform = true
        assetImg.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels
        do{
            let cgimgref = try assetImg.copyCGImage(at: CMTime(seconds: 10, preferredTimescale: 50), actualTime: nil)
            return UIImage(cgImage: cgimgref)
        }catch{
            return PTUtils.createImageWithColor(color: UIColor.randomColor)
        }
    }
    
    public class func timeRunWithTime_base(timeInterval:TimeInterval,finishBlock:@escaping ((_ finish:Bool,_ time:Int)->Void))
    {
        var newCount = Int(timeInterval) + 1
        let timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        timer.schedule(deadline: .now(), repeating: .seconds(1))
        timer.setEventHandler {
            DispatchQueue.main.async {
                newCount -= 1
                finishBlock(false,newCount)
                if newCount < 1 {
                    DispatchQueue.main.async {
                        finishBlock(true,0)
                    }
                    timer.cancel()
                }
            }
        }
        timer.resume()
    }

    
    public class func timeRunWithTime(timeInterval:TimeInterval,
                                    sender:UIButton,
                                    originalTitle:String,
                                    canTap:Bool,
                                timeFinish:(()->Void)?)
    {
        PTUtils.timeRunWithTime_base(timeInterval: timeInterval) { finish, time in
            if finish
            {
                sender.setTitle(originalTitle, for: .normal)
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
                sender.setTitle(buttonTime, for: .normal)
                sender.isUserInteractionEnabled = canTap
            }
        }
    }
    
    public class func createImageWithColor(color:UIColor)->UIImage
    {
        let rect = CGRect.init(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let ccontext = UIGraphicsGetCurrentContext()
        ccontext?.setFillColor(color.cgColor)
        ccontext!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
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
                            height:CGFloat,
                            width:CGFloat)->CGSize
    {
        let dic = [NSAttributedString.Key.font:font]
        let size = string.boundingRect(with: CGSize.init(width: width, height: height), options: [.usesLineFragmentOrigin,.usesDeviceMetrics], attributes: dic, context: nil).size
        return size
    }
    
    public class func getCurrentVCFrom(rootVC:UIViewController)->UIViewController
    {
//        var newRoot:UIViewController?
        var currentVC : UIViewController?
//        if rootVC.presentedViewController != nil
//        {
//            newRoot = rootVC.presentedViewController!
//        }
//        else
//        {
//            newRoot = rootVC
//        }
        
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
        let currentVC = PTUtils.getCurrentVCFrom(rootVC: (UIApplication.shared.keyWindow?.rootViewController ?? anyClass!))
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
        return UIImage(named: name, in: bundle!, compatibleWith: traitCollection) ?? PTUtils.createImageWithColor(color: UIColor.randomColor)
    }
    
    public class func darkModeImage(name:String,bundle:Bundle? = PTUtils.cgBaseBundle())->UIImage
    {
        return PTUtils.image(name: name, traitCollection: (UIApplication.shared.delegate?.window?!.rootViewController!.traitCollection)!,bundle: bundle!)
    }

    //Mark:越狱检测
    ///越狱检测
    public class func isJailBroken()->Bool
    {
        let apps = ["/Applications/Cydia.app",
                  "/Applications/limera1n.app",
                  "/Applications/greenpois0n.app",
                  "/Applications/blackra1n.app",
                  "/Applications/blacksn0w.app",
                  "/Applications/redsn0w.app",
                  "/Applications/Absinthe.app",
                    "/private/var/lib/apt"]
        for app in apps
        {
            if FileManager.default.fileExists(atPath: app)
            {
                return true
            }
        }
        return false
    }
    
    public class func watermark(originalImage:UIImage,title:String,font:UIFont? = UIFont.systemFont(ofSize: 23),color:UIColor?) -> UIImage
    {
        
        let HORIZONTAL_SPACE = 30
        let VERTICAL_SPACE = 50
        
        let viewWidth = originalImage.size.width
        let viewHeight = originalImage.size.height
        
        let newColor = (color == nil) ? originalImage.imageMostColor() : color
        
        UIGraphicsBeginImageContext(CGSize.init(width: viewWidth, height: viewHeight))
        originalImage.draw(in: CGRect.init(x: 0, y: 0, width: viewWidth, height: viewHeight))
        let sqrtLength = sqrt(viewWidth * viewWidth + viewHeight * viewHeight)
        let attr = [NSAttributedString.Key.font:font!,NSAttributedString.Key.foregroundColor:newColor!]
        let mark : NSString = title as NSString
        let attrStr = NSMutableAttributedString.init(string: mark as String, attributes: attr)
        let strWidth = attrStr.size().width
        let strHeight = attrStr.size().height
        let context = UIGraphicsGetCurrentContext()!
        context.concatenate(CGAffineTransform(translationX: viewWidth/2, y: viewHeight/2))
        context.concatenate(CGAffineTransform(rotationAngle: (Double.pi / 2 / 3)))
        context.concatenate(CGAffineTransform(translationX: -viewWidth/2, y: -viewHeight/2))
        
        let horCount : Int = Int(sqrtLength / (strWidth + CGFloat(HORIZONTAL_SPACE)) + 1)
        let verCount : Int = Int(sqrtLength / (strWidth + CGFloat(VERTICAL_SPACE)) + 1)
        
        let orignX = -(sqrtLength - viewWidth)/2
        let orignY = -(sqrtLength - viewHeight)/2

        var tempOrignX = orignX
        var tempOrignY = orignY

        let totalCount : Int = Int(horCount * verCount)
        for i in 0..<totalCount
        {
            mark.draw(in: CGRect.init(x: tempOrignX, y: tempOrignY, width: strWidth, height: strHeight), withAttributes: attr)
            if i % horCount == 0 && i != 0
            {
                tempOrignX = orignX
                tempOrignY += (strHeight + CGFloat(VERTICAL_SPACE))
            }
            else
            {
                tempOrignX += (strWidth + CGFloat(HORIZONTAL_SPACE))
            }
        }
        
        let finalImg = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        context.restoreGState()
        return finalImg
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
    
    public class func jsonStringToArray(jsonStr:String)->NSArray
    {
        do {
            let tmp = try JSONSerialization.jsonObject(with: jsonStr.data(using: String.Encoding.utf8)!, options: [JSONSerialization.ReadingOptions.mutableLeaves,JSONSerialization.ReadingOptions.mutableContainers])
            if tmp is NSArray
            {
                return (tmp as! NSArray)
            }
            else if (tmp is NSString) || (tmp is NSDictionary)
            {
                return NSArray.init(array: [tmp])
            }
        } catch {
            return NSArray.init()
        }
        return NSArray.init()
    }
    
    //MARK: 弹出框
    class open func gobal_drop(title:String?,titleFont:UIFont? = UIFont.appfont(size: 16),subTitle:String? = nil,subTitleFont:UIFont? = UIFont.appfont(size: 16),notifiTap:(()->Void)? = nil)
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
        banner.backgroundColor = .white
        banner.subtitleLabel?.textAlignment = PTUtils.sizeFor(string: subTitleStr, font: subTitleFont!, height:44, width: CGFloat(MAXFLOAT)).width > (kSCREEN_WIDTH - 36) ? .left : .center
        banner.subtitleLabel?.font = subTitleFont
        banner.subtitleLabel?.textColor = .black
        banner.titleLabel?.textAlignment = PTUtils.sizeFor(string: titleStr, font: titleFont!, height:44, width: CGFloat(MAXFLOAT)).width > (kSCREEN_WIDTH - 36) ? .left : .center
        banner.titleLabel?.font = titleFont
        banner.titleLabel?.textColor = .black
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
}
