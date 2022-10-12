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
    public var headerPlaceholder:String?
    public var headerCls: AnyClass?
    public var headerID: String?
    public var footerCls: AnyClass?
    public var footerID: String?
    public var footerHeight: CGFloat? = CGFloat.leastNormalMagnitude
    public var headerHeight: CGFloat? = CGFloat.leastNormalMagnitude
    public var rows: [PTRows]!
    public var haveDisclosureIndicator:Bool? = false
    public var disclosureIndicatorTitle:String?
    public var disclosureIndicatorImage:String? = ""
    public var disclosureIndicatorSelectImage:String? = ""
    public var isSelectIndicator:Bool? = false

    public init(headerTitle: String? = "",
                headerPlaceholder: String? = "",
                headerCls: AnyClass? = nil,
                headerID: String? = "",
                footerCls:AnyClass? = nil,
                footerID:String? = "",
                footerHeight:CGFloat? = CGFloat.leastNormalMagnitude,
                headerHeight:CGFloat? = CGFloat.leastNormalMagnitude,
                rows:[PTRows]!,
                haveDisclosureIndicator:Bool? = false,
                disclosureIndicatorTitle:String? = "",
                disclosureIndicatorImage:String? = "",
                disclosureIndicatorSelectImage:String? = "",
                isSelectIndicator:Bool? = false
         )
    {
        super.init()
        
        self.headerTitle = headerTitle
        self.headerPlaceholder = headerPlaceholder
        self.headerCls = headerCls
        self.headerID = headerID
        self.footerCls = footerCls
        self.footerID = footerID
        self.footerHeight = footerHeight
        self.headerHeight = headerHeight
        self.rows = rows
        self.haveDisclosureIndicator = haveDisclosureIndicator
        self.disclosureIndicatorTitle = disclosureIndicatorTitle
        self.disclosureIndicatorImage = disclosureIndicatorImage
        self.disclosureIndicatorSelectImage = disclosureIndicatorSelectImage
        self.isSelectIndicator = isSelectIndicator
    }
}


open class PTRows: NSObject {
    
    open var title = ""
    open var placeholder = ""
    open var cls: AnyClass?
    open var ID: String = ""
    open var dataModel: AnyObject?
    open var titleColor = UIColor.randomColor
    open var haveDisclosureIndicator = false
    open var haveSwitchView = false
    open var textEdit = false
    open var keyboard:UIKeyboardType = .default
    open var infoColor = UIColor.randomColor
    open var iconName = ""
    open var nibName = ""
    open var content = ""
    open var contentColor = UIColor.randomColor
    open var badge:Int = 0

    public init(title: String = "",
         placeholder: String = "",
         content:String = "",
         cls: AnyClass? = nil,
         nibName:String? = "",
         ID: String? = "",
         titleColor:UIColor? = UIColor.randomColor,
         haveDisclosureIndicator:Bool? = false,
         haveSwitchView:Bool? = false,
         textEdit:Bool? = false,
         keyboard:UIKeyboardType? = .default,
         infoColor:UIColor? = UIColor.randomColor,
         contentColor:UIColor? = UIColor.randomColor,
         iconName:String? = "",
         dataModel:AnyObject? = nil,
         badge:Int? = 0) {
        super.init()
        self.title = title
        self.placeholder = placeholder
        self.ID = ID!
        self.cls = cls
        self.titleColor = titleColor!
        self.haveDisclosureIndicator = haveDisclosureIndicator!
        self.textEdit = textEdit!
        self.keyboard = keyboard!
        self.infoColor = infoColor!
        self.iconName = iconName!
        self.dataModel = dataModel
        self.nibName = nibName!
        self.haveSwitchView = haveSwitchView!
        self.content = content
        self.contentColor = contentColor!
        self.badge = badge!
    }
}

extension UITableView {
    /// - Parameter bkSections:
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
    /// - Parameter bkSections:
    public func pt_register(by ptSections: [PTSection]) {
        
        ptSections.forEach { [weak self] (tmpSection) in
            // 注册 hederView
            if let cls = tmpSection.headerCls, let id = tmpSection.headerID {
                self?.register(cls.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: id)
            }
            else
            {
                PTLocalConsoleFunction.share.pNSLog("NoHeader")
            }
            
            if let cls = tmpSection.footerCls, let id = tmpSection.footerID {
                self?.register(cls.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: id)
            }
            else
            {
                PTLocalConsoleFunction.share.pNSLog("NoFooter")
            }

            // 注册 cell
            tmpSection.rows.forEach { (tmpRow) in
                if tmpRow.nibName.stringIsEmpty()
                {
                    self?.register(tmpRow.cls.self, forCellWithReuseIdentifier:  tmpRow.ID)
                }
                else
                {
                    self?.register(UINib.init(nibName: tmpRow.nibName, bundle: nil), forCellWithReuseIdentifier: tmpRow.ID)
                }
            }
        }
    }
}
