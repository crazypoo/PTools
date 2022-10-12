//
//  MSMainSegmentDataSource.swift
//  MinaTicket
//
//  Created by jax on 2022/6/18.
//  Copyright © 2022 Hola. All rights reserved.
//

import UIKit
import JXSegmentedView

public class PTMainSegmentDataSource: JXSegmentedBaseDataSource {
    ///MARK:这里要先加载数据
    public var dataSourceData = [PTSegmentControlBaseModel?]()
    public var change:PTSegmentControlModelType? = .ImageTitle(type: .Normal)
    public var titleNormalColor:UIColor = .black
    public var titleSelectedColor:UIColor = .black
    public var itemWidths: CGFloat = kSCREEN_WIDTH / 4
    private var cell_width_array = [CGFloat]()
    private var cell_width_array_sub = [CGFloat]()
    
    public override func reloadData(selectedIndex: Int) {
        super.reloadData(selectedIndex: selectedIndex)
        itemWidthIncrement = 20
        itemSpacing = 0
                
        dataSourceData.enumerated().forEach { (index,model) in
            let titleModel = PTMainSegmentModel()
            titleModel.title = model?.categoryName
            titleModel.subTitle = model?.subTitle
            titleModel.itemWidthIncrement = itemWidthIncrement
            titleModel.onlyShowTitle = change!
            titleModel.index = index
            titleModel.itemSpace = itemSpacing
            titleModel.titleNormalColor = self.titleNormalColor
            titleModel.titleCurrentColor = self.titleNormalColor
            titleModel.titleSelectedColor = self.titleSelectedColor
            titleModel.titleNormalFont = .appfont(size: 16)
            titleModel.titleSelectedFont = .appfont(size: 16,bold: true)
            titleModel.subTitleSelectedColor = self.titleNormalColor
            titleModel.subTitleNormalColor = self.titleNormalColor
            titleModel.subTitleCurrentColor = self.titleSelectedColor
            titleModel.imageURL = model?.imageURL
            titleModel.itemWidth = self.itemWidths
            dataSource.append(titleModel)
        }

        for (index, model) in (dataSource as! [PTMainSegmentModel]).enumerated() {
            if index == selectedIndex {
                model.isSelected = true
                model.titleCurrentColor = model.titleSelectedColor
                model.subTitleCurrentColor = model.subTitleSelectedColor
                model.subTitleCurrentBGColor = model.subTitleSelectedBGColor
                break
            }
        }
    }

    public override func preferredSegmentedView(_ segmentedView: JXSegmentedView, widthForItemAt index: Int) -> CGFloat {
        return dataSource.first!.itemWidth
    }

    //MARK: - JXSegmentedViewDataSource
    public override func registerCellClass(in segmentedView: JXSegmentedView) {
        segmentedView.collectionView.register(PTMainSegmentCell.self, forCellWithReuseIdentifier: "titleCell")
    }

    public override func segmentedView(_ segmentedView: JXSegmentedView, cellForItemAt index: Int) -> JXSegmentedBaseCell {
        var cell:JXSegmentedBaseCell?
        if dataSource[index] is PTMainSegmentModel {
            cell = segmentedView.dequeueReusableCell(withReuseIdentifier: "titleCell", at: index)
            if index != 0
            {
                (cell as! PTMainSegmentCell).lineView.isHidden = false
            }
            else
            {
                (cell as! PTMainSegmentCell).lineView.isHidden = true
            }
        }
        return cell!
    }

    //针对不同的cell处理选中态和未选中态的刷新
    public override func refreshItemModel(_ segmentedView: JXSegmentedView, currentSelectedItemModel: JXSegmentedBaseItemModel, willSelectedItemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) {
        super.refreshItemModel(segmentedView, currentSelectedItemModel: currentSelectedItemModel, willSelectedItemModel: willSelectedItemModel, selectedType: selectedType)

        guard let myCurrentSelectedItemModel = currentSelectedItemModel as? PTMainSegmentModel, let myWilltSelectedItemModel = willSelectedItemModel as? PTMainSegmentModel else {
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
