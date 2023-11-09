//
//  PTUpdateTipsViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 31/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import AttributedString

class PTUpdateTipsContentView : UIView {
    init(oV:String,nV:String,descriptionString:String) {
        super.init(frame: .zero)
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
            
            addSubview(valueLabel)
            valueLabel.snp.makeConstraints { (make) in
                make.right.equalTo(self.snp.right)
                make.top.equalTo(self.snp.top).offset(height)
                make.size.equalTo(CGSize(width: 200, height:tempHeight))
            }
            
            addSubview(nameLabel)
            nameLabel.snp.makeConstraints { (make) in
                make.right.equalTo(valueLabel.snp.left).offset(-15)
                make.left.equalTo(self.snp.left)
                make.top.equalTo(self.snp.top).offset(height)
                make.height.equalTo(tempHeight)
            }
        }
        
        let baseContentSize = CGSize(width: 200, height: 65)
        
        let scrollView = UIScrollView()
        scrollView.contentSize = baseContentSize
        addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.right.equalTo(self.snp.right)
            make.top.equalTo(self.snp.top).offset(90)
            make.width.equalTo(baseContentSize.width)
            make.bottom.equalToSuperview()
        }
                                
        let tmpHight = UIView.sizeFor(string: descriptionString, font: .appfont(size: 14),lineSpacing: 2, width: baseContentSize.width).height
        
        let valueLabel = UILabel()
        valueLabel.numberOfLines = 0
        scrollView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { (make) in
            make.top.equalTo(scrollView.snp.top)
            make.left.equalTo(scrollView.snp.left)
            make.size.equalTo(CGSize(width: baseContentSize.width, height: tmpHight))
        }
        
        let att:ASAttributedString = """
        \(wrap: .embedding("""
        \(descriptionString,.foreground(.black),.font(.appfont(size: 14)),.paragraph(.alignment(.left)),.baselineOffset(2))
        """))
        """
        valueLabel.attributed.text = att
        
        scrollView.contentSize = CGSize(width: baseContentSize.width, height: tmpHight + 10)
                
        let contentLine = descriptionString.numberOfLines(font: .appfont(size: 14), labelShowWidth: baseContentSize.width, lineSpacing: 2)
        scrollView.isScrollEnabled = contentLine > 4
        scrollView.contentOffset = CGPoint(x: 0, y: (contentLine > 1 ? -15 : 0))

        let nameLabel = UILabel()
        nameLabel.text = nameArr.last
        nameLabel.font = .appfont(size: 14)
        nameLabel.textColor = .black
        nameLabel.textAlignment = .right
        nameLabel.backgroundColor = .clear
        nameLabel.numberOfLines = 0
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.right.equalTo(scrollView.snp.left).offset(-15)
            make.left.equalTo(self.snp.left)
            make.top.equalTo(scrollView.snp.top)
            make.height.equalTo(35)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PTUpdateTipsViewController: PTBaseViewController {

    var doneTask:PTActionTask!
    var cancelTask:PTActionTask!

    lazy var whiteView : UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.viewCorner(radius: 10)
        return view
    }()
    
    lazy var contentView : UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var titleLabel : UILabel = {
        let view = UILabel()
        view.text = titleString
        view.font = .appfont(size: 18)
        view.textColor = .black
        view.textAlignment = .center
        view.numberOfLines = 0
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var closeButton : UIButton = {
        let view = UIButton(type: .custom)
        view.setTitle(cancelTitle, for: .normal)
        view.titleLabel?.font = .appfont(size: 14,bold: true)
        view.backgroundColor = .clear
        view.setTitleColor(.black, for: .normal)
        view.viewCorner(radius: 5,borderWidth: 1,borderColor: .black)
        view.addActionHandlers { sender in
            self.dismiss(animated: true) {
                self.cancelTask()
            }
        }
        return view
    }()
    
    lazy var downLoadButton : UIButton = {
        let view = UIButton(type: .custom)
        view.setTitle(doneTitle, for: .normal)
        view.titleLabel?.font = .appfont(size: 14,bold: true)
        view.backgroundColor = .red
        view.setTitleColor(.white, for: .normal)
        view.viewCorner(radius: 5)
        view.addActionHandlers { sender in
            self.dismiss(animated: true) {
                self.doneTask()
            }
        }
        return view
    }()

    
    private var cancelTitle:String? = ""
    private var doneTitle:String!
    private var titleString:String? = ""

    init(titleString:String? = "",cancelTitle:String? = "",doneTitle:String) {
        super.init(nibName: nil, bundle: nil)
        self.titleString = titleString
        self.cancelTitle = cancelTitle
        self.doneTitle = doneTitle
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .clear
        // Do any additional setup after loading the view.
        self.view.addSubview(whiteView)
        whiteView.snp.makeConstraints { (make) in
            make.center.equalTo(view)
            make.size.equalTo(CGSize(width: 335, height: 278))
        }
        
        createAlert()
    }
    
    func createAlert() {
        whiteView.addSubviews([downLoadButton,contentView])
        
        if !(titleString ?? "").stringIsEmpty() {
            whiteView.addSubviews([titleLabel])
            titleLabel.snp.makeConstraints { (make) in
                make.centerX.equalTo(whiteView)
                make.top.equalTo(whiteView.snp.top).offset(10)
                make.right.equalTo(whiteView.snp.right).offset(-15)
                make.height.equalTo(titleLabel.font.pointSize + 5)
            }
        }
        
        let hasCancel:Bool = !(cancelTitle ?? "").stringIsEmpty()
        
        if hasCancel {
            whiteView.addSubview(closeButton)
            closeButton.snp.makeConstraints { (make) in
                make.size.equalTo(CGSize(width: 100, height: 40))
                make.bottom.equalToSuperview().inset(10)
                make.right.equalTo(whiteView.snp.centerX).offset(-10)
            }
        }
        
        downLoadButton.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().inset(10)
            if hasCancel {
                make.left.equalTo(whiteView.snp.centerX).offset(10)
                make.size.equalTo(CGSize(width: 100, height: 40))
            } else {
                make.centerX.equalToSuperview()
                make.size.equalTo(CGSize(width: 210, height: 40))
            }
        }
        
        contentView.snp.makeConstraints { (make) in
            make.left.equalTo(whiteView.snp.left).offset(15)
            make.right.equalTo(whiteView).offset(-15)
            make.bottom.equalTo(downLoadButton.snp.top).offset(-10)
            if !(titleString ?? "").stringIsEmpty() {
                make.top.equalTo(titleLabel.snp.bottom).offset(15)
            } else {
                make.top.equalToSuperview().inset(15)
            }
        }
    }
}
