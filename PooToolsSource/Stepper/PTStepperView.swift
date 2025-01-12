//
//  PTStepperView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/22/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import AttributedString

public enum PTStepperViewType {
    case Horizontal(type:PTStepperHorizontalSubType)
    case Vertical(type:PTStepperVerticalSubType)
    
    public enum PTStepperHorizontalSubType {
        case Normal
        case Scroll
    }
    
    public enum PTStepperVerticalSubType {
        case Normal
//        case Card
    }
}

open class PTStepperListConfig:NSObject {
    ///展示的类型
    open var type:PTStepperViewType = .Horizontal(type: .Normal)
    ///数据Model
    open var stepperModels:[PTStepperListModel]!
    
    ///用于横向混动的W(Scroll模式下使用)
    open var itemWidth:CGFloat = 100
    ///用于竖向滑动的H
    open var itemHeight:CGFloat =   100
    ///用于竖向滑动的起始点
    open var itemOriginalX:CGFloat = 0
    ///空白頁
    open var emptyConfig:PTEmptyDataViewConfig?
    ///当前线是否填充颜色
    open var currentStopLineColorShow:Bool = true
}

public enum PTStepperModelStopType {
    ///步骤
    case Step
    ///图片
    case Image
    ///自定义,暂时支持文字
    case Custom
}

open class PTStepperListModel:PTBaseModel {
    ///标题
    open var title:String = ""
    
    open var titleAtt:ASAttributedString?
    ///标题颜色
    open var titleColor:UIColor = DynamicColor(light: .black, dark: .white)
    ///标题字体
    open var titleFont:UIFont = .appfont(size: 14)
    ///描述
    open var desc:String = ""
    ///描述颜色
    open var descColor:UIColor = DynamicColor(light: .black, dark: .white)
    ///描述字体
    open var descFont:UIFont = .appfont(size: 14)
    ///描述富文本
    open var descAtt:ASAttributedString?
    ///圈圈是否填充颜色
    open var circleFillColor:Bool = true
    ///圈圈大小min15max64
    @PTClampedProperyWrapper(range:10...64) open var stopCircleWidth: CGFloat = 44
    ///圈圈线宽度min1max8
    @PTClampedProperyWrapper(range:1...8) open var borderWidth: CGFloat = 1
    ///普通颜色
    open var stopNormalColor = DynamicColor.lightGray
    ///已经完成颜色
    open var stopSelectedColor = DynamicColor.cyan
    ///线宽度
    @PTClampedProperyWrapper(range:1...5) open var stopLineHeight: CGFloat = 1
    ///是否已经完成
    open var stopFinish:Bool = true
    ///圈圈展示类型
    open var stopType:PTStepperModelStopType = .Step
    ///圈圈展示内容
    open var stopInfo:Any?
    ///圈圈展示内字体
    open var stopFont:UIFont = .appfont(size: 14)
}

open class PTStepperView: UIView {
    
    open var viewConfig:PTStepperListConfig = PTStepperListConfig()
    fileprivate var normalHorizontalItemWidth:CGFloat = 0
    fileprivate var itemOriginalX:CGFloat = 10
    
