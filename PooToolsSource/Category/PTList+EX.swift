//
//  PTList+EX.swift
//  咪呐
//
//  Created by 九州所想 on 2022/3/23.
//  Copyright © 2022 MN. All rights reserved.
//

import UIKit

open class PTSection: NSObject {
    
    public var headerTitle: String?
    public var headerCls: AnyClass?
    public var headerID: String?
    public var footerCls: AnyClass?
    public var footerID: String?
    public var footerHeight: CGFloat? = CGFloat.leastNormalMagnitude
    public var headerHeight: CGFloat? = CGFloat.leastNormalMagnitude
    public var rows: [PTRows]!
    public var headerDataModel: AnyObject?

    public init(headerTitle: String? = "",
                headerCls: AnyClass? = nil,
                headerID: String? = "",
                footerCls:AnyClass? = nil,
                footerID:String? = "",
                footerHeight:CGFloat? = CGFloat.leastNormalMagnitude,
                headerHeight:CGFloat? = CGFloat.leastNormalMagnitude,
                rows:[PTRows]!,
                headerDataModel:AnyObject? = nil) {
        super.init()
        
        self.headerTitle = headerTitle
        self.headerCls = headerCls
        self.headerID = headerID
        self.footerCls = footerCls
        self.footerID = footerID
        self.footerHeight = footerHeight
        self.headerHeight = headerHeight
        self.rows = rows
        self.headerDataModel = headerDataModel
    }
}


open class PTRows: NSObject {
    
    open var title = ""
    open var cls: AnyClass?
    open var ID: String = ""
    open var dataModel: AnyObject?
    open var nibName = ""
    open var badge:Int = 0

    public init(title: String = "",
                cls: AnyClass? = nil,
                nibName:String? = "",
                ID: String? = "",
                dataModel:AnyObject? = nil,
                badge:Int? = 0) {
        super.init()
        self.title = title
        self.ID = ID!
        self.cls = cls
        self.dataModel = dataModel
        self.nibName = nibName!
        self.badge = badge!
    }
}

extension UITableView {
    //MARK: 註冊TableView的Cell
    ///註冊TableView的Cell
    public func pt_register(by ptSections: [PTSection]) {
        
        ptSections.forEach { [weak self] (tmpSection) in
            // 注册 hederView
            if let cls = tmpSection.headerCls, let id = tmpSection.headerID {
                self?.register(cls.self,
                         forHeaderFooterViewReuseIdentifier: id)
            }
            // 注册 cell
            tmpSection.rows.forEach { (tmpRow) in
                self?.register(tmpRow.cls.self,
                         forCellReuseIdentifier: tmpRow.ID)
            }
        }
    }
}

extension UICollectionView {
    
    public static func sectionRows(rowsModel:[PTFusionCellModel]) -> [PTRows] {
        var rows = [PTRows]()
        rowsModel.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,cls:value.cellClass,ID: value.cellID,dataModel: value)
            rows.append(row)
        }
        return rows
    }
    
    //MARK: 註冊CollectionView的Cell
    ///註冊CollectionView的Cell
    public func pt_register(by ptSections: [PTSection]) {
        
        ptSections.forEach { [weak self] (tmpSection) in
            // 注册 hederView
            if let cls = tmpSection.headerCls, let id = tmpSection.headerID {
                self?.register(cls.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: id)
            }
            
            if let cls = tmpSection.footerCls, let id = tmpSection.footerID {
                self?.register(cls.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: id)
            }

            // 注册 cell
            tmpSection.rows.forEach { (tmpRow) in
                if tmpRow.nibName.stringIsEmpty() {
                    self?.register(tmpRow.cls.self, forCellWithReuseIdentifier:  tmpRow.ID)
                } else {
                    self?.register(UINib.init(nibName: tmpRow.nibName, bundle: nil), forCellWithReuseIdentifier: tmpRow.ID)
                }
            }
        }
    }
}
