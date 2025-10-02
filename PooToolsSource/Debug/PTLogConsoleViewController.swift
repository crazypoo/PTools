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
import SafeSFSymbols
import AttributedString

class PTLogConsoleViewController: PTBaseViewController {

    lazy var fakeNav:PTNavBar = {
        let view = PTNavBar()
        return view
    }()

    lazy var valueSwitch:PTSwitch = {
        let view = PTSwitch()
        view.isOn = PTCoreUserDefultsWrapper.PTLogWrite
        view.valueChangeCallBack = { value in
            PTCoreUserDefultsWrapper.PTLogWrite = value
        }
        view.bounds = CGRect(origin: .zero, size: CGSize.SwitchSize)
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
        navigationController?.navigationBar.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubviews([fakeNav,infoLabel])
        fakeNav.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(self.sheetViewController?.options.pullBarHeight ?? 0)
            make.height.equalTo(CGFloat.kNavBarHeight)
        }
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(.arrow.uturnLeftCircle), for: .normal)
        if #available(iOS 26.0, *) {
            button.configuration = UIButton.Configuration.clearGlass()
        }

        let refreshButton = UIButton(type: .custom)
        refreshButton.setImage(UIImage(.arrow.clockwise), for: .normal)
        if #available(iOS 26.0, *) {
            refreshButton.configuration = UIButton.Configuration.clearGlass()
        }

        let clearButton = UIButton(type: .custom)
        clearButton.setImage(UIImage(.paintbrush), for: .normal)
        if #available(iOS 26.0, *) {
            clearButton.configuration = UIButton.Configuration.clearGlass()
        }

        fakeNav.setLeftButtons([button])
        fakeNav.setRightButtons([valueSwitch,refreshButton,clearButton])
        
        button.addActionHandlers { sender in
            self.dismissAnimated()
        }
        
        refreshButton.addActionHandlers { sender in
            self.reloadText()
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
        if let content = handler.content as? String {
            let infoAtt:ASAttributedString = """
                        \(wrap: .embedding("""
                        \(content,.font(.appfont(size: 14)),.paragraph(.alignment(.left),.lineSpacing(2.5)),.foreground(DynamicColor(light: .black, dark: .white)))
                        """))
                        """
            infoLabel.attributedText = infoAtt.value
            infoLabel.scrollToBottom()
        }
    }
}
