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
public class PTFusionHeader: PTBaseCollectionReusableView,PTSupplementaryRegisterable {
    public static let ID = "PTFusionHeader"
    
    static public var kind: String { UICollectionView.elementKindSectionHeader }
    static public var reuseID: String { PTFusionHeader.ID }

    public var switchValueChangeBlock:PTCellSwitchBlock?
    public var moreActionBlock:PTSectionMoreBlock?
    public var switchValue:Bool? {
        didSet {
            if let findValue = switchValue {
                switch dataContent.activeSwitch {
                case let valueView as PTSwitch:
                    valueView.isOn = findValue
                case let valueView as UISwitch:
                    valueView.isOn = findValue
                default:break
                }
            }
        }
    }
    
    public var sectionModel:PTFusionCellModel? {
        didSet {
            if let cellModel = sectionModel {
                dataContent.configure(model: cellModel)
            }
        }
    }
    
    fileprivate lazy var dataContent:PTFusionContentView = {
        let view = PTFusionContentView()
        view.switchValueChangeBlock = { name,view in
            self.switchValueChangeBlock?(name,view)
        }
        view.moreButton.addActionHandlers { sender in
            if let findCellModel = self.sectionModel {
                self.moreActionBlock?(findCellModel.name,sender)
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
public class PTVersionFooter: PTBaseCollectionReusableView,PTSupplementaryRegisterable {
    public static let ID = "PTVersionFooter"
    static public var kind: String { UICollectionView.elementKindSectionFooter }
    static public var reuseID: String { PTVersionFooter.ID }

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

