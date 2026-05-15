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
    
    private var currentFilter: PTHarBethFilter! = PTHarBethFilter.none
    
    private var thumbnailFilterImages: [UIImage] = []

    private lazy var filterCollectionView : PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Custom

        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTFilterImageCell.ID:PTFilterImageCell.self])
        view.customerLayout = { sectionIndex,sectionModel in
            return UICollectionView.horizontalLayout(data: sectionModel.rows,itemOriginalX: PTAppBaseConfig.share.defaultViewSpace,itemWidth: 88,itemHeight: 108,topContentSpace: 0,bottomContentSpace: 0,itemLeadingSpace: 10)
        }
        view.cellInCollection = { collection,sectionModel,indexPath in
            let config = PTVideoEditorConfig.share
            if let itemRow = sectionModel.rows?[indexPath.row],let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTFilterImageCell {
                let cellFilter = PTVideoEditorConfig.share.filters[indexPath.row]
                cell.imageView.loadImage(contentData: itemRow.dataModel as Any,borderWidth: 0,borderColor: .clear)
                cell.nameLabel.text = cellFilter.name
                if self.currentFilter == cellFilter {
                    cell.nameLabel.textColor = config.themeColor
                } else {
                    cell.nameLabel.textColor = .lightGray
                }
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { collection,sectionModel,indexPath in
            self.currentFilter = PTVideoEditorConfig.share.filters[indexPath.row]
            let rows = self.filterCollectionView.getAllRows(in: 0)
            self.filterCollectionView.reloadRows(rows, in: 0)
        }
        return view
    }()
    
    var currentImage:UIImageView!
    
    public init(currentImage:UIImageView,currentFilter:PTHarBethFilter,viewControl: PTVideoEditorToolsModel) {
        self.currentImage = currentImage
        self.currentFilter = currentFilter
        super.init(viewControl: viewControl)
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
        
        generateFilterImages {
            Task { @MainActor in
                let rows = self.thumbnailFilterImages.map { PTRows(ID:PTFilterImageCell.ID,dataModel: $0) }
                let section = PTSection(rows: rows)
                self.filterCollectionView.showCollectionDetail(collectionData: [section])
            }
        }
        
        doneButton.addActionHandlers { sender in
            self.returnFrontVC {
                self.filterHandler(self.currentFilter)
            }
        }
    }
    
    private func generateFilterImages(finish:@escaping PTActionTask) {
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
        
        PTVideoEditorConfig.share.filters.enumerated().forEach { index,value in
            switch value.type {
            case .none:
                self.thumbnailFilterImages.insert(PTAppBaseConfig.share.defaultEmptyImage, at: 0)
            default:
                PTHarBethFilter.share.texureSize = thumbnailImage.size
                self.thumbnailFilterImages.append(value.getCurrentFilterImage(image: thumbnailImage))
            }
            if index == (PTVideoEditorConfig.share.filters.count - 1) {
                finish()
            }
        }
    }
}
