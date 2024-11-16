//
//  PTWhatsNewsViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 24/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import AttributedString
import SnapKit
import SwifterSwift

@objc public enum PTWhatsNewsPresentationOption:Int {
    /// 版本不同就显示
    case always
    /// 大版本差异显示
    case majorVersion
    /// 不会显示
    case never
    /// 长期显示
    case debug
}

@objcMembers
public class PTWhatsNews:NSObject {

    public static func markCurrentVersionAsPresented() {
        PTCoreUserDefultsWrapper.PTWhatNewsLatestAppVersionPresented = kAppVersion!
    }

    public class func shouldPresent(with option: PTWhatsNewsPresentationOption = .always, currentVersion: String? = kAppVersion) -> Bool {
        guard let currentAppVersion = currentVersion else { return false }
        let previousAppVersion = PTCoreUserDefultsWrapper.PTWhatNewsLatestAppVersionPresented
        let didUpdate = previousAppVersion != currentAppVersion
        switch option {
        case .debug: return true
        case .never: return false
        case .majorVersion: return didUpdate && didChangeMajorVersion(previous: previousAppVersion, current: currentAppVersion)
        case .always: return didUpdate
        }
    }

    private static func didChangeMajorVersion(previous: String?, current: String?) -> Bool {
        guard let previous = previous else { return true }
        guard let previousMajor = previous.split(separator: ".").first, let previousMajorInt = Int(previousMajor) else { return false }
        guard let currentMajor = current?.split(separator: ".").first, let currentMajorInt = Int(currentMajor) else { return false }
        return currentMajorInt > previousMajorInt
    }
}

@objcMembers
public class PTWhatsNewsTitleItem:NSObject {
    public var title:String = ""
    public var titleFont:UIFont = UIFont.appfont(size: 26,bold: true)
    public var titleColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)
    public var atts:ASAttributedString?
    public var textAlignment:NSTextAlignment = .center
    
    public init(title: String = "What's News", titleFont: UIFont = UIFont.appfont(size: 26,bold: true), titleColor: UIColor = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white), atts: ASAttributedString? = nil, textAlignment:NSTextAlignment = .center) {
        self.title = title
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.atts = atts
        self.textAlignment = textAlignment
    }
}

@objcMembers
public class PTWhatsNewsIKnowItem:NSObject {
    public var title:String = ""
    public var titleFont:UIFont = UIFont.appfont(size: 16,bold: true)
    public var titleColor:UIColor = .white
    public var backgroundColor:UIColor = .systemBlue
    public var itemLayout:PTSheetButtonStyle = .leftImageRightTitle
    public var image:Any?
    public var itemSpace:CGFloat = 10
    public var privacy:String = ""
    public var privacyURL:String = ""
    public var privacyFont:UIFont = .appfont(size: 14)
    public var privacyColor:UIColor = .systemBlue

    public init(title: String = "I Know",
                titleFont: UIFont = UIFont.appfont(size: 16,bold: true),
                titleColor: UIColor = .white,
                backgroundColor: UIColor = .systemBlue,
                itemLayout: PTSheetButtonStyle = .leftImageRightTitle,
                image: Any? = nil,
                itemSpace: CGFloat = 10,
                privacy:String = "",
                privacyURL:String = "",
                privacyFont:UIFont = .appfont(size: 14),
                privacyColor:UIColor = .systemBlue) {
        self.title = title
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.backgroundColor = backgroundColor
        self.itemLayout = itemLayout
        self.image = image
        self.itemSpace = itemSpace
        self.privacy = privacy
        self.privacyURL = privacyURL
        self.privacyFont = privacyFont
        self.privacyColor = privacyColor
    }
}

@objcMembers
public class PTWhatsNewsItem:NSObject {
    public var title:String = ""
    public var titleFont:UIFont = UIFont.appfont(size: 20,bold: true)
    public var titleColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white)
    public var contentSpace:CGFloat = 2
    public var subTitle:String = ""
    public var subTitleFont:UIFont = UIFont.appfont(size: 16,bold: true)
    public var subTitleColor:UIColor = .lightGray
    public var newsImage:Any?
    
    public init(title: String = "",
                titleFont: UIFont = UIFont.appfont(size: 20,bold: true),
                titleColor: UIColor = PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white),
                contentSpace: CGFloat = 2,
                subTitle: String = "",
                subTitleFont: UIFont = UIFont.appfont(size: 16,bold: true),
                subTitleColor: UIColor = .lightGray,
                newsImage: Any? = nil) {
        self.title = title
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.contentSpace = contentSpace
        self.subTitle = subTitle
        self.subTitleFont = subTitleFont
        self.subTitleColor = subTitleColor
        self.newsImage = newsImage
    }
}