    public lazy var listCollection:PTCollectionView = {
        let collectionConfig = PTCollectionViewConfig()
        collectionConfig.viewType = .Custom
        if let emptyConfig = viewConfig.emptyConfig {
            collectionConfig.showEmptyAlert = true
            collectionConfig.emptyViewConfig = emptyConfig
        }
        switch self.viewConfig.type {
        case .Horizontal(let type):
            if type == .Normal {
                collectionConfig.alwaysBounceHorizontal = false
            } else {
                collectionConfig.alwaysBounceHorizontal = true
            }
            collectionConfig.alwaysBounceVertical = false
        case .Vertical(_):
            collectionConfig.alwaysBounceVertical = true
            collectionConfig.alwaysBounceHorizontal = false
        }
        let view = PTCollectionView(viewConfig: collectionConfig)
        view.registerClassCells(classs: [PTStepperHorizontalCell.ID:PTStepperHorizontalCell.self,PTStepperVerticalCell.ID:PTStepperVerticalCell.self])
        view.customerLayout = { index,section in
            switch self.viewConfig.type {
            case .Horizontal(let type):
                var itemW:CGFloat = 0
                if type == .Normal {
                    itemW = self.normalHorizontalItemWidth
                } else {
                    itemW = self.viewConfig.itemWidth
                }
                return UICollectionView.horizontalLayout(data: section.rows!,itemOriginalX: 0,itemWidth: itemW,itemHeight: self.height,topContentSpace: 0,bottomContentSpace: 0,itemLeadingSpace: 0)
            case .Vertical(_):
                return UICollectionView.waterFallLayout(data: section.rows!,rowCount: 1,itemOriginalX: self.viewConfig.itemOriginalX, itemSpace: 0) { index, rowModels in
                    var realHeight:CGFloat = self.viewConfig.itemHeight
                    if let rowModel = rowModels as? PTRows,let cellModel = rowModel.dataModel as? PTStepperListModel {
                        let contentWidth = CGFloat.kSCREEN_WIDTH - self.viewConfig.itemOriginalX * 2 - cellModel.stopCircleWidth - PTStepperVerticalCell.circleRight - PTAppBaseConfig.share.defaultViewSpace
                        var descHeight:CGFloat = 0
                        if let descAtt = cellModel.descAtt {
                            descHeight = UIView.sizeFor(string: descAtt.value.description, font: .appfont(size: descAtt.value.largestFontSize()),width: contentWidth).height + 5
                        } else {
                            descHeight = UIView.sizeFor(string: cellModel.desc, font: cellModel.descFont,width: contentWidth).height + 5
                        }
                        
                        var titleHeight:CGFloat = 0
                        if let titleAtt = cellModel.titleAtt {
                            titleHeight = UIView.sizeFor(string: titleAtt.value.string, font: .appfont(size: titleAtt.value.largestFontSize()),width: contentWidth).height + 5
                        } else {
                            titleHeight = UIView.sizeFor(string: cellModel.title, font: cellModel.titleFont,width: contentWidth).height + 5
                        }
                        let totalHeight = descHeight + titleHeight
                        if totalHeight > realHeight {
                            realHeight = totalHeight
                        }
                    }
                    return realHeight
                }
            }
        }
        view.cellInCollection = { collectionView,sectionModel,indexPath in
            if let itemRow = sectionModel.rows?[indexPath.row] {
                let cellModel = itemRow.dataModel as! PTStepperListModel
                if itemRow.ID == PTStepperHorizontalCell.ID {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTStepperHorizontalCell
                    cell.cellModel = cellModel
                    
                    if let forwardCell = collectionView.cellForItem(at: IndexPath(row: indexPath.row - 1, section: indexPath.section)) as? PTStepperHorizontalCell {
                        if forwardCell.cellModel.stopFinish {
                            cell.leftLine.backgroundColor = cellModel.stopSelectedColor
                        } else {
                            cell.leftLine.backgroundColor = cellModel.stopNormalColor
                        }
                    } else {
                        if cellModel.stopFinish {
                            cell.leftLine.backgroundColor = cellModel.stopSelectedColor
                        } else {
                            cell.leftLine.backgroundColor = cellModel.stopNormalColor
                        }
                    }

                    cell.leftLine.isHidden = indexPath.row == 0 ? true : false
                    cell.rightLine.isHidden = indexPath.row == (sectionModel.rows!.count - 1) ? true : false
                    switch cellModel.stopType {
                    case .Step:
                        cell.stopLabel.isHidden = false
                        cell.stopImage.isHidden = true
                        cell.stopLabel.text = "\(indexPath.row + 1)"
                    case .Image:
                        cell.stopLabel.isHidden = true
                        cell.stopImage.isHidden = false
                        if let image = cellModel.stopInfo {
                            cell.stopImage.loadImage(contentData: image)
                        } else {
                            cell.stopImage.image = PTAppBaseConfig.share.defaultEmptyImage
                        }
                    case .Custom:
                        cell.stopLabel.isHidden = false
                        cell.stopImage.isHidden = true
                        if let customLabel = cellModel.stopInfo as? String {
                            cell.stopLabel.text = customLabel
                        }
                    }
                    return cell
                } else if itemRow.ID == PTStepperVerticalCell.ID {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTStepperVerticalCell
                    cell.cellModel = cellModel
                    cell.verticalLine.isHidden = indexPath.row == (sectionModel.rows!.count - 1) ? true : false
                    if self.viewConfig.currentStopLineColorShow {
                        cell.verticalLine.backgroundColor = cellModel.stopFinish ? cellModel.stopSelectedColor : cellModel.stopNormalColor
                    } else {
                        cell.verticalLine.backgroundColor = cellModel.stopNormalColor
                    }
                    
                    switch self.viewConfig.type {
                    case .Vertical(let type):
                        switch type {
                        case .Normal:
                            if !cellModel.desc.stringIsEmpty() {
                                cell.descLabel.text = cellModel.desc
                                cell.descLabel.font = cellModel.descFont
                                cell.descLabel.textColor = cellModel.descColor
                                cell.descLabel.textAlignment = .left
                            } else if let att = cellModel.descAtt {
                                cell.descLabel.attributed.text = att
                            }
                            
                            if !cellModel.title.stringIsEmpty() {                                
                                cell.infoLabel.textColor = cellModel.titleColor
                                cell.infoLabel.font = cellModel.titleFont
                                cell.infoLabel.text = cellModel.title
                                cell.infoLabel.textAlignment = .left
                            } else if let att = cellModel.titleAtt {
                                cell.infoLabel.attributed.text = att
                            }
    //                    case .Card:
    //                        break
                        }
                    default:
                        break
                    }
                    
                    switch cellModel.stopType {
                    case .Step:
                        cell.stopLabel.isHidden = false
                        cell.stopImage.isHidden = true
                        cell.stopLabel.text = "\(indexPath.row + 1)"
                    case .Image:
                        cell.stopLabel.isHidden = true
                        cell.stopImage.isHidden = false
                        if let image = cellModel.stopInfo {
                            cell.stopImage.loadImage(contentData: image)
                        } else {
                            cell.stopImage.image = PTAppBaseConfig.share.defaultEmptyImage
                        }
                    case .Custom:
                        cell.stopLabel.isHidden = false
                        cell.stopImage.isHidden = true
                        if let customLabel = cellModel.stopInfo as? String {
                            cell.stopLabel.text = customLabel
                        }
                    }

                    return cell
                }
            }
            return nil
        }
        view.collectionDidSelect = { collectionView,sectionModel,indexPath in
            let itemRow = sectionModel.rows?[indexPath.row]
        }
        return view
    }()

