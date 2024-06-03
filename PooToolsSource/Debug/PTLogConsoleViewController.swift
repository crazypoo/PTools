//
//  PTLogConsoleViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/6/3.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif
import SafeSFSymbols
import AttributedString

class PTLogConsoleViewController: PTBaseViewController {

    lazy var fakeNav:UIView = {
        let view = UIView()
        return view
    }()

    lazy var valueSwitch:PTSwitch = {
        let view = PTSwitch()
        view.isOn = PTCoreUserDefultsWrapper.PTLogWrite
        view.valueChangeCallBack = { value in
            PTCoreUserDefultsWrapper.PTLogWrite = value
        }
        return view
    }()
    
    lazy var infoLabel:UITextView = {
        let view = UITextView()
        view.isEditable = false
        return view
    }()
    
    var filePath:String {
        get {
            let cachePath = FileManager.pt.CachesDirectory()
            let logURL = cachePath + "/log.txt"
            return logURL
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_hideBaseNavBar = true
#else
        navigationController?.navigationBar.isHidden = true
#endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubviews([fakeNav,infoLabel])
        fakeNav.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(20)
            make.height.equalTo(CGFloat.kNavBarHeight)
        }
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(.arrow.uturnLeftCircle), for: .normal)
        
        let refreshButton = UIButton(type: .custom)
        refreshButton.setImage(UIImage(.arrow.clockwise), for: .normal)

        let clearButton = UIButton(type: .custom)
        clearButton.setImage(UIImage(.paintbrush), for: .normal)

        fakeNav.addSubviews([button,valueSwitch,refreshButton,clearButton])
        button.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.top.equalToSuperview().inset(5)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        button.addActionHandlers { sender in
            self.dismissAnimated()
        }
                        
        valueSwitch.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.centerY.equalTo(button)
            make.width.equalTo(51)
            make.height.equalTo(31)
        }
        
        refreshButton.snp.makeConstraints { make in
            make.size.centerY.equalTo(button)
            make.right.equalTo(valueSwitch.snp.left).offset(-7.5)
        }
        refreshButton.addActionHandlers { sender in
            self.reloadText()
        }
        
        clearButton.snp.makeConstraints { make in
            make.size.centerY.equalTo(button)
            make.right.equalTo(refreshButton.snp.left).offset(-7.5)
        }
        clearButton.addActionHandlers { sender in
            let callBack = FileManager.pt.writeToFile(writeType: .TextType, content: "", writePath: self.filePath)
            if callBack.isSuccess {
                self.reloadText()
            }
        }
        
        infoLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight)
            make.top.equalTo(self.fakeNav.snp.bottom)
        }
        
        reloadText()
    }
    
    func reloadText() {
        let handler = FileManager.pt.readFromFile(readType: .TextType, readPath: filePath)
        let infoAtt:ASAttributedString = """
                    \(wrap: .embedding("""
                    \((handler.content as! String),.font(.appfont(size: 14)),.paragraph(.alignment(.left),.lineSpacing(2.5)),.foreground(DynamicColor(light: .black, dark: .white)))
                    """))
                    """
        infoLabel.attributedText = infoAtt.value
        infoLabel.scrollToBottom()
    }
}
