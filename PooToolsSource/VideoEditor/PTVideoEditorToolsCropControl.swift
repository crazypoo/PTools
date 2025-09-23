//
//  PTVideoEditorToolsCropControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 12/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

class PTVideoEditorToolsCropControl: PTBaseViewController {

    var cropImageHandler:((CGSize,CGRect)->Void)!
    
    lazy var dismissButtonItem:UIButton = {
        let image = PTVideoEditorConfig.share.dismissImage
        let buttonItem = UIButton(type: .custom)
        buttonItem.setImage(image, for: .normal)
        buttonItem.addActionHandlers { sender in
            self.returnFrontVC()
        }
        return buttonItem
    }()
    
    lazy var doneButtonItem:UIButton = {
        let image = PTVideoEditorConfig.share.cutImage
        let buttonItem = UIButton(type: .custom)
        buttonItem.setImage(image, for: .normal)
        buttonItem.addActionHandlers { sender in
            self.cropView.crop { [weak self] (crop) in
                guard let self = self else { return }
                if let error = crop.error {
                    PTGCDManager.gcdMain {
                        PTAlertTipControl.present(title:PTVideoEditorConfig.share.alertTitleOpps,subtitle:error.localizedDescription,icon:.Error,style: .Normal)
                    }
                    return
                }
                if let cropFrame = crop.cropFrame, let imageSize = crop.imageSize {
                    self.dismiss(animated: true) {
                        self.cropImageHandler(imageSize,cropFrame)
                    }
                }
            }
        }
        return buttonItem
    }()

    
    private var cropView: CropPickerView = {
        let view = CropPickerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.cropLineColor = .white
        view.dimBackgroundColor = UIColor(white: 0, alpha: 0.6)
        return view
    }()

    private let image: UIImage

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let nav = navigationController else { return }
        PTBaseNavControl.GobalNavControl(nav: nav,textColor: .white,navColor: .black)
        dismissButtonItem.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        doneButtonItem.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        setCustomBackButtonView(dismissButtonItem)
        setCustomRightButtons(buttons: [doneButtonItem], rightPadding: 0)
    }

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.clipsToBounds = true
        self.view.backgroundColor = .black
        self.view.addSubview(self.cropView)
        self.cropView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + 10)
        }

        PTGCDManager.gcdMain {
            self.cropView.image(self.image, isMin: true)
        }
    }
}
