//
//  PTStepperCellsCollection.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/22/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import SnapKit

//MARK: HorizontalCell
public class PTStepperHorizontalCell: PTBaseNormalCell {
    public static let ID = "PTStepperHorizontalCell"
    
    public var cellModel: PTStepperListModel! {
        didSet {
            PTGCDManager.gcdMain {
                self.circleView.snp.updateConstraints { make in
                    make.size.equalTo(self.cellModel.stopCircleWidth)
                }
                if self.cellModel.stopFinish {
                    self.circleView.viewCorner(radius: self.cellModel.stopCircleWidth / 2,borderWidth: 1,borderColor: self.cellModel.stopSelectedColor)
                    if self.cellModel.circleFillColor {
                        self.circleView.backgroundColor = self.cellModel.stopFinish ? self.cellModel.stopSelectedColor : .clear
                        self.stopLabel.textColor = self.cellModel.stopFinish ? .white : self.cellModel.stopNormalColor
                    } else {
                        self.stopLabel.textColor = self.cellModel.stopFinish ? self.cellModel.stopSelectedColor : self.cellModel.stopNormalColor
                    }
                } else {
                    self.circleView.viewCorner(radius: self.cellModel.stopCircleWidth / 2,borderWidth: 1,borderColor: self.cellModel.stopNormalColor)
                    self.stopLabel.textColor = self.cellModel.stopFinish ? self.cellModel.stopSelectedColor : self.cellModel.stopNormalColor
                }
            }
            
            leftLine.snp.updateConstraints { make in
                make.height.equalTo(self.cellModel.stopLineHeight)
            }
            
            rightLine.snp.updateConstraints { make in
                make.height.equalTo(self.cellModel.stopLineHeight)
            }
            rightLine.backgroundColor = self.cellModel.stopFinish ? self.cellModel.stopSelectedColor : self.cellModel.stopNormalColor

            infoLabel.textColor = cellModel.titleColor
            infoLabel.font = cellModel.titleFont
            infoLabel.text = cellModel.title
            
            stopLabel.font = cellModel.stopFont
        }
    }
    
    fileprivate lazy var circleView:UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var leftLine:UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var rightLine:UIView = {
        let view = UIView()
        return view
    }()
    
    fileprivate var infoLabel:UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.numberOfLines = 0
        return view
    }()
    
    lazy var stopLabel:UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.numberOfLines = 0
        view.isHidden = true
        return view
    }()
    
    lazy var stopImage:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubviews([circleView,leftLine,rightLine,infoLabel,stopLabel,stopImage])
        circleView.snp.makeConstraints { make in
            make.centerX.top.equalToSuperview()
            make.size.equalTo(0)
        }
        
        leftLine.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalTo(self.circleView.snp.left)
            make.centerY.equalTo(self.circleView)
            make.height.equalTo(0)
        }
        
        rightLine.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.left.equalTo(self.circleView.snp.right)
            make.centerY.equalTo(self.circleView)
            make.height.equalTo(0)
        }

        infoLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(7.5)
            make.top.equalTo(self.circleView.snp.bottom)
            make.bottom.equalToSuperview().inset(7.5)
        }
        
        stopLabel.snp.makeConstraints { make in
            make.edges.equalTo(self.circleView)
        }
        
        stopImage.snp.makeConstraints { make in
            make.edges.equalTo(self.circleView)
        }
    }
    
    @MainActor required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: VerticalCell
public class PTStepperVerticalCell: PTBaseNormalCell {
    public static let ID = "PTStepperVerticalCell"
    
    public var cellModel: PTStepperListModel! {
        didSet {
            PTGCDManager.gcdMain {
                self.circleView.snp.updateConstraints { make in
                    make.size.equalTo(self.cellModel.stopCircleWidth)
                }
                if self.cellModel.stopFinish {
                    self.circleView.viewCorner(radius: self.cellModel.stopCircleWidth / 2,borderWidth: 1,borderColor: self.cellModel.stopSelectedColor)
                    if self.cellModel.circleFillColor {
                        self.circleView.backgroundColor = self.cellModel.stopFinish ? self.cellModel.stopSelectedColor : .clear
                        self.stopLabel.textColor = self.cellModel.stopFinish ? .white : self.cellModel.stopNormalColor
                    } else {
                        self.stopLabel.textColor = self.cellModel.stopFinish ? self.cellModel.stopSelectedColor : self.cellModel.stopNormalColor
                    }
                } else {
                    self.circleView.viewCorner(radius: self.cellModel.stopCircleWidth / 2,borderWidth: 1,borderColor: self.cellModel.stopNormalColor)
                    self.stopLabel.textColor = self.cellModel.stopFinish ? self.cellModel.stopSelectedColor : self.cellModel.stopNormalColor
                }
            }
            
            verticalLine.snp.updateConstraints { make in
                make.width.equalTo(self.cellModel.stopLineHeight)
            }

            infoLabel.textColor = cellModel.titleColor
            infoLabel.font = cellModel.titleFont
            infoLabel.text = cellModel.title

            stopLabel.font = cellModel.stopFont
        }
    }
    
    fileprivate lazy var circleView:UIView = {
        let view = UIView()
        return view
    }()

    fileprivate var infoLabel:UILabel = {
        let view = UILabel()
        view.textAlignment = .left
        view.numberOfLines = 0
        return view
    }()

    lazy var stopLabel:UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.numberOfLines = 0
        view.isHidden = true
        return view
    }()
    
    lazy var stopImage:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    lazy var verticalLine:UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var descLabel:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubviews([circleView,verticalLine,infoLabel,stopLabel,stopImage,descLabel])
        circleView.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.size.equalTo(0)
        }
        
        verticalLine.snp.makeConstraints { make in
            make.centerX.equalTo(self.circleView)
            make.top.equalTo(self.circleView.snp.bottom)
            make.bottom.equalToSuperview()
            make.width.equalTo(0)
        }
        
        infoLabel.snp.makeConstraints { make in
            make.left.equalTo(self.circleView.snp.right).offset(20)
            make.right.equalToSuperview().inset(10)
            make.top.bottom.equalTo(self.circleView)
        }
        
        stopLabel.snp.makeConstraints { make in
            make.edges.equalTo(self.circleView)
        }
        
        stopImage.snp.makeConstraints { make in
            make.edges.equalTo(self.circleView)
        }
        
        descLabel.snp.makeConstraints { make in
            make.left.right.equalTo(self.infoLabel)
            make.top.equalTo(self.infoLabel.snp.bottom)
            make.bottom.equalTo(self.verticalLine)
        }
    }
    
    @MainActor required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
