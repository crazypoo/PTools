//
//  PTList+EX.swift
//  咪呐
//
//  Created by 九州所想 on 2022/3/23.
//  Copyright © 2022 MN. All rights reserved.
//

import UIKit

struct PTSection {
    var headerTitle: String?
    var headerPlaceholder:String?
    var headerCls: AnyClass?
    var headerID: String?
    var footerCls: AnyClass?
    var footerID: String?
    var footerHeight: CGFloat? = CGFloat.leastNormalMagnitude
    var headerHeight: CGFloat? = CGFloat.leastNormalMagnitude
    var rows: [PTRows]
    var haveDisclosureIndicator:Bool? = false
    var disclosureIndicatorTitle:String?
    var disclosureIndicatorImage:String? = ""
    var disclosureIndicatorSelectImage:String? = ""
    var isSelectIndicator:Bool? = false
}

class PTRows: NSObject {
    
    var title = ""
    var placeholder = ""
    var cls: AnyClass?
    var ID: String = ""
    var dataModel: AnyObject?
    var titleColor = UIColor.randomColor
    var haveDisclosureIndicator = false
    var haveSwitchView = false
    var textEdit = false
    var keyboard:UIKeyboardType = .default
    var infoColor = UIColor.randomColor
    var iconName = ""
    var nibName = ""
    var content = ""
    var contentColor = UIColor.randomColor
    var badge:Int = 0

    init(title: String = "",
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
    func pt_register(by ptSections: [PTSection]) {
        
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
    func pt_register(by ptSections: [PTSection]) {
        
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
