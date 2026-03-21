//
//  PTList+EX.swift
//  咪呐
//
//  Created by 九州所想 on 2022/3/23.
//  Copyright © 2022 MN. All rights reserved.
//

import UIKit

public struct PTSection: Hashable {

    public var identifier: String

    public var headerTitle: String?
    public var headerID: String?
    public var footerID: String?
    public var footerHeight: CGFloat?
    public var headerHeight: CGFloat?

    public var rows: [PTRows]?

    public var headerDataModel: AnyHashable?
    public var footerDataModel: AnyHashable?

    public init(identifier: String = UUID().uuidString,
                headerTitle: String? = nil,
                headerID: String? = nil,
                footerID: String? = nil,
                footerHeight: CGFloat? = nil,
                headerHeight: CGFloat? = nil,
                rows: [PTRows]? = nil,
                headerDataModel: AnyHashable? = nil,
                footerDataModel: AnyHashable? = nil) {
        self.identifier = identifier
        self.headerTitle = headerTitle
        self.headerID = headerID
        self.footerID = footerID
        self.footerHeight = footerHeight
        self.headerHeight = headerHeight
        self.rows = rows
        self.headerDataModel = headerDataModel
        self.footerDataModel = footerDataModel
    }
    
    public static func == (lhs: PTSection, rhs: PTSection) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
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
                nibName:String = "",
                ID: String = "",
                dataModel:AnyObject? = nil,
                badge:Int = 0) {
        super.init()
        self.title = title
        self.ID = ID
        self.dataModel = dataModel
        self.nibName = nibName
        self.badge = badge
    }
}

extension UICollectionView {
    
    public static func sectionRows(rowsModel:[PTFusionCellModel]) -> [PTRows] {
        let rows = rowsModel.map { PTRows(title:$0.name,ID: $0.cellID ?? "",dataModel:$0) }
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
