//
//  PTList+EX.swift
//  咪呐
//
//  Created by 九州所想 on 2022/3/23.
//  Copyright © 2022 MN. All rights reserved.
//

import UIKit

public class PTSection: NSObject {
    
    public var identifier: String = UUID().uuidString
    
    public var headerTitle: String?
    public var headerID: String?
    public var footerID: String?
    public var footerHeight: CGFloat? = CGFloat.leastNormalMagnitude
    public var headerHeight: CGFloat? = CGFloat.leastNormalMagnitude
    public var rows: [PTRows]?
    public var headerDataModel: AnyObject?
    public var footerDataModel: AnyObject?

    public init(headerTitle: String? = "",
                headerID: String? = "",
                footerID:String? = "",
                footerHeight:CGFloat? = CGFloat.leastNormalMagnitude,
                headerHeight:CGFloat? = CGFloat.leastNormalMagnitude,
                rows:[PTRows]? = nil,
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
        self.footerDataModel = footerDataModel
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PTSection else { return false }
        
        return self.identifier == other.identifier &&
               self.isContentEqual(to: other)
    }

    public override var hash: Int {
        return identifier.hashValue
    }

}

extension PTSection {
    
    func isContentEqual(to other: PTSection) -> Bool {
        
        // 基础属性比较
        if headerTitle != other.headerTitle { return false }
        if headerID != other.headerID { return false }
        if footerID != other.footerID { return false }
        if footerHeight != other.footerHeight { return false }
        if headerHeight != other.headerHeight { return false }
        
        // rows 数量比较（最关键）
        let lhsCount = rows?.count ?? 0
        let rhsCount = other.rows?.count ?? 0
        
        if lhsCount != rhsCount { return false }
        
        // 👉 这里只做“浅比较”（高性能）
        return true
    }
}

public class PTRows: NSObject {
    
    public var title = ""
    public var ID: String = ""
    public var dataModel: AnyObject?
    public var nibName = ""
    public var badge:Int = 0

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

extension UICollectionView {
    
    public static func sectionRows(rowsModel:[PTFusionCellModel]) -> [PTRows] {
        let rows = rowsModel.map { PTRows(title:$0.name,ID: $0.cellID,dataModel:$0) }
        return rows
    }
    
    public func registerClassCells(classs:[String:AnyClass]) {
        classs.allKeys().forEach { key in
            if let cellClass = classs[key] {
                self.register(cellClass, forCellWithReuseIdentifier: key)
            }
        }
    }
    
    public func registerNibCells(nib:[String:String]) {
        nib.allKeys().forEach { value in
            if let nibId = nib[value] {
                self.register(UINib(nibName: value, bundle: nil), forCellWithReuseIdentifier: nibId)
            }
        }
    }
    
    public func registerSupplementaryView(classs:[String:AnyClass],kind:String) {
        //kind:UICollectionView.elementKindSectionFooter && UICollectionView.elementKindSectionHeader
        classs.allKeys().forEach { value in
            self.register(classs[value].self, forSupplementaryViewOfKind: kind, withReuseIdentifier: value)
        }
    }
    
    public func registerSupplementaryView(ids:[String],viewClass:AnyClass,kind:String) {
        //kind:UICollectionView.elementKindSectionFooter && UICollectionView.elementKindSectionHeader
        ids.forEach { value in
            self.register(viewClass.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: value)
        }
    }
}
