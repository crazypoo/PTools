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
    
    private var dismissCallBack:PTActionTask?
    private var player:AVPlayerViewController?
    private lazy var skipButton:UIButton = {
        let view = UIButton()
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        view.setTitleColor(.white, for: .normal)
        return view
    }()
    private var notifiData:[AnyHashable : Any]?
    
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
                                  callBack:PTActionTask? = nil) {
        dismissCallBack = callBack
        notifiData = param
        let v = UIView()
        v.backgroundColor = .lightGray
        
        let loadImageView = UIImageView(image: PTAppBaseConfig.share.defaultPlaceholderImage)
        loadImageView.contentMode = .scaleAspectFit
        
        let loadingSkip = UIButton(type: .custom)
        loadingSkip.setTitle("Skip", for: .normal)
        loadingSkip.setTitleColor(.white, for: .normal)
        loadingSkip.setBackgroundColor(color: .DevMaskColor, forState: .normal)
        loadingSkip.addActionHandlers(handler: { sender in
            self.hideView(sender: sender)
        })
        
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
        
        skipButton.titleLabel?.font = skipFont
        v.addSubview(skipButton)
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
            v.addSubview(label)
            label.snp.makeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(bottomViewHeight)
            }
        }

        v.addSubviews([loadImageView,loadingSkip])
        loadImageView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(bottomViewHeight)
        }
        skipButton.isHidden = true
        loadingSkip.titleLabel?.font = skipFont
        loadingSkip.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.right.equalToSuperview().inset(10)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight())
        }
        
        PTGCDManager.gcdMain(block: {
            loadingSkip.viewCorner(radius: 22)
        })
        
        let mediaHaveData: Bool = param != nil
        loadImageAtPath(path: path) { type, media in
            PTGCDManager.gcdMain {
                loadingSkip.removeFromSuperview()
                loadImageView.removeFromSuperview()
                self.skipButton.isHidden = false
                switch type {
                case .Image:
                    if let medias = media as? [UIImage] {
                        if medias.count > 1 {
                            let imageView = UIImageView()
                            imageView.animationImages = medias
                            imageView.animationDuration = 1
                            imageView.startAnimating()
                            v.insertSubview(imageView, at: 0)
                            imageView.snp.makeConstraints { make in
                                make.left.top.right.equalToSuperview()
                                make.height.equalTo(bottomViewHeight)
                            }
                            
                            let tag = UITapGestureRecognizer { sender in
                                self.showDetail(sender: imageView)
                            }
                            imageView.addGestureRecognizer(tag)
                        } else if medias.count == 1 {
                            let imageBtn = UIButton(type: .custom)
                            imageBtn.setImage(medias.first, for: .normal)
                            imageBtn.addActionHandlers { sender in
                                self.showDetail(sender: sender)
                            }
                            imageBtn.isUserInteractionEnabled = mediaHaveData
                            v.insertSubview(imageBtn, at: 0)
                            imageBtn.snp.makeConstraints { make in
                                make.left.top.right.equalToSuperview()
                                make.bottom.equalToSuperview().inset(bottomViewHeight)
                            }
                            imageBtn.imageView?.clipsToBounds = true
                            imageBtn.imageView?.contentMode = PTLaunchAdMonitor.share.imageContentMode
                            imageBtn.adjustsImageWhenHighlighted = false
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
                            self.hideView(sender: self.skipButton)
                        })
                    }
                case .Video:
                    if let videoUrl = media as? URL {
                        self.player = AVPlayerViewController()
                        self.player?.player = AVPlayer(url: videoUrl)
                        self.player?.showsPlaybackControls = false
                        self.player?.entersFullScreenWhenPlaybackBegins = true
                        v.insertSubview((self.player?.view)!, at: 0)
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
                    v.addSubview(imageBtn)
                    imageBtn.snp.makeConstraints { make in
                        make.left.top.right.equalToSuperview()
                        make.bottom.equalToSuperview().inset(bottomViewHeight)
                    }
                    
                    self.skipButton.setTitle("PT Button skip".localized(), for: .normal)
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
        case Image
        case Video
    }
    
    private func loadImageAtPath(path: Any, completion: @escaping (PTLaunchAdMediaType,Any?) -> Void) {
        if let imagePath = path as? String {
            if imagePath.contentTypeForUrl() == PTUrlStringVideoType.MP4 {
                let videoUrl = (imagePath as NSString).range(of: "/var").length > 0 ? URL(fileURLWithPath: imagePath) : URL(string: imagePath.urlToUnicodeURLString() ?? "")
                completion(.Video,videoUrl)
            } else {
                Task {
                    let result = await PTLoadImageFunction.loadImage(contentData: path)
                    completion(.Image,result.0)
                }
            }
        } else {
            Task {
                let result = await PTLoadImageFunction.loadImage(contentData: path)
                completion(.Image,result.0)
            }
        }
    }

    @MainActor fileprivate func hideView(sender:UIButton) {
        let sup = sender.superview
        sup?.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.25) {
            sup?.alpha = 0
        } completion: { finish in
            self.player?.player?.pause()
            sup?.removeFromSuperview()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: PLaunchAdSkipNotification), object:nil)
            self.dismissCallBack?()
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
