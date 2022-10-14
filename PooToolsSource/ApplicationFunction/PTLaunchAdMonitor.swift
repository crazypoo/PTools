//
//  PTLaunchAdMonitor.swift
//  Diou
//
//  Created by ken lam on 2021/10/9.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import AVKit
import DeviceKit

public typealias PTLaunchAdMonitorCallBack = () -> Void

public let PLaunchAdDetailDisplayNotification = "PShowLaunchAdDetailNotification"

@objcMembers
public class PTLaunchAdMonitor: NSObject {
    public static let shared = PTLaunchAdMonitor()
    public static let monitor : PTLaunchAdMonitor = PTLaunchAdMonitor.shared

    private var playMovie:Bool?
    private var imgLoaded:Bool? = false
    private var videoUrl:URL?
    private var imgData:NSMutableData?
    private var imageType:PTAboutImageType?
    private var callBack:PTLaunchAdMonitorCallBack?
    private var player:AVPlayerViewController?
    private var detailParam:NSMutableDictionary?

    public class func showAt(path:NSArray,onView:Any,timeInterval:TimeInterval,param:NSDictionary?,year:String?,skipFont:UIFont?,comName:String?,comNameFont:UIFont,callBack:PTLaunchAdMonitorCallBack?)
    {
        PTLaunchAdMonitor.shared.loadImageAtPath(path: path)
        while !monitor.imgLoaded! {
            RunLoop.current.run(mode: .default, before: Date.distantFuture)
        }
        
        monitor.detailParam = NSMutableDictionary()
        monitor.detailParam?.removeAllObjects()
        monitor.detailParam?.addEntries(from: param as! [AnyHashable : Any])
        
        let dic = (param == nil) ? false : true
        monitor.callBack = callBack
        
        let comLabel:Bool?
        if (year ?? "").stringIsEmpty() || (comName ?? "").stringIsEmpty()
        {
            comLabel = true
        }
        else
        {
            comLabel = false
        }
        
        PTLaunchAdMonitor.showImageAt(onView: onView, timeInterval: timeInterval, year: year, comName: comName, dic: dic, comlabel: comLabel!, comNameFont: comNameFont, skipFont: skipFont)
    }
    
    class func showImageAt(onView:Any,timeInterval:TimeInterval,year:String?,comName:String?,dic:Bool,comlabel:Bool,comNameFont:UIFont?,skipFont:UIFont?)
    {
        var f = UIScreen.main.bounds
        let v = UIView()
        v.backgroundColor = .lightGray
        
