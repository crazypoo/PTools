//
//  PTImageListViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/10.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

class PTImageListViewController: PTBaseViewController {

    var images = ["http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg","http://p3.music.126.net/VDn1p3j4g2z4p16Gux969w==/2544269907756816.jpg"]
    
    lazy var listCollection:PTCollectionView = {
                                
        let collectionConfig = PTCollectionViewConfig()
        collectionConfig.viewType = .Gird
        collectionConfig.rowCount = 3
        collectionConfig.itemHeight = 88
        collectionConfig.cellLeadingSpace = 8
        collectionConfig.cellTrailingSpace = 8

        let view = PTCollectionView(viewConfig: collectionConfig)
        view.registerClassCells(classs: [PTImageCell.ID:PTImageCell.self])
        view.cellInCollection = { collectionView,sectionModel,indexPath in
            let itemRow = sectionModel.rows[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTImageCell
            cell.showAnimator = true
            cell.imageData = self.images[indexPath.row]
            return cell
        }
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(listCollection)
        listCollection.snp.makeConstraints { make in
#if POOTOOLS_NAVBARCONTROLLER
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
#else
            make.top.equalToSuperview()
#endif
            make.left.right.bottom.equalToSuperview()
        }
        loadCell()
    }
    
    func loadCell() {
        var section = [PTSection]()
        
        var rows = [PTRows]()
        images.enumerated().forEach { index,value in
            let row = PTRows(ID: PTImageCell.ID)
            rows.append(row)
        }

        section.append(PTSection(rows: rows))
        listCollection.showCollectionDetail(collectionData: section)
    }
}
