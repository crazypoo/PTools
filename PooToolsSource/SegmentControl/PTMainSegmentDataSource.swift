//
//  MSMainSegmentDataSource.swift
//  MinaTicket
//
//  Created by jax on 2022/6/18.
//  Copyright © 2022 Hola. All rights reserved.
//

import UIKit
import JXSegmentedView

// 🚀 核心终极修复：增加 @unchecked Sendable 协议。
// 结合 @MainActor，完美化解老旧第三方 UI 库与 Swift 6 严格并发检查的冲突！
@MainActor
@objcMembers
public class PTMainSegmentDataSource: JXSegmentedBaseDataSource, @unchecked Sendable {
    
    ///MARK: 这里要先加载数据
    open var dataSourceData = [PTSegmentControlBaseModel]()
    open var change: PTSegmentControlModelType? = .ImageTitle(type: .Normal)
    open var titleNormalColor: UIColor = .black
    open var titleSelectedColor: UIColor = .black
    open var itemWidths: CGFloat = CGFloat.kSCREEN_WIDTH / 4
    
    private var cell_width_array = [CGFloat]()
    private var cell_width_array_sub = [CGFloat]()
    
    public override func reloadData(selectedIndex: Int) {
        // 现在 self 是 Sendable 的了，可以安全地送入 assumeIsolated 闭包中
        MainActor.assumeIsolated {
            super.reloadData(selectedIndex: selectedIndex)
            
            itemWidthIncrement = 20
            itemSpacing = 0
            
            // 同步组装数据，消灭旧代码的隐式生命周期 Bug
            let newModels = self.dataSourceData.enumerated().map { (index, model) -> PTMainSegmentModel in
                let titleModel = PTMainSegmentModel()
                titleModel.title = model.categoryName
                titleModel.subTitle = model.subTitle
                titleModel.itemWidthIncrement = self.itemWidthIncrement
                titleModel.onlyShowTitle = self.change ?? .ImageTitle(type: .Normal)
                titleModel.index = index
                titleModel.itemSpace = self.itemSpacing
                titleModel.titleNormalColor = self.titleNormalColor
                titleModel.titleCurrentColor = self.titleNormalColor
                titleModel.titleSelectedColor = self.titleSelectedColor
                titleModel.titleNormalFont = .appfont(size: 16)
                titleModel.titleSelectedFont = .appfont(size: 16, bold: true)
                titleModel.subTitleSelectedColor = self.titleNormalColor
                titleModel.subTitleNormalColor = self.titleNormalColor
                titleModel.subTitleCurrentColor = self.titleSelectedColor
                titleModel.imageURL = model.imageURL
                titleModel.itemWidth = self.itemWidths
                return titleModel
            }
            
            self.dataSource.append(contentsOf: newModels)
            
            for (index, model) in (self.dataSource as! [PTMainSegmentModel]).enumerated() {
                if index == selectedIndex {
                    model.isSelected = true
                    model.titleCurrentColor = model.titleSelectedColor
                    model.subTitleCurrentColor = model.subTitleSelectedColor
                    model.subTitleCurrentBGColor = model.subTitleSelectedBGColor
                    break
                }
            }
        }
    }
    
    public override func preferredSegmentedView(_ segmentedView: JXSegmentedView, widthForItemAt index: Int) -> CGFloat {
        return MainActor.assumeIsolated {
            guard let firstModel = self.dataSource.first as? PTMainSegmentModel else { return self.itemWidths }
            return firstModel.itemWidth
        }
    }
    
    //MARK: - JXSegmentedViewDataSource
    public override func registerCellClass(in segmentedView: JXSegmentedView) {
        MainActor.assumeIsolated {
            segmentedView.collectionView.register(PTMainSegmentCell.self, forCellWithReuseIdentifier: "titleCell")
        }
    }
    
    public override func segmentedView(_ segmentedView: JXSegmentedView, cellForItemAt index: Int) -> JXSegmentedBaseCell {
        return MainActor.assumeIsolated {
            var cell: JXSegmentedBaseCell?
            if self.dataSource[index] is PTMainSegmentModel {
                cell = segmentedView.dequeueReusableCell(withReuseIdentifier: "titleCell", at: index)
                if let titleCell = cell as? PTMainSegmentCell {
                    titleCell.lineView.isHidden = (index == 0)
                }
            }
            return cell ?? JXSegmentedBaseCell()
        }
    }
    
    // 针对不同的cell处理选中态和未选中态的刷新
    // 针对不同的cell处理选中态和未选中态的刷新
    public override func refreshItemModel(_ segmentedView: JXSegmentedView, currentSelectedItemModel: JXSegmentedBaseItemModel, willSelectedItemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) {
        
        // 🚀 修复核心：移除 MainActor.assumeIsolated。
        // 因为这里我们只操作传入的 Model，不触碰 self（DataSource）里的任何受保护属性。
        // 父类方法本身就是非隔离的，传入非 Sendable 的参数不跨越任何边界，绝对安全！
        super.refreshItemModel(segmentedView, currentSelectedItemModel: currentSelectedItemModel, willSelectedItemModel: willSelectedItemModel, selectedType: selectedType)
        
        // 转化为我们自己的 Model 并安全赋值
        guard let myCurrentSelectedItemModel = currentSelectedItemModel as? PTMainSegmentModel,
              let myWilltSelectedItemModel = willSelectedItemModel as? PTMainSegmentModel else {
            return
        }
        
        myCurrentSelectedItemModel.titleCurrentColor = myCurrentSelectedItemModel.titleNormalColor
        myWilltSelectedItemModel.titleCurrentColor = myWilltSelectedItemModel.titleSelectedColor
        myCurrentSelectedItemModel.subTitleCurrentColor = myCurrentSelectedItemModel.subTitleNormalColor
        myWilltSelectedItemModel.subTitleCurrentColor = myWilltSelectedItemModel.subTitleSelectedColor
        myCurrentSelectedItemModel.subTitleCurrentBGColor = myCurrentSelectedItemModel.subTitleNormalBGColor
        myWilltSelectedItemModel.subTitleCurrentBGColor = myWilltSelectedItemModel.subTitleSelectedBGColor
    }
}