        if onView is UIView
        {
            (onView as! UIView).addSubview(v)
            (onView as! UIView).bringSubviewToFront(v)
            v.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        else if onView is UIWindow
        {
            (onView as! UIWindow).addSubview(v)
            (onView as! UIWindow).bringSubviewToFront(v)
            v.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        f.size.height -= 50
        
        let device = UIDevice.current
        
        var bottomViewHeight:CGFloat? = 0
        
        if comlabel
        {
            bottomViewHeight = 0
        }
        else
        {
            switch device.orientation {
            case .landscapeLeft:
                bottomViewHeight = 50
            case .landscapeRight:
                bottomViewHeight = 50
            default:
                bottomViewHeight = 100
            }
        }
        
        var newFont :UIFont?
        
        if Gobal_device_info.isPad
        {
            let orientation = UIApplication.shared.statusBarOrientation
            switch orientation {
            case .landscapeLeft:
                newFont = skipFont != nil ? UIFont.init(name: skipFont!.familyName, size: skipFont!.pointSize/2.5) : UIFont.systemFont(ofSize: 16)
            case .landscapeRight:
                newFont = skipFont != nil ? UIFont.init(name: skipFont!.familyName, size: skipFont!.pointSize/2.5) : UIFont.systemFont(ofSize: 16)
            default:
                newFont = skipFont != nil ? skipFont! : UIFont.systemFont(ofSize: 16)
            }
        }
        else
        {
            switch device.orientation {
            case .landscapeLeft:
                newFont = skipFont != nil ? UIFont.init(name: skipFont!.familyName, size: skipFont!.pointSize/2.5) : UIFont.systemFont(ofSize: 16)
            case .landscapeRight:
                newFont = skipFont != nil ? UIFont.init(name: skipFont!.familyName, size: skipFont!.pointSize/2.5) : UIFont.systemFont(ofSize: 16)
            default:
                newFont = skipFont != nil ? skipFont! : UIFont.systemFont(ofSize: 16)
            }
        }
        
        if monitor.playMovie!
        {
            monitor.player = AVPlayerViewController()
            monitor.player?.player = AVPlayer.init(url: monitor.videoUrl!)
            monitor.player?.showsPlaybackControls = false
            if #available(iOS 11.0, *) {
                monitor.player?.entersFullScreenWhenPlaybackBegins = true
            }
            v.addSubview((monitor.player?.view)!)
            monitor.player?.view.snp.makeConstraints({ make in
                make.left.top.right.equalToSuperview()
                make.bottom.equalToSuperview().inset(bottomViewHeight!)
            })
            monitor.player?.player?.play()
            
            let imageBtn = UIButton.init(type: .custom)
            imageBtn.addActionHandlers { sender in
                PTLaunchAdMonitor.showDetail(sender: sender)
            }
            imageBtn.isUserInteractionEnabled = dic
            v.addSubview(imageBtn)
            imageBtn.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            let exit = UIButton.init(type: .custom)
            exit.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.2)
            exit.setTitleColor(.white, for: .normal)
            exit.titleLabel?.font = newFont
            exit.setTitle("跳过", for: .normal)
            exit.addActionHandlers { sender in
                PTLaunchAdMonitor.hideView(sender: sender)
            }
            exit.viewCorner(radius: 5)
            v.addSubview(exit)
            let w = skipFont!.pointSize * CGFloat((exit.titleLabel!.text! as NSString).length) + 10 * 2
            let h = skipFont!.pointSize * CGFloat((exit.titleLabel!.text! as NSString).length) + 10 * 2
            exit.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(10)
                make.top.equalToSuperview().inset(kStatusBarHeight)
                make.width.equalTo(w)
                make.height.equalTo(h)
            }
        }
        else
        {
            switch monitor.imageType {
            case .GIF:
                let source = CGImageSourceCreateWithData(monitor.imgData!, nil)
                let frameCount = CGImageSourceGetCount(source!)
                var frames = [UIImage]()
                for i in 0...frameCount
                {
                    let imageref = CGImageSourceCreateImageAtIndex(source!,i,nil)
                    let imageName = UIImage.init(cgImage: imageref!)
                    frames.append(imageName)
                }
                
                let imageView = UIImageView()
                imageView.animationImages = frames
                imageView.animationDuration = 1
                imageView.startAnimating()
                v.addSubview(imageView)
                imageView.snp.makeConstraints { make in
                    make.left.top.right.equalToSuperview()
                    make.height.equalTo(bottomViewHeight!)
                }
                
                let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(PTLaunchAdMonitor.showDetail(sender:)))
                imageView.addGestureRecognizer(tapGesture)
            default:
                let imageBtn = UIButton.init(type: .custom)
                if monitor.imgData != nil
                {
                    imageBtn.setImage(UIImage(data: monitor.imgData! as Data), for: .normal)
                }
                else
                {
                    imageBtn.setImage(UIColor.randomColor.createImageWithColor(), for: .normal)
                }
                imageBtn.addActionHandlers { sender in
                    PTLaunchAdMonitor.showDetail(sender: sender)
                }
                monitor.imgData?.length = 0
                imageBtn.isUserInteractionEnabled = dic
                v.addSubview(imageBtn)
                imageBtn.snp.makeConstraints { make in
                    make.left.top.right.equalToSuperview()
                    make.bottom.equalToSuperview().inset(bottomViewHeight!)
                }
                imageBtn.imageView?.contentMode = .scaleAspectFit
                imageBtn.adjustsImageWhenHighlighted = false
            }
            
