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
import SnapKit

public let PLaunchAdDetailDisplayNotification = "PShowLaunchAdDetailNotification"
public let PLaunchAdSkipNotification = "PLaunchAdSkipNotification"

/*
 启动页面
 */
@objcMembers
public class PTLaunchAdMonitor: NSObject {
    public static let shared = PTLaunchAdMonitor()
    public static let monitor : PTLaunchAdMonitor = PTLaunchAdMonitor.shared
    
    public var imageContentMode:UIView.ContentMode = .scaleAspectFill
    
    private var images:[UIImage]? = [UIImage]()
    private var playMovie:Bool?
    private var imgLoaded:Bool? = false
    private var videoUrl:URL?
    private var imgData:NSMutableData?
    private var imageType:PTAboutImageType?
    private var callBack:PTActionTask?
    private var player:AVPlayerViewController?
    private var detailParam:NSMutableDictionary?
    private var isTap:Bool = false
    //MARK: 初始化廣告界面
    ///初始化廣告界面
    /// - Parameters:
    ///   - path: 多媒體數據路徑URL
    ///   - onView: 展示在哪裏
    ///   - timeInterval: 展示時間
    ///   - param: 點擊標識
    ///   - year: 公司年份
    ///   - skipFont: 跳過字體
    ///   - comName: 公司名字
    ///   - comNameFont: 公司字體
    ///   - callBack: 回調
    public class func showAt(path:Any,
                             onView:Any,
                             timeInterval:TimeInterval,
                             param:NSDictionary?,
                             skipFont:UIFont?,
                             ltdString:String?,
                             comNameFont:UIFont,
                             callBack:PTActionTask?) {
        monitor.loadImageAtPath(path: path)
        while !monitor.imgLoaded! {
            RunLoop.current.run(mode: .default, before: Date.distantFuture)
        }
        
        monitor.detailParam = NSMutableDictionary()
        monitor.detailParam?.removeAllObjects()
        if param != nil {
            monitor.detailParam?.addEntries(from: param as! [AnyHashable : Any])
        }
        
        let dic = (param == nil) ? false : true
        monitor.callBack = callBack
        
        var comLabel: Bool
        if (ltdString ?? "").stringIsEmpty() {
            comLabel = true
        } else {
            comLabel = false
        }
        
        PTLaunchAdMonitor.showImageAt(onView: onView, timeInterval: timeInterval, ltdString: ltdString, dic: dic, comlabel: comLabel, comNameFont: comNameFont, skipFont: skipFont)
    }
    
