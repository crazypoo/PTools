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
import SwifterSwift

public let PLaunchAdDetailDisplayNotification = "PShowLaunchAdDetailNotification"
public let PLaunchAdSkipNotification = "PLaunchAdSkipNotification"

/*
 启动页面
 */
@objcMembers
public class PTLaunchAdMonitor: NSObject {
    public static let share = PTLaunchAdMonitor()
    public var imageContentMode:UIView.ContentMode = .scaleAspectFill
    
    public var skipName:String = "Skip"
    private var dismissCallBack:PTActionTask?
    private var timeUpCallBack:PTActionTask?
    private var player:AVPlayerViewController?
    private lazy var skipButton:UIButton = {
        let view = UIButton()
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        view.setTitleColor(.white, for: .normal)
        view.setBackgroundColor(color: .DevMaskColor, forState: .normal)
        return view
    }()
    
    private lazy var loadImageView:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private var notifiData:[AnyHashable : Any]?
    
    private lazy var contentView : UIView = {
        let view = UIView()
        return view
    }()
    //MARK: 初始化廣告界面
    ///初始化廣告界面
    /// - Parameters:
    ///   - path: 多媒體數據
    ///   - onView: 展示在哪裏
    ///   - timeInterval: 展示時間
    ///   - param: 點擊標識
    ///   - skipFont: 跳過字體
    ///   - ltdString: 公司年份
    ///   - comNameFont: 公司字體
    ///   - callBack: 回調
    @MainActor public func showAd(path:Any,
                                  onView:Any,
                                  @PTClampedProperyWrapper(range:3...15) timeInterval:TimeInterval = 5,
                                  param:[AnyHashable : Any]?,
                                  skipFont:UIFont = .appfont(size: 16),
                                  ltdString:String = "",
                                  comNameFont:UIFont = .appfont(size: 12),
                                  callBack:PTActionTask? = nil,
                                  timeUp:PTActionTask? = nil) {
        dismissCallBack = callBack
        timeUpCallBack = timeUp
        notifiData = param
        contentView.backgroundColor = .lightGray
                        
        if onView is UIView {
            (onView as! UIView).addSubview(contentView)
            (onView as! UIView).bringSubviewToFront(contentView)
            contentView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else if onView is UIWindow {
            let windows = (onView as! UIWindow)
            windows.addSubview(contentView)
            windows.bringSubviewToFront(contentView)
            contentView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
#if POOTOOLS_DEBUG
            let share = LocalConsole.shared
            if share.isVisiable {
                windows.bringSubviewToFront(share.terminal!)
            }
#endif
        }
        skipButton.setTitle(skipName, for: .normal)
        skipButton.titleLabel?.font = skipFont
        skipButton.addActionHandlers { sender in
            self.hideView(sender: sender)
        }
        
        let comLabel: Bool = ltdString.stringIsEmpty() ? false : true
        let device = UIDevice.current
        var bottomViewHeight:CGFloat = 0
        if !comLabel {
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
        if comLabel {
            let label = UILabel()
            label.backgroundColor = .white
            label.numberOfLines = 0
            label.lineBreakMode = .byCharWrapping
            label.font = comNameFont
            label.textColor = .black
            label.text = ltdString
            label.textAlignment = .center
            contentView.addSubview(label)
            label.snp.makeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(bottomViewHeight)
            }
        }

        contentView.addSubviews([loadImageView,skipButton])
        loadImageView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(bottomViewHeight)
        }
        skipButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.right.equalToSuperview().inset(10)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
        }
        
        PTGCDManager.gcdMain(block: {
            self.skipButton.viewCorner(radius: 22)
        })
        