            let exit = UIButton.init(type: .custom)
            exit.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.2)
            exit.setTitleColor(.white, for: .normal)
            exit.addActionHandlers { sender in
                PTLaunchAdMonitor.hideView(sender: sender)
            }
            exit.titleLabel!.textAlignment = .center
            exit.titleLabel!.numberOfLines = 0
            exit.titleLabel!.lineBreakMode = .byCharWrapping
            exit.titleLabel!.font = newFont
            v.addSubview(exit)
            exit.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(10)
                make.top.equalToSuperview().inset(kStatusBarHeight)
                make.width.height.equalTo(55)
            }
            exit.viewCorner(radius: 55/2)
            PTUtils.timeRunWithTime(timeInterval: timeInterval, sender: exit, originalTitle: "", canTap: true) {
                PTLaunchAdMonitor.hideView(sender: exit)
            }
            
            if !comlabel
            {
                let label = UILabel()
                label.backgroundColor = .white
                label.numberOfLines = 0
                label.lineBreakMode = .byCharWrapping
                label.font = comNameFont != nil ? comNameFont! : UIFont.systemFont(ofSize: 12)
                label.textColor = .black
                label.text = String.init(format:"Copyright (c) %@年 %@.\n All rights reserved.",year!,comName!)
                label.textAlignment = .center
                v.addSubview(label)
                label.snp.makeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                    make.height.equalTo(bottomViewHeight!)
                    
                }
            }
        }
    }
    
    public class func hideView(sender:Any)
    {
        let sup = (sender as! UIButton).superview
        sup?.isUserInteractionEnabled = false
        if monitor.callBack != nil
        {
            monitor.callBack!()
        }
        
        UIView.animate(withDuration: 0.25) {
            sup?.alpha = 0
        } completion: { finish in
            monitor.player?.player?.pause()
            sup?.removeFromSuperview()
        }
    }
    
    @objc class public func showDetail(sender:Any)
    {
        var sup:UIView?
        switch monitor.imageType {
        case .GIF:
            sup = (sender as! UIImageView).superview
        default:
            sup = (sender as! UIButton).superview
        }
        
        sup?.isUserInteractionEnabled = false
        
        if monitor.callBack != nil
        {
            monitor.callBack!()
        }
        
        UIView.animate(withDuration: 0.25) {
            sup?.alpha = 0
        } completion: { finish in
            sup?.removeFromSuperview()
            monitor.player?.player?.pause()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: PLaunchAdDetailDisplayNotification), object: monitor.detailParam!)
            monitor.detailParam?.removeAllObjects()
        }
    }
    
    func loadImageAtPath(path:NSArray)
    {
        let imageStr = path.firstObject
        if PTUtils.contentTypeForUrl(url: imageStr as! String) == PTUrlStringVideoType.MP4
        {
            playMovie = true
            imgLoaded = true
            videoUrl = ((imageStr as! NSString).range(of: "/var").length > 0 ) ? URL.init(fileURLWithPath: imageStr as! String) : URL.init(string: (imageStr as! NSString).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed))
        }
        else
        {
            playMovie = false
            if imageStr is String
            {
                loadImage(path: imageStr as! String)
            }
            else if imageStr is URL
            {
                loadImage(path:(imageStr as! URL).description)
            }
            else if imageStr is UIImage
            {
                imgData = NSMutableData()
                imgData?.append((imageStr as! UIImage).pngData()!)
                imgLoaded = true
            }
        }
    }
    
    func loadImage(path:String)
    {
        let url = URL.init(string: path)
        let request = URLRequest.init(url: url!)
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request) { data, response, error in
            
            let resp = response as? HTTPURLResponse
            if resp?.statusCode != 200
            {
                self.imgLoaded = true
                return
            }
            self.imgData = NSMutableData()
            self.imageType = data?.detectImageType()
            self.imgData?.append(data!)
            self.imgLoaded = true
        }
        dataTask.resume()
    }
}
