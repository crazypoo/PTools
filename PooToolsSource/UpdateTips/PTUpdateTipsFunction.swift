//
//  PTUpdateTipsFunction.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/3/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

public let uAppNoMoreShowUpdate = "AppNoMoreShowUpdate"

public class PTUpdateTipsFunction: NSObject {
    
    static let share = PTUpdateTipsFunction()
    
    //MARK: 初始化UpdateTips
    ///初始化UpdateTips
    /// - Parameters:
    ///   - oV: 舊版本號
    ///   - nV: 新版本號
    ///   - descriptionString: 更新信息
    ///   - url: 下載URL
    ///   - test: 是否測試
    ///   - isShowError: 是否顯示錯誤
    ///   - isForcedUpgrade: 是否強制升級
    public func showUpdateTips(oldVersion oV: String,
                               newVersion nV: String,
                               description descriptionString: String,
                               downloadUrl url: URL,
                               isTest test:Bool = false,
                               showError isShowError:Bool = true,
                               forcedUpgrade isForcedUpgrade:Bool = false) {
        let cancelTitle:String = isForcedUpgrade ? "" : NSLocalizedString("取消升级", comment: "")
        gobalTips(tipsTitle: NSLocalizedString("发现新版本", comment: ""), cancelTitle: cancelTitle, cancelBlock: { maskVC in
            if test {
                if isShowError {
                    maskVC.dismiss(animated: true, completion: nil)
                } else {
                    UserDefaults.standard.set(1, forKey: uAppNoMoreShowUpdate)
                    maskVC.dismiss(animated: true, completion: nil)
                }
            } else {
                maskVC.dismiss(animated: true, completion: nil)
            }

        }, doneTitle: NSLocalizedString("升级", comment: "")) { maskVC in
            let realURL:URL = (url.scheme ?? "").stringIsEmpty() ? URL.init(string: "https://" + url.description)! : url
            UIApplication.shared.open(realURL, options: .init(), completionHandler: nil)
            maskVC.dismiss(animated: true, completion: nil)

        } tipContentView: { contentVC,maskVC in
            let nameArr = [NSLocalizedString("当前版本", comment: ""), NSLocalizedString("新版本", comment: ""), NSLocalizedString("版本信息", comment: "")]
            let valueArr = [oV, nV, descriptionString]
            for index in 0...nameArr.count - 2 {
                let nameLabel = UILabel()
                nameLabel.text = nameArr[index]
                nameLabel.font = .appfont(size: 14)
                nameLabel.textColor = .black
                nameLabel.textAlignment = .right
                nameLabel.numberOfLines = 0
                nameLabel.backgroundColor = .clear
                
                let valueLabel = UILabel()
                valueLabel.text = valueArr[index]
                valueLabel.font = .appfont(size: 14)
                valueLabel.textColor = .black
                valueLabel.textAlignment = .left
                valueLabel.numberOfLines = 0
                valueLabel.backgroundColor = .clear
                let tempHeight = 35
                let height = CGFloat(tempHeight) * CGFloat(index) + CGFloat(index) * 10
                
                contentVC.addSubview(valueLabel)
                valueLabel.snp.makeConstraints { (make) in
                    make.right.equalTo(contentVC.snp.right)
                    make.top.equalTo(contentVC.snp.top).offset(height)
                    make.size.equalTo(CGSize(width: 200, height:tempHeight))
                }
                
                contentVC.addSubview(nameLabel)
                nameLabel.snp.makeConstraints { (make) in
                    make.right.equalTo(valueLabel.snp.left).offset(-15)
                    make.left.equalTo(contentVC.snp.left)
                    make.top.equalTo(contentVC.snp.top).offset(height)
                    make.height.equalTo(tempHeight)
                }
            }
            
            let scrollView = UIScrollView()
            scrollView.contentSize = CGSize(width: 200, height: 65)
            contentVC.addSubview(scrollView)
            scrollView.snp.makeConstraints { (make) in
                make.right.equalTo(contentVC.snp.right)
                make.top.equalTo(contentVC.snp.top).offset(90)
                make.size.equalTo(CGSize(width: 200, height: 65))
            }
                        
            let tmpHight = UIView.sizeFor(string: descriptionString, font: .appfont(size: 14), height: CGFloat(MAXFLOAT), width: CGFloat(200)).height
            
            let valueLabel = UILabel()
            valueLabel.text = descriptionString
            valueLabel.font = .appfont(size: 14)
            valueLabel.textColor = .black
            valueLabel.textAlignment = .left
            valueLabel.backgroundColor = .clear
            valueLabel.numberOfLines = 0
            scrollView.addSubview(valueLabel)
            valueLabel.snp.makeConstraints { (make) in
                make.top.equalTo(scrollView.snp.top).offset(10)
                make.left.equalTo(scrollView.snp.left)
                make.size.equalTo(CGSize(width: 200, height: tmpHight))
            }
            
            scrollView.contentSize = CGSize(width: 200, height: tmpHight + 10)
            
            let nameLabel = UILabel()
            nameLabel.text = nameArr.last
            nameLabel.font = .appfont(size: 14)
            nameLabel.textColor = .black
            nameLabel.textAlignment = .right
            nameLabel.backgroundColor = .clear
            nameLabel.numberOfLines = 0
            contentVC.addSubview(nameLabel)
            nameLabel.snp.makeConstraints { (make) in
                make.right.equalTo(scrollView.snp.left).offset(-15)
                make.left.equalTo(contentVC.snp.left)
                make.top.equalTo(scrollView.snp.top)
                make.height.equalTo(35)
            }
        }
    }
    
