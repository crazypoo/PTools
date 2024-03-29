//
//  PTVideoEditorToolsSpeedControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

class PTVideoEditorToolsSpeedControl: PTVideoEditorBaseFloatingViewController {

    // MARK: Public Properties
    fileprivate var speed: Double
    public var speedHandler:((Double)->Void)!

    // MARK: Private Properties

    private lazy var slider: PTVideoEditorToolsSlider = {
        let slider = PTVideoEditorToolsSlider()
        slider.value = speed
        slider.range = .stepped(values: [0.25, 0.5, 0.75, 1.0, 2.0, 5.0, 10.0])
        slider.isContinuous = false
        return slider
    }()
    
    // MARK: Init
    
    init(speed: Double,typeModel:PTVideoEditorToolsModel) {
        self.speed = speed
        super.init(viewControl: typeModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubviews([slider])
        let inset: CGFloat = 28.0
        slider.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(inset)
            make.height.equalTo(48)
            make.centerY.equalToSuperview()
        }
        
        doneButton.addActionHandlers { sender in
            self.speedHandler(self.slider.value)
            self.returnFrontVC()
        }
    }
}

