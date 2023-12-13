//
//  PTVideoEditorFilterControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 13/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

class PTVideoEditorFilterControl: PTVideoEditorBaseFloatingViewController {

    public var filterHandler:((PTHarBethFilter)->Void)!
    
    private var currentFilter: PTHarBethFilter! = PTHarBethFilter(name: "", type: .none)
    
    private var thumbnailFilterImages: [UIImage] = []

    private lazy var filterCollectionView : PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Custom

        let view = PTCollectionView(viewConfig: config)
        view.customerLayout = { sectionModel in
            var bannerGroupSize : NSCollectionLayoutSize
            var customers = [NSCollectionLayoutGroupCustomItem]()
            var groupW:CGFloat = PTAppBaseConfig.share.defaultViewSpace
            let screenW:CGFloat = 88
            let cellHeight:CGFloat = PTCutViewController.cutRatioHeight
            sectionModel.rows.enumerated().forEach { (index,model) in
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: PTAppBaseConfig.share.defaultViewSpace + 10 * CGFloat(index) + screenW * CGFloat(index), y: 0, width: screenW, height: cellHeight), zIndex: 1000+index)
                customers.append(customItem)
                groupW += (cellHeight + 10)
            }
            bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(groupW), heightDimension: NSCollectionLayoutDimension.absolute(cellHeight))
            return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                customers
            })
        }
        view.cellInCollection = { collection,sectionModel,indexPath in
            let config = PTImageEditorConfig.share
            let itemRow = sectionModel.rows[indexPath.row]
            let cellTools = itemRow.dataModel as! UIImage
            let cellFilter = PTImageEditorConfig.share.filters[indexPath.row]
            let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFilterImageCell
            cell.imageView.image = cellTools
            cell.nameLabel.text = cellFilter.name
            
            if self.currentFilter == cellFilter {
                cell.nameLabel.textColor = config.themeColor
            } else {
                cell.nameLabel.textColor = .lightGray
            }
            return cell
        }
        view.collectionDidSelect = { collection,sectionModel,indexPath in
            let cellFilter = PTImageEditorConfig.share.filters[indexPath.row]
            self.returnFrontVC() {
                self.filterHandler(cellFilter)
            }
        }
        return view
    }()
    
    var currentImage:UIImageView!
    
    public init(currentImage:UIImageView,currentFilter:PTHarBethFilter,viewControl: PTVideoEditorToolsModel) {
        self.currentImage = currentImage
        self.currentFilter = currentFilter
        super.init(viewControl: viewControl)
        generateFilterImages()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(filterCollectionView)
        filterCollectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.doneButton.snp.top).offset(-5)
            make.top.equalTo(self.titleStack.snp.bottom).offset(5)
        }
        
        PTGCDManager.gcdAfter(time: 0.35) {
            var rows = [PTRows]()
            self.thumbnailFilterImages.enumerated().forEach { index,value in
                let row = PTRows(cls: PTFilterImageCell.self,ID:PTFilterImageCell.ID,dataModel: value)
                rows.append(row)
            }
            
            let section = PTSection(rows: rows)
            self.filterCollectionView.showCollectionDetail(collectionData: [section])
        }
    }
    
    private func generateFilterImages() {
        let image = currentImage.image!
        let size: CGSize
        let ratio = (image.size.width / image.size.height)
        let fixLength: CGFloat = 200
        if ratio >= 1 {
            size = CGSize(width: fixLength * ratio, height: fixLength)
        } else {
            size = CGSize(width: fixLength, height: fixLength / ratio)
        }
        let thumbnailImage = image.pt.resize_vI(size) ?? PTAppBaseConfig.share.defaultEmptyImage
        
        PTGCDManager.gcdGobal {
            let filters = PTVideoEditorConfig.share.filters
            filters.enumerated().forEach { index,value in
                if value.type == .none {
                    self.thumbnailFilterImages.append(PTAppBaseConfig.share.defaultEmptyImage)
                } else {
                    PTHarBethFilter.share.texureSize = thumbnailImage.size
                    self.thumbnailFilterImages.append(value.getCurrentFilterImage(image: thumbnailImage))
                }
            }
        }
    }
}