    fileprivate func gobalTips(tipsTitle:String? = "",
                               cancelTitle:String = "",
                               cancelBlock: ((_ currentVC:PTBaseViewController)->Void)?,
                               doneTitle:String,
                               doneBlock: ((_ currentVC:PTBaseViewController)->Void)?,
                               tipContentView:((_ contentView:UIView,_ currentVC:PTBaseViewController)->Void)?) {
        let maskVC = PTBaseViewController()
        maskVC.modalPresentationStyle = .fullScreen
        maskVC.view.backgroundColor = .init(white: 0, alpha: 0.5)
        let whiteView = UIView()
        whiteView.backgroundColor = .white
        whiteView.viewCorner(radius: 10)
        
        let titleLabel = UILabel()
        titleLabel.text = tipsTitle
        titleLabel.font = .appfont(size: 18)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.backgroundColor = .clear
        
        let bgView = UIView()
        bgView.backgroundColor = .clear
        
        maskVC.view.addSubview(whiteView)
        whiteView.snp.makeConstraints { (make) in
            make.center.equalTo(maskVC.view)
            make.size.equalTo(CGSize(width: 335, height: 278))
        }
        
        whiteView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(whiteView)
            make.top.equalTo(whiteView.snp.top).offset(20)
            make.right.equalTo(whiteView.snp.right).offset(-15)
        }
        let hasCancel:Bool = cancelTitle.count > 0
        if hasCancel {
            let closeBtn = UIButton(type: .custom)
            closeBtn.setTitle(cancelTitle, for: .normal)
            closeBtn.titleLabel?.font = .appfont(size: 14)
            closeBtn.backgroundColor = .clear
            closeBtn.setTitleColor(.black, for: .normal)
            closeBtn.viewCorner(radius: 5,borderWidth: 1,borderColor: .black)
            closeBtn.addActionHandlers { sender in
                if cancelBlock != nil {
                    cancelBlock!(maskVC)
                }
            }
            
            whiteView.addSubview(closeBtn)
            closeBtn.snp.makeConstraints { (make) in
                make.size.equalTo(CGSize(width: 100, height: 40))
                make.bottom.equalToSuperview().inset(10)
                make.right.equalTo(whiteView.snp.centerX).offset(-10)
            }
        }
        
        let downLoadBtn = UIButton(type: .custom)
        downLoadBtn.setTitle(doneTitle, for: .normal)
        downLoadBtn.titleLabel?.font = .appfont(size: 14)
        downLoadBtn.backgroundColor = .red
        downLoadBtn.setTitleColor(.white, for: .normal)
        downLoadBtn.viewCorner(radius: 5)
        downLoadBtn.addActionHandlers { (sneder) in
            if doneBlock != nil {
                doneBlock!(maskVC)
            }
        }

        whiteView.addSubview(downLoadBtn)
        downLoadBtn.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().inset(10)
            if hasCancel {
                make.left.equalTo(whiteView.snp.centerX).offset(10)
                make.size.equalTo(CGSize(width: 100, height: 40))
            } else {
                make.centerX.equalToSuperview()
                make.size.equalTo(CGSize(width: 210, height: 40))
            }
        }
        
        whiteView.addSubview(bgView)
        bgView.snp.makeConstraints { (make) in
            make.left.equalTo(whiteView.snp.left).offset(15)
            make.right.equalTo(whiteView).offset(-15)
            make.bottom.equalTo(downLoadBtn.snp.top).offset(-10)
            make.top.equalTo(titleLabel.snp.bottom).offset(15)
        }

        if tipContentView != nil {
            tipContentView!(bgView,maskVC)
        }
        PTUtils.getCurrentVC().present(maskVC, animated: true, completion: nil)
    }
}
