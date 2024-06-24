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
    public var headerID: String?
    public var footerID: String?
    public var footerHeight: CGFloat? = CGFloat.leastNormalMagnitude
    public var headerHeight: CGFloat? = CGFloat.leastNormalMagnitude
    public var rows: [PTRows]!
    public var headerDataModel: AnyObject?
    public var footerDataModel: AnyObject?

    public init(headerTitle: String? = "",
                headerID: String? = "",
                footerID:String? = "",
                footerHeight:CGFloat? = CGFloat.leastNormalMagnitude,
                headerHeight:CGFloat? = CGFloat.leastNormalMagnitude,
                rows:[PTRows]!,
                headerDataModel:AnyObject? = nil,
                footerDataModel:AnyObject? = nil) {
        super.init()
        
        self.headerTitle = headerTitle
        self.headerID = headerID
        self.footerID = footerID
        self.footerHeight = footerHeight
        self.headerHeight = headerHeight
        self.rows = rows
        self.headerDataModel = headerDataModel
        self.footerDataModel = headerDataModel
    }
}


open class PTRows: NSObject {
    
    open var title = ""
    open var ID: String = ""
    open var dataModel: AnyObject?
    open var nibName = ""
    open var badge:Int = 0

    public init(title: String = "",
                nibName:String? = "",
                ID: String? = "",
                dataModel:AnyObject? = nil,
                badge:Int? = 0) {
        super.init()
        self.title = title
        self.ID = ID!
        self.dataModel = dataModel
        self.nibName = nibName!
        self.badge = badge!
    }
}

extension UITableView {
//    //MARK: 註冊TableView的Cell
//    ///註冊TableView的Cell
//    public func pt_register(by ptSections: [PTSection]) {
//        
//        ptSections.forEach { [weak self] (tmpSection) in
//            // 注册 hederView
//            if let cls = tmpSection.headerCls, let id = tmpSection.headerID {
//                self?.register(cls.self,
//                         forHeaderFooterViewReuseIdentifier: id)
//            }
//            // 注册 cell
//            tmpSection.rows.forEach { (tmpRow) in
//                self?.register(tmpRow.cls.self,
//                         forCellReuseIdentifier: tmpRow.ID)
//            }
//        }
//    }
}

extension UICollectionView {
    
    public static func sectionRows(rowsModel:[PTFusionCellModel]) -> [PTRows] {
        var rows = [PTRows]()
        rowsModel.enumerated().forEach { index,value in
            let row = PTRows(title:value.name,ID: value.cellID,dataModel: value)
            rows.append(row)
        }
        return rows
    }
    
    public func registerClassCells(classs:[String:AnyClass]) {
        classs.allKeys().enumerated().forEach { index,value in
            self.register(classs[value].self, forCellWithReuseIdentifier: value)
        }
    }
    
    public func registerNibCells(nib:[String:String]) {
        nib.allKeys().enumerated().forEach { index,value in
            self.register(UINib.init(nibName: value, bundle: nil), forCellWithReuseIdentifier: nib[value]!)
        }
    }
    
    public func registerSupplementaryView(classs:[String:AnyClass],kind:String) {
        //kind:UICollectionView.elementKindSectionFooter && UICollectionView.elementKindSectionHeader
        classs.allKeys().enumerated().forEach { index,value in
            self.register(classs[value].self, forSupplementaryViewOfKind: kind, withReuseIdentifier: value)
        }
    }
    
    public func registerSupplementaryView(ids:[String],viewClass:AnyClass,kind:String) {
        //kind:UICollectionView.elementKindSectionFooter && UICollectionView.elementKindSectionHeader
        ids.enumerated().forEach { index,value in
            self.register(viewClass.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: value)
        }
    }
}
