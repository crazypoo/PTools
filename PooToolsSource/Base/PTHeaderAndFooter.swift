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
    
    public var switchValueChangeBlock:PTCellSwitchBlock?
    public var moreActionBlock:PTSectionMoreBlock?
    public var switchValue:Bool? {
        didSet {
            if let valueSwitch = dataContent.valueSwitch {
                valueSwitch.isOn = switchValue!
            }
        }
    }
    
    public var sectionModel:PTFusionCellModel? {
        didSet {
            dataContent.cellModel = sectionModel
        }
    }
    
    fileprivate lazy var dataContent:PTFusionCellContent = {
        let view = PTFusionCellContent()
        if let valueSwitch = view.valueSwitch {
            valueSwitch.valueChangeCallBack = { value in
                self.switchValueChangeBlock?(self.sectionModel!.name,valueSwitch)
            }
        }
        if let sectionMore = view.sectionMore {
            sectionMore.addActionHandlers { sender in
                self.moreActionBlock?(self.sectionModel!.name,sender)
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

