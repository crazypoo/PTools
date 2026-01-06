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
    
    lazy var backButton:UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(.arrow.uturnLeftCircle), for: .normal)
        if #available(iOS 26.0, *) {
            button.configuration = UIButton.Configuration.clearGlass()
        }
        button.addActionHandlers { sender in
            self.dismissAnimated()
        }
        button.bounds = CGRect(origin: .zero, size: .init(width: 34, height: 34))
        return button
    }()
    
    lazy var refreshButton:UIButton = {
        let refreshButton = UIButton(type: .custom)
        refreshButton.setImage(UIImage(.arrow.clockwise), for: .normal)
        if #available(iOS 26.0, *) {
            refreshButton.configuration = UIButton.Configuration.clearGlass()
        }
        refreshButton.addActionHandlers { sender in
            self.reloadText()
        }
        refreshButton.bounds = CGRect(origin: .zero, size: .init(width: 34, height: 34))
        return refreshButton
    }()
    
    lazy var clearButton:UIButton = {
        let clearButton = UIButton(type: .custom)
        clearButton.setImage(UIImage(.paintbrush), for: .normal)
        if #available(iOS 26.0, *) {
            clearButton.configuration = UIButton.Configuration.clearGlass()
        }
        clearButton.bounds = CGRect(origin: .zero, size: .init(width: 34, height: 34))
        clearButton.addActionHandlers { sender in
            let callBack = FileManager.pt.writeToFile(writeType: .TextType, content: "", writePath: self.filePath)
            if callBack.isSuccess {
                self.reloadText()
            }
        }
        return clearButton
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCustomBackButtonView(backButton)
        setCustomRightButtons(buttons: [valueSwitch,refreshButton,clearButton], rightPadding: 10)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubviews([infoLabel])
        infoLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight)
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
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