    class func showImageAt(onView:Any,
                           timeInterval:TimeInterval,
                           ltdString:String?,
                           dic:Bool,
                           comlabel:Bool,
                           comNameFont:UIFont?,
                           skipFont:UIFont?) {
        var f = UIScreen.main.bounds
        let v = UIView()
        v.backgroundColor = .lightGray
        
        if onView is UIView {
            (onView as! UIView).addSubview(v)
            (onView as! UIView).bringSubviewToFront(v)
            v.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else if onView is UIWindow {
            let windows = (onView as! UIWindow)
            windows.addSubview(v)
            windows.bringSubviewToFront(v)
            v.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
#if POOTOOLS_DEBUG
            let share = LocalConsole.shared
            if share.isVisiable {
                windows.bringSubviewToFront(share.terminal!)
            }
#endif
        }
        
        f.size.height -= 50
        
        let device = UIDevice.current
        
        var bottomViewHeight:CGFloat? = 0
        
        if comlabel {
            bottomViewHeight = 0
        } else {
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
        
        if Gobal_device_info.isPad {
            var orientation:UIInterfaceOrientation = .unknown
            orientation = PTUtils.getCurrentVC().view.window!.windowScene!.interfaceOrientation
            
            switch orientation {
            case .landscapeLeft,.landscapeRight:
                newFont = skipFont != nil ? UIFont.init(name: skipFont!.familyName, size: skipFont!.pointSize/2.5) : UIFont.systemFont(ofSize: 16)
            default:
                newFont = skipFont != nil ? skipFont! : UIFont.systemFont(ofSize: 16)
            }
        } else {
            switch device.orientation {
            case .landscapeLeft,.landscapeRight:
                newFont = skipFont != nil ? UIFont.init(name: skipFont!.familyName, size: skipFont!.pointSize/2.5) : UIFont.systemFont(ofSize: 16)
            default:
                newFont = skipFont != nil ? skipFont! : UIFont.systemFont(ofSize: 16)
            }
        }
        
        if monitor.playMovie! {
            monitor.player = AVPlayerViewController()
            monitor.player?.player = AVPlayer.init(url: monitor.videoUrl!)
            monitor.player?.showsPlaybackControls = false
            monitor.player?.entersFullScreenWhenPlaybackBegins = true
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
            exit.setTitle("PT Button skip".localized(), for: .normal)
            exit.addActionHandlers { sender in
                PTLaunchAdMonitor.hideView(sender: sender)
            }
            exit.viewCorner(radius: 5)
            v.addSubview(exit)
            let w = skipFont!.pointSize * CGFloat((exit.titleLabel!.text! as NSString).length) + 10 * 2
            let h = skipFont!.pointSize * CGFloat((exit.titleLabel!.text! as NSString).length) + 10 * 2
            exit.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(10)
                make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
                make.width.equalTo(w)
                make.height.equalTo(h)
            }
        } else {
            
            if (monitor.images?.count ?? 0) > 1 {
                let imageView = UIImageView()
                imageView.animationImages = monitor.images!
                imageView.animationDuration = 1
                imageView.startAnimating()
                v.addSubview(imageView)
                imageView.snp.makeConstraints { make in
                    make.left.top.right.equalToSuperview()
                    make.height.equalTo(bottomViewHeight!)
                }
                
                let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(PTLaunchAdMonitor.showDetail(sender:)))
                imageView.addGestureRecognizer(tapGesture)
            } else if (monitor.images?.count ?? 0) == 1 {
                let imageBtn = UIButton.init(type: .custom)
                imageBtn.setImage(monitor.images!.first, for: .normal)
                imageBtn.addActionHandlers { sender in
                    PTLaunchAdMonitor.showDetail(sender: sender)
                }
                imageBtn.isUserInteractionEnabled = dic
                v.addSubview(imageBtn)
                imageBtn.snp.makeConstraints { make in
                    make.left.top.right.equalToSuperview()
                    make.bottom.equalToSuperview().inset(bottomViewHeight!)
                }
                imageBtn.imageView?.clipsToBounds = true
                imageBtn.imageView?.contentMode = PTLaunchAdMonitor.shared.imageContentMode
                imageBtn.adjustsImageWhenHighlighted = false
            }
            
            let exit = UIButton.init(type: .custom)
            exit.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.2)
            exit.setTitleColor(.white, for: .normal)
            exit.addActionHandlers { sender in
                monitor.isTap = true
                PTLaunchAdMonitor.hideView(sender: sender)
            }
            exit.titleLabel!.textAlignment = .center
            exit.titleLabel!.numberOfLines = 0
            exit.titleLabel!.lineBreakMode = .byCharWrapping
            exit.titleLabel!.font = newFont
            exit.isUserInteractionEnabled = true
            v.addSubview(exit)
            v.bringSubviewToFront(exit)
            exit.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(10)
                make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
                make.width.height.equalTo(55)
            }
            exit.viewCorner(radius: 55/2)
            exit.buttonTimeRun(timeInterval: timeInterval, originalTitle: "") {
                if !monitor.isTap {
                    PTLaunchAdMonitor.hideView(sender: exit)
                } else {
                    monitor.isTap = false
                }
            }
            
            if !comlabel {
                let label = UILabel()
                label.backgroundColor = .white
                label.numberOfLines = 0
                label.lineBreakMode = .byCharWrapping
                label.font = comNameFont != nil ? comNameFont! : UIFont.systemFont(ofSize: 12)
                label.textColor = .black
                label.text = ltdString
                label.textAlignment = .center
                v.addSubview(label)
                label.snp.makeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                    make.height.equalTo(bottomViewHeight!)
                    
                }
            }
        }
    }
    
    @objc fileprivate class func hideView(sender:UIButton) {
        let sup = sender.superview
        sup?.isUserInteractionEnabled = false
        if monitor.callBack != nil {
            monitor.callBack!()
        }
        
        UIView.animate(withDuration: 0.25) {
            sup?.alpha = 0
        } completion: { finish in
            monitor.player?.player?.pause()
            sup?.removeFromSuperview()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: PLaunchAdSkipNotification), object:nil)
        }
    }
    
    @objc fileprivate class func showDetail(sender:Any) {
        monitor.isTap = true
        var sup:UIView?
        switch monitor.imageType {
        case .GIF:
            sup = (sender as! UIImageView).superview
        default:
            sup = (sender as! UIButton).superview
        }
        
        sup?.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.25) {
            sup?.alpha = 0
        } completion: { finish in
            sup?.removeFromSuperview()
            monitor.player?.player?.pause()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: PLaunchAdDetailDisplayNotification), object: monitor.detailParam!)
            monitor.detailParam?.removeAllObjects()
        }
    }
    
    func loadImageAtPath(path:Any) {
        if path is String {
            let imagePath = (path as! String)
            if imagePath.contentTypeForUrl() == PTUrlStringVideoType.MP4 {
                playMovie = true
                imgLoaded = true
                videoUrl = ((imagePath as NSString).range(of: "/var").length > 0 ) ? URL.init(fileURLWithPath: imagePath) : URL.init(string: (imagePath as NSString).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed))
            } else {
                playMovie = false
                
                Task {
                    let result = await PTLoadImageFunction.loadImage(contentData: path as Any)
                    self.imgLoaded = true
                    self.images = result.0
                }
            }
        } else {
            playMovie = false
            
            Task {
                let result = await PTLoadImageFunction.loadImage(contentData: path as Any)
                self.imgLoaded = true
                self.images = result.0
            }
        }
    }
}
