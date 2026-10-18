//
//  CropView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
#if canImport(PToolsConstraintLayout)
import PToolsConstraintLayout
#endif
import SnapKit

// English: Import the umbrella Core target explicitly for standalone SwiftPM builds.
// Español: Importa explícitamente el target Core para las compilaciones SwiftPM independientes.
// 中文：独立 SwiftPM 编译时，显式导入 Core 聚合 target。
#if SWIFT_PACKAGE
import ptools
#endif

// Crop LineView
class CropView: UIView {
    private let margin: CGFloat = 0
    private let lineSize: CGFloat = 1
    
    var lineColor: UIColor? = .white {
        willSet {
            self.topLineView.backgroundColor = newValue
            self.bottomLineView.backgroundColor = newValue
            self.leftLineView.backgroundColor = newValue
            self.rightLineView.backgroundColor = newValue
            self.horizontalRightLineView.backgroundColor = newValue
            self.horizontalLeftLineView.backgroundColor = newValue
            self.verticalTopLineView.backgroundColor = newValue
            self.verticalBottomLineView.backgroundColor = newValue
        }
    }
    
    private lazy var topLineView: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.ptLayout.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview().offset(self.margin).priority(950)
            make.height.equalTo(self.lineSize).priority(950)
        }
        return view
    }()
    
    private lazy var leftLineView: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.ptLayout.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().offset(self.margin).priority(950)
            make.width.equalTo(self.lineSize).priority(950)
        }
        return view
    }()
    
    private lazy var bottomLineView: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.ptLayout.makeConstraints { make in
            make.leading.trailing.equalToSuperview().offset(self.margin).priority(950)
            make.bottom.equalToSuperview().offset(self.margin).priority(950)
            make.height.equalTo(self.lineSize).priority(950)
        }
        return view
    }()
    
    private lazy var rightLineView: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.ptLayout.makeConstraints { make in
            make.trailing.top.bottom.equalToSuperview().offset(self.margin).priority(950)
            make.width.equalTo(self.lineSize).priority(950)
        }
        return view
    }()
    
    private lazy var horizontalLeftLineView: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.ptLayout.makeConstraints { make in
            make.leading.equalTo(self.horizontalLeftView.ptLayout.trailing).priority(950)
            make.bottom.equalTo(self.bottomLineView.ptLayout.top).priority(950)
            make.top.equalTo(self.topLineView.ptLayout.bottom).priority(950)
            make.width.equalTo(self.lineSize).priority(950)
        }
        return view
    }()
    
    private lazy var horizontalRightLineView: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.ptLayout.makeConstraints { make in
            make.leading.equalTo(self.horizontalCenterView.ptLayout.trailing).priority(950)
            make.bottom.equalTo(self.bottomLineView.ptLayout.top).priority(950)
            make.top.equalTo(self.topLineView.ptLayout.bottom).priority(950)
            make.width.equalTo(self.lineSize).priority(950)
        }
        return view
    }()
    
    private lazy var verticalTopLineView: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.ptLayout.makeConstraints { make in
            make.top.equalTo(self.verticalTopView.ptLayout.bottom).priority(950)
            make.leading.equalTo(self.leftLineView.ptLayout.trailing).priority(950)
            make.trailing.equalTo(self.rightLineView.ptLayout.leading).priority(950)
            make.height.equalTo(self.lineSize).priority(950)
        }
        return view
    }()
    
    private lazy var verticalBottomLineView: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.ptLayout.makeConstraints { make in
            make.top.equalTo(self.verticalCenterView.ptLayout.bottom).priority(950)
            make.leading.equalTo(self.leftLineView.ptLayout.trailing).priority(950)
            make.trailing.equalTo(self.rightLineView.ptLayout.leading).priority(950)
            make.height.equalTo(self.lineSize).priority(950)
        }
        return view
    }()
    
    private lazy var horizontalLeftView: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.ptLayout.makeConstraints { make in
            make.leading.equalTo(self.leftLineView.ptLayout.trailing).priority(950)
            make.bottom.equalTo(self.bottomLineView.ptLayout.top).priority(950)
            make.top.equalTo(self.topLineView.ptLayout.bottom).priority(950)
        }
        return view
    }()
    
    private lazy var horizontalCenterView: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.ptLayout.makeConstraints { make in
            make.leading.equalTo(self.horizontalLeftLineView.ptLayout.trailing).priority(950)
            make.bottom.equalTo(self.bottomLineView.ptLayout.top).priority(950)
            make.top.equalTo(self.topLineView.ptLayout.bottom).priority(950)
            make.width.equalTo(self.horizontalLeftView.ptLayout.width).priority(950)
        }
        return view
    }()
    
    private lazy var horizontalRightView: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.ptLayout.makeConstraints { make in
            make.leading.equalTo(self.horizontalRightLineView.ptLayout.trailing).priority(950)
            make.bottom.equalTo(self.bottomLineView.ptLayout.top).priority(950)
            make.top.equalTo(self.topLineView.ptLayout.bottom).priority(950)
            make.trailing.equalTo(self.rightLineView.ptLayout.leading).priority(950)
            make.width.equalTo(self.horizontalLeftView.ptLayout.width).priority(950)
        }
        return view
    }()
    
    private lazy var verticalTopView: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.ptLayout.makeConstraints { make in
            make.top.equalTo(self.topLineView.ptLayout.bottom).priority(950)
            make.leading.equalTo(self.leftLineView.ptLayout.trailing).priority(950)
            make.trailing.equalTo(self.rightLineView.ptLayout.leading).priority(950)
        }
        return view
    }()
    
    private lazy var verticalCenterView: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.ptLayout.makeConstraints { make in
            make.top.equalTo(self.verticalTopLineView.ptLayout.bottom).priority(950)
            make.leading.equalTo(self.leftLineView.ptLayout.trailing).priority(950)
            make.trailing.equalTo(self.rightLineView.ptLayout.leading).priority(950)
            make.height.equalTo(self.verticalTopView.ptLayout.height).priority(950)
        }
        return view
    }()
    
    private lazy var verticalBottomView: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.ptLayout.makeConstraints { make in
            make.top.equalTo(self.verticalBottomLineView.ptLayout.bottom).priority(950)
            make.leading.equalTo(self.leftLineView.ptLayout.trailing).priority(950)
            make.trailing.equalTo(self.rightLineView.ptLayout.leading).priority(950)
            make.height.equalTo(self.verticalTopView.ptLayout.height).priority(950)
            make.bottom.equalTo(self.bottomLineView.ptLayout.top).priority(950)
        }
        return view
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        PTGCDManager.shared.runOnMain {
            self.initVars()
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.initVars()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initVars()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func initVars() {
        self.isUserInteractionEnabled = false
        self.backgroundColor = .clear
        self.topLineView.alpha = 1
        self.leftLineView.alpha = 1
        self.bottomLineView.alpha = 1
        self.rightLineView.alpha = 1
        self.horizontalLeftLineView.alpha = 0
        self.horizontalRightLineView.alpha = 0
        self.verticalTopLineView.alpha = 0
        self.verticalBottomLineView.alpha = 0
        
        self.horizontalLeftView.alpha = 0
        self.horizontalCenterView.alpha = 0
        self.horizontalRightView.alpha = 0
        self.verticalTopView.alpha = 0
        self.verticalCenterView.alpha = 0
        self.verticalBottomView.alpha = 0
    }
    
    func line(_ isHidden: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.3) {
                if isHidden {
                    self.horizontalRightLineView.alpha = 0
                    self.horizontalLeftLineView.alpha = 0
                    self.verticalTopLineView.alpha = 0
                    self.verticalBottomLineView.alpha = 0
                } else {
                    self.horizontalRightLineView.alpha = 1
                    self.horizontalLeftLineView.alpha = 1
                    self.verticalTopLineView.alpha = 1
                    self.verticalBottomLineView.alpha = 1
                }
            }
        } else {
            if isHidden {
                self.horizontalRightLineView.alpha = 0
                self.horizontalLeftLineView.alpha = 0
                self.verticalTopLineView.alpha = 0
                self.verticalBottomLineView.alpha = 0
            } else {
                self.horizontalRightLineView.alpha = 1
                self.horizontalLeftLineView.alpha = 1
                self.verticalTopLineView.alpha = 1
                self.verticalBottomLineView.alpha = 1
            }
        }
    }
}