fileprivate class PTWhatsNewsCell:PTBaseNormalCell {
    static let ID = "PTWhatsNewsCell"
    static let CellBaseHeight:CGFloat = 64

    var cellModel: PTWhatsNewsItem? {
        didSet {
            
            if cellModel?.newsImage != nil {
                imageView.loadImage(contentData: cellModel!.newsImage as Any)
            } else {
                imageView.image = nil
            }
            
            let attTitle:ASAttributedString = ASAttributedString("\(cellModel!.title)",.paragraph(.alignment(.left),.lineSpacing(cellModel!.contentSpace)),.font(cellModel!.titleFont),.foreground(cellModel!.titleColor))
            
            let attSubTitle:ASAttributedString = ASAttributedString("\(!cellModel!.title.stringIsEmpty() ? "\n\(cellModel!.subTitle)" : cellModel!.subTitle)",.paragraph(.alignment(.left),.lineSpacing(cellModel!.contentSpace)),.font(cellModel!.subTitleFont),.foreground(cellModel!.subTitleColor))

            var totalAtt:ASAttributedString = ASAttributedString(string: "")

            if !cellModel!.title.stringIsEmpty() {
                totalAtt += attTitle
            }
            
            if !cellModel!.subTitle.stringIsEmpty() {
                totalAtt += attSubTitle
            }
            
            titleLabel.attributedText = totalAtt.value
            
            layoutSubviews()
        }
    }
    
    lazy var imageView : UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    lazy var titleLabel:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubviews([imageView,titleLabel])
        imageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview().inset(7.5)
            make.height.equalTo(49)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(imageView.snp.right).offset(10)
            make.top.bottom.equalToSuperview().inset(7.5)
            make.right.equalToSuperview()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if cellModel != nil {
            if cellModel!.newsImage != nil {
                imageView.isHidden = false
                imageView.snp.makeConstraints { make in
                    make.left.equalToSuperview()
                    make.top.equalToSuperview().inset(7.5)
                    make.height.equalTo(49)
                }
                
                titleLabel.snp.makeConstraints { make in
                    make.left.equalTo(self.imageView.snp.right).offset(10)
                    make.top.bottom.equalToSuperview().inset(7.5)
                    make.right.equalToSuperview()
                }
            } else {
                imageView.isHidden = true
                imageView.snp.makeConstraints { make in
                    make.left.equalToSuperview()
                    make.top.equalToSuperview().inset(7.5)
                    make.height.equalTo(49)
                    make.width.equalTo(0)
                }
                
                titleLabel.snp.makeConstraints { make in
                    make.left.equalTo(self.imageView.snp.right)
                    make.top.bottom.equalToSuperview().inset(7.5)
                    make.right.equalToSuperview()
                }
            }
        }
    }
}

@objcMembers
public class PTWhatsNewsViewController: PTBaseViewController {

    public var privacyTapHandler:PTActionTask?
    public var iKnowTapHandler:PTActionTask?

    public func setContentLRSpace(@PTClampedProperyWrapper(range:0...100) values:CGFloat = 48) {
        contentViewSpace = values
    }
    private var contentViewSpace:CGFloat = 48

