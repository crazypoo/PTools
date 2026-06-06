//
//  PTList+EX.swift
//  咪呐
//
//  Created by 九州所想 on 2022/3/23.
//  Copyright © 2022 MN. All rights reserved.
//

import UIKit

@MainActor
public final class PTSection: NSObject {
    
    nonisolated public let identifier: String
    public var layoutVersion: Int = 0

    public var headerTitle: String?
    public var headerID: String?
    public var footerID: String?
    public var footerHeight: CGFloat? = CGFloat.leastNormalMagnitude
    public var headerHeight: CGFloat? = CGFloat.leastNormalMagnitude
    public var rows: [PTRows]?
    public var headerDataModel: AnyObject?
    public var footerDataModel: AnyObject?

    public var footerClass: UICollectionReusableView.Type?
    public var headerClass: UICollectionReusableView.Type?
    
    public var decorationBackgroundColor: UIColor? = PTAppBaseConfig.share.decorationBackgroundColor
    public var decorationCornerRadius: CGFloat = PTAppBaseConfig.share.decorationBackgroundCornerRadius
    public var decorationBackgroundImage: UIImage?
    public var decorationShadowOpacity: Float = 0.08

    public init(identifier: String = UUID().uuidString,
                headerTitle: String? = "",
                headerID: String? = "",
                footerID: String? = "",
                footerHeight: CGFloat? = CGFloat.leastNormalMagnitude,
                headerHeight: CGFloat? = CGFloat.leastNormalMagnitude,
                rows: [PTRows]? = nil,
                headerDataModel: AnyObject? = nil,
                footerDataModel: AnyObject? = nil) {
        self.identifier = identifier
        self.headerTitle = headerTitle
        self.headerID = headerID
        self.footerID = footerID
        self.footerHeight = footerHeight
        self.headerHeight = headerHeight
        self.rows = rows
        self.headerDataModel = headerDataModel
        self.footerDataModel = footerDataModel
        super.init()
    }
    
    // 🌟 修复：Identity 仅仅依赖 identifier
    nonisolated public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(identifier)
        return hasher.finalize()
    }
    
    nonisolated public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PTSection else { return false }
        return self.identifier == other.identifier
    }

    public func isSameIdentity(as other: PTSection) -> Bool {
        return self.identifier == other.identifier
    }
    
    public var headerReuseID: String? {
        if let headerid = headerID, !headerid.stringIsEmpty() {
            return headerid
        }
        return (headerClass as? PTSupplementaryRegisterable.Type)?.reuseID
    }

    public var footerReuseID: String? {
        if let footerid = footerID, !footerid.stringIsEmpty() {
            return footerid
        }
        return (footerClass as? PTSupplementaryRegisterable.Type)?.reuseID
    }
    
    // 🌟 优化：业务层手动判断内容是否改变的辅助方法，不干扰底层 Diff 机制
    public func isContentEqual(to other: PTSection) -> Bool {
        if layoutVersion != other.layoutVersion { return false }
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
        return true
    }
}

// 🌟 同上：加入 @MainActor 和 final
@MainActor
public final class PTRows: NSObject {
    /// 身份（唯一标识）
    nonisolated public let diffId: String
    /// 内容版本（用于业务层判断内容是否改变）
    public var diffHash: Int = 0

    public var title = ""
    public var ID: String = ""
    public var dataModel: AnyObject?
    public var nibName = ""
    public var badge: Int = 0
    
    public var cellClass: UICollectionViewCell.Type?

    public init(title: String = "",
                nibName: String = "",
                ID: String = "",
                diffId: String = UUID().uuidString,
                diffHash: Int = 0,
                dataModel: AnyObject? = nil,
                badge: Int = 0) {
        self.title = title
        self.ID = ID
        self.dataModel = dataModel
        self.nibName = nibName
        self.badge = badge
        self.diffId = diffId
        self.diffHash = diffHash
        super.init()
    }
    
    public var reuseID: String {
        if let cls = cellClass as? PTCellRegisterable.Type {
            return cls.reuseID
        }
        return ID
    }
    
    // 🌟🌟🌟 核心修复：移除 diffHash！绝对不能让 Diffable DataSource 的哈希随状态突变！
    nonisolated public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(diffId)
        return hasher.finalize()
    }
    
    // 🌟🌟🌟 核心修复：isEqual 也只判断 Identity。保证 reloadItems 时平滑更新！
    nonisolated public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PTRows else { return false }
        return self.diffId == other.diffId
    }
    
    /// 判断是不是同一个 cell（身份一致）
    public func isSameIdentity(as other: PTRows) -> Bool {
        return self.diffId == other.diffId
    }
    
    /// 判断内容是否有变动（提供给你的业务侧做按需刷新判断）
    public func isContentEqual(to other: PTRows) -> Bool {
        return self.diffHash == other.diffHash
    }
}

extension PTRows {
    public convenience init(model: AnyObject,
                            reuseID: String = "",
                            title: String = "",
                            nibName: String = "",
                            badge: Int = 0) {
        if let diffModel = model as? PTDiffableModel {
            self.init(title: title,
                      nibName: nibName,
                      ID: reuseID,
                      diffId: diffModel.diffId,
                      diffHash: diffModel.diffHash,
                      dataModel: model,
                      badge: badge)
        } else {
            self.init(title: title,
                      nibName: nibName,
                      ID: reuseID,
                      dataModel: model,
                      badge: badge)
        }
    }
}

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
