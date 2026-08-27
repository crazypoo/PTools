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
public class PTFusionHeader: PTBaseCollectionReusableView,@MainActor PTSupplementaryRegisterable {
    public static let ID = "PTFusionHeader"
    
    static public var kind: String { UICollectionView.elementKindSectionHeader }
    static public var reuseID: String { PTFusionHeader.ID }

    public var switchValueChangeBlock:PTCellSwitchBlock?
    public var moreActionBlock:PTSectionMoreBlock?
    public var switchValue:Bool? {
        didSet {
            let value = switchValue ?? false
            switch dataContent.activeSwitch {
            case let valueView as PTSwitch:
                valueView.isOn = value
            case let valueView as UISwitch:
                valueView.isOn = value
            default:
                break
            }
        }
    }
    
    public var sectionModel:PTFusionCellModel? {
        didSet {
            if let cellModel = sectionModel {
                dataContent.configure(model: cellModel)
            } else {
                dataContent.resetForReuse()
            }
        }
    }
    
    fileprivate lazy var dataContent:PTFusionContentView = {
        let view = PTFusionContentView()
        view.switchValueChangeBlock = { [weak self] name, view in
            self?.switchValueChangeBlock?(name,view)
        }
        view.moreButton.addActionHandlers { [weak self] sender in
            guard let self, let findCellModel = self.sectionModel else { return }
            self.moreActionBlock?(findCellModel.name,sender)
        }
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupHeaderUI()
    }

    private func setupHeaderUI() {
        addSubview(dataContent)
        dataContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHeaderUI()
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        switchValueChangeBlock = nil
        moreActionBlock = nil
        switchValue = nil
        sectionModel = nil
        dataContent.resetForReuse()
    }
}

@objcMembers
public class PTVersionFooter: PTBaseCollectionReusableView,@MainActor PTSupplementaryRegisterable {
    public static let ID = "PTVersionFooter"
    static public var kind: String { UICollectionView.elementKindSectionFooter }
    static public var reuseID: String { PTVersionFooter.ID }

    lazy var verionLabel:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        let appName = kAppDisplayName ?? ""
        let version = kAppVersion ?? ""
        let build = kAppBuildVersion ?? ""
        
        let att:ASAttributedString = """
        \(wrap: .embedding("""
        \("\(appName) \(version)(\(build))",.foreground(.lightGray),.font(PTAppBaseConfig.share.privacyNameFont),.paragraph(.alignment(.center)))
        \("PT Privacy".localized(),.foreground(.systemBlue),.font(PTAppBaseConfig.share.privacyNameFont),.paragraph(.alignment(.center)),.underline(.single,color: .systemBlue),.action {
                if let url = URL(string: PTAppBaseConfig.share.privacyURL) {
                    PTAppStoreFunction.jumpLink(url: url)
                }
        })
        """))
        """
        view.attributed.text = att
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupVersionFooterUI()
    }

    private func setupVersionFooterUI() {
        addSubview(verionLabel)
        verionLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(5)
        }
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupVersionFooterUI()
    }
}