    public init(viewConfig:PTStepperListConfig = .init()) {
        self.viewConfig = viewConfig
        super.init(frame: .zero)
        
        addSubviews([listCollection])
        listCollection.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
                
        PTGCDManager.gcdAfter(time: 0.1) {
            self.dataListSet()
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        switch self.viewConfig.type {
        case .Horizontal(let type):
            if type == .Normal {
                PTGCDManager.gcdAfter(time: 0.01) {
                    self.normalHorizontalItemWidth = self.width / CGFloat(self.viewConfig.stepperModels.count)
                }
            }
        case .Vertical( _):
            break
        }
    }
    
    func dataListSet() {
        var sections = [PTSection]()
        
        switch self.viewConfig.type {
        case .Horizontal(_):
            var rows = [PTRows]()
            self.viewConfig.stepperModels.enumerated().forEach { index,value in
                let row = PTRows(ID:PTStepperHorizontalCell.ID,dataModel: value)
                rows.append(row)
            }
            sections.append(PTSection(rows: rows))
        case .Vertical(_):
            var rows = [PTRows]()
            self.viewConfig.stepperModels.enumerated().forEach { index,value in
                let row = PTRows(ID:PTStepperVerticalCell.ID,dataModel: value)
                rows.append(row)
            }
            sections.append(PTSection(rows: rows))
        }
        
        listCollection.showCollectionDetail(collectionData: sections)
    }
}