        let mediaHaveData: Bool = param != nil
        loadImageAtPath(path: path) { type, media in
            PTGCDManager.gcdMain {
                switch type {
                case .Image:
                    if let medias = media as? [UIImage] {
                        if medias.count > 1 {
                            self.loadImageView.animationImages = medias
                            self.loadImageView.animationImages = medias
                            self.loadImageView.animationDuration = 1
                            self.loadImageView.startAnimating()
                            self.contentView.insertSubview(self.loadImageView, at: 0)
                            self.loadImageView.snp.remakeConstraints { make in
                                make.left.top.right.equalToSuperview()
                                make.height.equalTo(bottomViewHeight)
                            }
                            
                            let tag = UITapGestureRecognizer { sender in
                                self.showDetail(sender: self.loadImageView)
                            }
                            self.loadImageView.addGestureRecognizer(tag)
                        } else if medias.count == 1 {
                            self.loadImageView.image = medias.first
                            let tag = UITapGestureRecognizer { sender in
                                self.showDetail(sender: self.loadImageView)
                            }
                            self.loadImageView.addGestureRecognizer(tag)
                            self.loadImageView.isUserInteractionEnabled = mediaHaveData
                            self.contentView.insertSubview(self.loadImageView, at: 0)
                            self.loadImageView.snp.remakeConstraints { make in
                                make.left.top.right.equalToSuperview()
                                make.bottom.equalToSuperview().inset(bottomViewHeight)
                            }
                            self.loadImageView.contentMode = PTLaunchAdMonitor.share.imageContentMode
                        }
                    }
                    self.skipButton.setTitle("\(timeInterval)", for: .normal)
                    let buttonWidth = self.skipButton.sizeFor().width + 15
                    self.skipButton.snp.remakeConstraints { make in
                        make.right.equalToSuperview().inset(10)
                        make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
                        make.size.equalTo(buttonWidth)
                    }
                    self.skipButton.viewCorner(radius: buttonWidth / 2)
                    PTGCDManager.gcdMain {
                        self.skipButton.buttonTimeRun(timeInterval: timeInterval, originalTitle: "",timeFinish: {
                            self.hideView()
                        })
                    }
                case .Video:
                    self.loadImageView.removeFromSuperview()
                    if let videoUrl = media as? URL {
                        self.player = AVPlayerViewController()
                        self.player?.player = AVPlayer(url: videoUrl)
                        self.player?.showsPlaybackControls = false
                        self.player?.entersFullScreenWhenPlaybackBegins = true
                        self.contentView.insertSubview((self.player?.view)!, at: 0)
                        self.player?.view.snp.makeConstraints({ make in
                            make.left.top.right.equalToSuperview()
                            make.bottom.equalToSuperview().inset(bottomViewHeight)
                        })
                        self.player?.player?.play()
                    }
                    
                    let imageBtn = UIButton(type: .custom)
                    imageBtn.addActionHandlers { sender in
                        self.showDetail(sender: sender)
                    }
                    imageBtn.isUserInteractionEnabled = mediaHaveData
                    self.contentView.addSubview(imageBtn)
                    imageBtn.snp.makeConstraints { make in
                        make.left.top.right.equalToSuperview()
                        make.bottom.equalToSuperview().inset(bottomViewHeight)
                    }
                    
                    self.skipButton.setTitle(self.skipName, for: .normal)
                    let buttonWidth = self.skipButton.sizeFor().width + 15
                    self.skipButton.snp.remakeConstraints { make in
                        make.right.equalToSuperview().inset(10)
                        make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
                        make.size.equalTo(buttonWidth)
                    }
                    self.skipButton.viewCorner(radius: buttonWidth / 2)
                }
            }
        }
    }
    
    enum PTLaunchAdMediaType {
        case Image,Video
    }
    
    private func loadImageAtPath(path: Any, completion: @escaping (PTLaunchAdMediaType,Any?) -> Void) {
        Task {
            if let imagePath = path as? String,imagePath.contentTypeForUrl() == PTUrlStringVideoType.MP4 {
                let videoUrl = (imagePath as NSString).range(of: "/var").length > 0 ? URL(fileURLWithPath: imagePath) : URL(string: imagePath)
                completion(.Video,videoUrl)
            } else {
                let result = await PTLoadImageFunction.loadImage(contentData: path)
                completion(.Image,result.0)
            }
        }
    }

    @MainActor fileprivate func hideView(sender:UIButton? = nil) {
        if let sup = sender?.superview {
            sup.isUserInteractionEnabled = false
            
            UIView.animate(withDuration: 0.25) {
                sup.alpha = 0
            } completion: { finish in
                self.player?.player?.pause()
                sup.removeFromSuperview()
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: PLaunchAdSkipNotification), object:nil)
                self.skipButton.cancelCountdown()
                self.dismissCallBack?()
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                self.contentView.alpha = 0
            } completion: { finish in
                self.player?.player?.pause()
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: PLaunchAdSkipNotification), object:nil)
                self.contentView.removeFromSuperview()
                self.timeUpCallBack?()
            }
        }
    }
    
    fileprivate func showDetail(sender:UIView) {
        let sup = sender.superview
        sup?.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.25) {
            sup?.alpha = 0
        } completion: { finish in
            sup?.removeFromSuperview()
            self.player?.player?.pause()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: PLaunchAdDetailDisplayNotification), object: self.notifiData)
        }
    }
}
