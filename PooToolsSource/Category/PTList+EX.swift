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
    public var layoutVersion: Int = 0   // 👈 新增

    public var headerTitle: String?
    public var headerID: String?
    public var footerID: String?
    public var footerHeight: CGFloat? = CGFloat.leastNormalMagnitude
    public var headerHeight: CGFloat? = CGFloat.leastNormalMagnitude
    public var rows: [PTRows]?
    public var headerDataModel: AnyObject?
    public var footerDataModel: AnyObject?

    public var footerClass:UICollectionReusableView.Type?
    public var headerClass:UICollectionReusableView.Type?
    
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
    
    public override var hash: Int {
        return identifier.hashValue
    }

    public func isSameIdentity(as other: PTSection) -> Bool {
        return self.identifier == other.identifier
    }
    
    public var headerReuseID: String? {
        if let headerid = headerID, !headerid.stringIsEmpty() {
            return headerid
        } else {
            return (headerClass as? PTSupplementaryRegisterable.Type)?.reuseID
        }
    }

    public var footerReuseID: String? {
        if let footerid = footerID, !footerid.stringIsEmpty() {
            return footerid
        } else {
            return (footerClass as? PTSupplementaryRegisterable.Type)?.reuseID
        }
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

        let lhs = rows ?? []
        let rhs = other.rows ?? []
        
        if lhs.count != rhs.count { return false }

        for (l, r) in zip(lhs, rhs) {
            if !l.isSameIdentity(as: r) { return false }
            if !l.isContentEqual(to: r) { return false }
        }

        // 👉 这里只做“浅比较”（高性能）
        return true
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PTSection else { return false }
        return self.identifier == other.identifier
    }
}

public class PTRows: NSObject {
    /// 🔥 identity（唯一标识）
    public var diffId: String = ""
    /// 🔥 内容版本（核心）
    public var diffHash: Int = 0

    public var title = ""
    public var ID: String = ""
    public var dataModel: AnyObject?
    public var nibName = ""
    public var badge:Int = 0
    
    public var cellClass:UICollectionViewCell.Type?

    public init(title: String = "",
                nibName:String = "",
                ID: String = "",
                diffId: String = UUID().uuidString,
                diffHash:Int = 0,
                dataModel:AnyObject? = nil,
                badge:Int = 0) {
        super.init()
        self.title = title
        self.ID = ID
        self.dataModel = dataModel
        self.nibName = nibName
        self.badge = badge
        self.diffId = diffId
        self.diffHash = diffHash
    }
    
    /// 🔥 reuseID（自动生成）
    public var reuseID: String {
        if let cls = cellClass as? PTCellRegisterable.Type {
            return cls.reuseID
        }
        return ID
    }
}

extension PTRows {

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(diffId)
        hasher.combine(diffHash) // 👈 关键点：把 diffHash 加入哈希
        return hasher.finalize()
    }

    /// identity（是不是同一个 cell）
    func isSameIdentity(as other: PTRows) -> Bool {
        return self.diffId == other.diffId
    }
    
    func isContentEqual(to other: PTRows) -> Bool {
        return diffHash == other.diffHash
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PTRows else { return false }
        // 👈 关键点：ID 相同且 Hash 相同，才认为是完全一样的数据。
        // 如果外部修改了 model 的数据并更新了 diffHash，DiffableDataSource 会自动帮你刷新这个 Cell！
        return self.diffId == other.diffId && self.diffHash == other.diffHash
    }
}

extension PTRows {
    
    convenience init(model: AnyObject,
                     reuseID: String = "",
                     title: String = "",
                     nibName: String = "",
                     badge:Int = 0) {
        
        if let diffModel = model as? PTDiffableModel {
            self.init(title: title,nibName: nibName,ID: reuseID,diffId: diffModel.diffId,diffHash: diffModel.diffHash,dataModel: model,badge: badge)
        } else {
            self.init(title: title,nibName: nibName,ID: reuseID,dataModel: model,badge: badge)
        }
    }
}

// 告诉编译器：跳过并发安全检查，我保证它们是安全的
extension PTSection: @unchecked Sendable {}
extension PTRows: @unchecked Sendable {}

public protocol PTCellRegisterable {
    static var reuseID: String { get }
}

public extension PTCellRegisterable {
    static var reuseID: String {
        String(describing: Self.self)
    }
}

public protocol PTSupplementaryRegisterable {
    static var reuseID: String { get }
    static var kind: String { get }
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