    fileprivate lazy var titleLabel:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }()
    
    fileprivate lazy var iKnowButton:PTLayoutButton = {
        let view = PTLayoutButton()
        view.cornerStyle = .small
        view.cornerRadius = 10
        view.addActionHandlers { sender in
            self.returnFrontVC {
                if self.iKnowTapHandler != nil {
                    self.iKnowTapHandler!()
                }
            }
        }
        return view
    }()
    
    fileprivate lazy var privacyButton:UIButton = {
        let view = UIButton(type: .custom)
        view.titleLabel?.font = iKnowItems.privacyFont
        view.setTitleColor(iKnowItems.privacyColor, for: .normal)
        view.setTitle(iKnowItems.privacy, for: .normal)
        view.addActionHandlers { sender in
            if !self.iKnowItems.privacyURL.stringIsEmpty() {
                if self.iKnowItems.privacyURL.isURL() {
                    PTAppStoreFunction.jumpLink(url: URL(string: self.iKnowItems.privacyURL)!)
                }
            } else {
                if self.privacyTapHandler != nil {
                    self.privacyTapHandler!()
                }
            }
        }
        return view
    }()
        
    fileprivate lazy var collectionView:PTCollectionView = {
        
        let viewWidth = self.view.frame.size.width - contentViewSpace

        var contentViewWidth = viewWidth
        
        let config = PTCollectionViewConfig()
        config.viewType = .Custom
        config.showsVerticalScrollIndicator = false
        config.showsHorizontalScrollIndicator = false

        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTWhatsNewsCell.ID:PTWhatsNewsCell.self])
        view.customerLayout = { sectionIndex,sectionModel in
            var bannerGroupSize : NSCollectionLayoutSize
            var customers = [NSCollectionLayoutGroupCustomItem]()
            var groupH:CGFloat = 0
            sectionModel.rows?.enumerated().forEach { index,model in
                let cellModel =  model.dataModel as! PTWhatsNewsItem
                
                if cellModel.newsImage != nil {
                    contentViewWidth = contentViewWidth - (PTWhatsNewsCell.CellBaseHeight - 15) - 10
                }
                let titleHeight = UIView.sizeFor(string: cellModel.title, font: cellModel.titleFont,lineSpacing: cellModel.contentSpace as NSNumber,width: contentViewWidth).height + 5
                let subTitleHeight = UIView.sizeFor(string: cellModel.subTitle, font: cellModel.subTitleFont,lineSpacing: cellModel.contentSpace as NSNumber,width: viewWidth).height + 5

                var cellHeight = (!cellModel.title.stringIsEmpty() ? titleHeight : 0) + (!cellModel.subTitle.stringIsEmpty() ? subTitleHeight : 0) + (!cellModel.title.stringIsEmpty() || !cellModel.subTitle.stringIsEmpty() ? 15 : 0) + (!cellModel.title.stringIsEmpty() && !cellModel.subTitle.stringIsEmpty() ? cellModel.contentSpace : 0)
                if cellHeight <= PTWhatsNewsCell.CellBaseHeight {
                    cellHeight = PTWhatsNewsCell.CellBaseHeight
                }
                
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: 0, y: groupH, width: viewWidth, height: cellHeight), zIndex: 1000+index)
                customers.append(customItem)
                groupH += cellHeight
            }
            bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(viewWidth), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
            return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                customers
            })
        }
        view.cellInCollection = { collection,sectionModel,indexPath in
            if let itemRow = sectionModel.rows?[indexPath.row] {
                let cellModel = (itemRow.dataModel as! PTWhatsNewsItem)
                let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTWhatsNewsCell
                cell.cellModel = cellModel
                return cell
            }
            return nil
        }
        return view
    }()
    
    fileprivate var newsItems:[PTWhatsNewsItem]!
    fileprivate var iKnowItems:PTWhatsNewsIKnowItem!

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        PTWhatsNews.markCurrentVersionAsPresented()
    }
    
    public init(titleItem: PTWhatsNewsTitleItem = PTWhatsNewsTitleItem(),
                iKnowItem:PTWhatsNewsIKnowItem = PTWhatsNewsIKnowItem(),
                newsItem:[PTWhatsNewsItem]) {
        super.init(nibName: nil, bundle: nil)
        iKnowItems = iKnowItem
        newsItems = newsItem
        if titleItem.atts != nil {
            titleLabel.attributedText = titleItem.atts!.value
        } else {
            titleLabel.textColor = titleItem.titleColor
            titleLabel.font = titleItem.titleFont
            titleLabel.text = titleItem.title
            titleLabel.textAlignment = titleItem.textAlignment
        }
        
        iKnowButton.normalTitle = iKnowItem.title
        iKnowButton.hightlightTitle = iKnowButton.normalTitle
        iKnowButton.normalTitleColor = iKnowItem.titleColor
        iKnowButton.hightlightTitleColor = iKnowButton.normalTitleColor
        iKnowButton.normalTitleFont = iKnowItem.titleFont
        iKnowButton.hightlightTitleFont = iKnowButton.normalTitleFont
        iKnowButton.configBackgroundColor = iKnowItem.backgroundColor
        iKnowButton.configBackgroundHightlightColor = iKnowButton.configBackgroundColor.lighter(amount: 0.5)

        if iKnowItem.image != nil {
            iKnowButton.imageSize = CGSize(width: 44, height: 44)
            iKnowButton.layoutStyle = iKnowItem.itemLayout == .leftImageRightTitle ? .leftImageRightTitle : .leftTitleRightImage
            iKnowButton.midSpacing = iKnowItem.itemSpace
            iKnowButton.loadImage(contentData: iKnowItem.image!)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        if !iKnowItems.privacy.stringIsEmpty() {
            view.addSubviews([titleLabel,iKnowButton,privacyButton,collectionView])
        } else {
            view.addSubviews([titleLabel,iKnowButton,collectionView])
        }
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight)
        }
        
        iKnowButton.snp.makeConstraints { make in
            make.left.right.equalTo(titleLabel)
            make.height.equalTo(54)
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarHeight_Total)
        }
        
        if !iKnowItems.privacy.stringIsEmpty() {
            privacyButton.snp.makeConstraints { make in
                make.centerX.equalTo(self.iKnowButton)
                make.bottom.equalTo(self.iKnowButton.snp.top).offset(-7.5)
                make.left.right.lessThanOrEqualTo(self.iKnowButton)
            }
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(10)
            if !self.iKnowItems.privacy.stringIsEmpty() {
                make.bottom.equalTo(self.privacyButton.snp.top).offset(-20)
            } else {
                make.bottom.equalTo(self.iKnowButton.snp.top).offset(-20)
            }
            make.left.right.equalToSuperview().inset(contentViewSpace / 2)
        }
        
        showNewsData()
    }
    
    func showNewsData() {
        var rows = [PTRows]()
        newsItems.enumerated().forEach { index,value in
            let row = PTRows(ID: PTWhatsNewsCell.ID,dataModel: value)
            rows.append(row)
        }
        
        collectionView.showCollectionDetail(collectionData: [PTSection(rows: rows)])
    }
    
    public func whatsNewsShow(vc:UIViewController) {
        modalPresentationStyle = .formSheet
        vc.present(self, animated: true)
    }
}
