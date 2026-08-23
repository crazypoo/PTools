//
//  PTPopoverMenuContent.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

@objcMembers
public class PTPopoverItem:NSObject {
    public var name:String = ""
    public var icon:Any?
}

@MainActor
@objcMembers
public class PTPopoverConfig:NSObject {
    public var textFont:UIFont = .appfont(size: 16)
    public var textColor:UIColor = PTAppBaseConfig.share.viewDefaultTextColor
    public var backgroundColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: .white, darkColor: .black)
    public var rowHeight:CGFloat = 44
}

public typealias PTPopoverHandler = (String,Int) -> Void

@MainActor
class PTPopoverMenuContent: PTBaseViewController {

    var didSelectedHandler: PTPopoverHandler?

    var arrowDirections: UIPopoverArrowDirection = .any {
        didSet {
            updateArrowLayout()
        }
    }

    private var basePreferredContentSize: CGSize?
    
    private var viewModel:[PTPopoverItem] = [PTPopoverItem]()
    private var viewConfig: PTPopoverConfig = PTPopoverConfig()

    lazy var collectionView:PTCollectionView = {
        let cConfig = PTCollectionViewConfig()
        cConfig.viewType = .Normal
        cConfig.itemHeight = self.viewConfig.rowHeight
        
        let view = PTCollectionView(viewConfig: cConfig)
        view.registerClassCells(classs: [PTFusionCell.ID:PTFusionCell.self])
        view.backgroundColor = .clear
        view.cellInCollection = { collectionView,sectionModel,indexPath in
            if let itemRow = sectionModel.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTFusionCellModel,let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTFusionCell {
                cell.cellModel = cellModel
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { _,sectionModel,indexPath in
            if let itemRow = sectionModel.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTFusionCellModel {
                self.dismiss(animated: true) { [weak self = self] in
                    self?.didSelectedHandler?(cellModel.name,indexPath.row)
                }
            }
        }
        return view
    }()
    
    init(config:PTPopoverConfig,viewModel: [PTPopoverItem]) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
        viewConfig = config
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        view.backgroundColor = .clear
        view.addSubviews([collectionView])
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let rows = viewModel.map { value in
            let cellModel = PTFusionCellModel()
            cellModel.name = value.name
            cellModel.leftImage = value.icon
            cellModel.nameColor = self.viewConfig.textColor
            cellModel.cellFont = self.viewConfig.textFont

            let row = PTRows(ID: PTFusionCell.ID,dataModel: cellModel)
            return row
        }
        
        let sections = [PTSection(rows: rows)]
        collectionView.showCollectionDetail(collectionData: sections)
        updateArrowLayout()
    }

    private func updateArrowLayout() {
        let size = basePreferredContentSize ?? preferredContentSize
        if basePreferredContentSize == nil {
            basePreferredContentSize = size
        }

        guard isViewLoaded else { return }

        switch arrowDirections {
        case .up, .down:
            preferredContentSize = CGSize(width: size.width, height: size.height + 16)
        case .left, .right:
            preferredContentSize = CGSize(width: size.width + 16, height: size.height)
        default:
            preferredContentSize = size
        }

        collectionView.snp.remakeConstraints { make in
            switch arrowDirections {
            case .up:
                make.left.right.bottom.equalToSuperview()
                make.top.equalToSuperview().inset(16)
            case .right:
                make.right.equalToSuperview().inset(16)
                make.top.bottom.left.equalToSuperview()
            case .left:
                make.left.equalToSuperview().inset(16)
                make.top.bottom.right.equalToSuperview()
            case .down:
                make.bottom.equalToSuperview().inset(16)
                make.top.left.right.equalToSuperview()
            default:
                make.edges.equalToSuperview()
            }
        }
    }
}
