//
//  PTFusionHeader.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 4/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import AttributedString

@objcMembers
public class PTFusionHeader: PTBaseCollectionReusableView {
    public static let ID = "PTFusionHeader"
    
    open var switchValueChangeBlock:PTCellSwitchBlock?
    open var moreActionBlock:PTSectionMoreBlock?
    open var switchValue:Bool? {
        didSet {
            dataContent.valueSwitch.isOn = switchValue!
        }
    }
    
    open var sectionModel:PTFusionCellModel? {
        didSet {
            dataContent.cellModel = sectionModel
        }
    }
    
    fileprivate lazy var dataContent:PTFusionCellContent = {
        let view = PTFusionCellContent()
        view.valueSwitch.addSwitchAction { sender in
            if self.switchValueChangeBlock != nil {
                self.switchValueChangeBlock!(self.sectionModel!.name,sender)
            }
        }
        view.sectionMore.addActionHandlers { sender in
            if self.moreActionBlock != nil {
                self.moreActionBlock!(self.sectionModel!.name,sender)
            }
        }
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(dataContent)
        dataContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@objcMembers
public class PTVersionFooter: PTBaseCollectionReusableView {
    public static let ID = "PTVersionFooter"
    
    lazy var verionLabel:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        
        let att:ASAttributedString = """
        \(wrap: .embedding("""
        \("\(kAppDisplayName! + " " + kAppVersion! + "(\(kAppBuildVersion!))")",.foreground(.lightGray),.font(PTAppBaseConfig.share.privacyNameFont),.paragraph(.alignment(.center)))
        \("PT Privacy".localized(),.foreground(.systemBlue),.font(PTAppBaseConfig.share.privacyNameFont),.paragraph(.alignment(.center)),.underline(.single,color: .systemBlue),.action {
                let url = URL(string: PTAppBaseConfig.share.privacyURL)!
                PTAppStoreFunction.jumpLink(url: url)
        })
        """))
        """
        view.attributed.text = att
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(verionLabel)
        verionLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(5)
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

