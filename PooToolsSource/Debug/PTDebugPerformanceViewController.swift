//
//  PTDebugPerformanceViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import SafeSFSymbols

enum PerformanceType: String,CaseIterable {
    case CPU = "CPU"
    case Memory = "Memory"
    case FPS = "FPS"
    case Leak = "Leak"
}

class PTDebugPerformanceViewController: PTBaseViewController {
    let toolkit = PTDebugPerformanceToolKit.shared
    var segmentType: PerformanceType = .CPU

    var floatingViewCellModel:PTFusionCellModel {
        get {
            let model = PTFusionCellModel()
            model.accessoryType = .Switch
            model.name = "FloatingView"
            return model
        }
    }
    
    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Custom
        config.refreshWithoutAnimation = true
        
        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTFusionCell.ID:PTFusionCell.self,PTPerformanceSegmentCell.ID:PTPerformanceSegmentCell.self,PTPerformanceChartCell.ID:PTPerformanceChartCell.self])
        view.registerSupplementaryView(classs: [NSStringFromClass(PTBaseCollectionReusableView.self):PTBaseCollectionReusableView.self], kind: UICollectionView.elementKindSectionHeader)
        view.customerLayout = { sectionIndex,sectionModel in
            if sectionModel.headerID == "Floating" || sectionModel.headerID == "Segment" || sectionModel.headerID == "PerformanceValue" {
                return UICollectionView.girdCollectionLayout(data: sectionModel.rows, groupWidth: CGFloat.kSCREEN_WIDTH, itemHeight: 54,cellRowCount: 1,originalX: 0)
            } else if sectionModel.headerID == "Chart" {
                return UICollectionView.girdCollectionLayout(data: sectionModel.rows, groupWidth: CGFloat.kSCREEN_WIDTH, itemHeight: 250,cellRowCount: 1,originalX: 0)
            } else {
                var bannerGroupSize : NSCollectionLayoutSize
                var customers = [NSCollectionLayoutGroupCustomItem]()
                var groupH:CGFloat = 0
                let screenW:CGFloat = CGFloat.kSCREEN_WIDTH
                var cellHeight:CGFloat = 0
                if Gobal_device_info.isPad {
                    cellHeight = 64
                } else {
                    cellHeight = CGFloat.ScaleW(w: 44)
                }
                sectionModel.rows?.enumerated().forEach { (index,model) in
                    let cellHeight:CGFloat = cellHeight
                    let customItem = NSCollectionLayoutGroupCustomItem(frame: CGRect(x: PTAppBaseConfig.share.defaultViewSpace, y: groupH, width: screenW - PTAppBaseConfig.share.defaultViewSpace * 2, height: cellHeight), zIndex: 1000+index)
                    customers.append(customItem)
                    groupH += cellHeight
                }
                bannerGroupSize = NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.absolute(screenW - PTAppBaseConfig.share.defaultViewSpace * 2), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
                return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                    customers
                })
            }
        }
        view.cellInCollection = { collection,itemSection,indexPath in
            if let itemRow = itemSection.rows?[indexPath.row] {
                if itemRow.ID == PTFusionCell.ID,let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTFusionCell,let cellModel = itemRow.dataModel as? PTFusionCellModel {
                    cell.cellModel = cellModel
                    if itemSection.headerID == "Floating" {
                        cell.switchValue = PTDebugPerformanceToolKit.shared.floatingShow
                        cell.switchValueChangeBlock = { title,sender in
                            PTDebugPerformanceToolKit.shared.floatingShow = !PTDebugPerformanceToolKit.shared.floatingShow
                        }
                    }
                    return cell
                } else if itemRow.ID == PTPerformanceSegmentCell.ID,let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTPerformanceSegmentCell {
                    cell.segmentedControl.selectedSegmentIndex = PerformanceType.allCases.firstIndex(of: self.segmentType) ?? 0
                    cell.segmentTapCallBack = { index in
                        self.segmentType = PerformanceType.allCases[index]
                        self.toolkit.performanceClose()
                        self.newCollectionView.clearAllData { cView in
                            self.listDataSet()
                            self.toolkit.performanceRestart()
                        }
                    }
                    return cell
                } else if itemRow.ID == PTPerformanceChartCell.ID,let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTPerformanceChartCell {
                    return cell
                }
            }
            return nil
        }
        view.collectionDidSelect = { collection,model,indexPath in
            if let itemRow = model.rows?[indexPath.row] {
                if itemRow.ID == PTFusionCell.ID,let cellModel = itemRow.dataModel as? PTFusionCellModel {
                    if cellModel.name == "Set Memory warning" {
                        UIDevice.pt.impactFeedbackGenerator(style: .heavy)
                        PTDebugPerformanceToolKit.generate()
                    } else if cellModel.name == "⚠️show leaks" {
                        let vc = PTLeakListViewController()
                        self.navigationController?.pushViewController(vc)
                    } else if cellModel.name == "Create Leak" {
                        let vc = PTCreateLeakViewController()
                        self.currentPresentToSheet(vc: vc,sizes: [.percent(0.9)])
                    }
                }
            }
        }
        return view
    }()
    
    lazy var fakeNav:PTNavBar = {
        let view = PTNavBar()
        return view
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let collectionInset:CGFloat = CGFloat.kTabbarSaveAreaHeight
        let collectionInset_Top:CGFloat = CGFloat.kNavBarHeight
        
        newCollectionView.contentCollectionView.contentInsetAdjustmentBehavior = .never
        newCollectionView.contentCollectionView.contentInset.top = collectionInset_Top
        newCollectionView.contentCollectionView.contentInset.bottom = collectionInset
        newCollectionView.contentCollectionView.verticalScrollIndicatorInsets.bottom = collectionInset

        view.addSubviews([newCollectionView,fakeNav])
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(self.sheetViewController?.options.pullBarHeight ?? 0)
        }

        fakeNav.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.newCollectionView)
            make.height.equalTo(CGFloat.kNavBarHeight)
        }

        let button = UIButton(type: .custom)
        button.setImage(UIImage(.arrow.uturnLeftCircle), for: .normal)
        if #available(iOS 26.0, *) {
            button.configuration = UIButton.Configuration.clearGlass()
        }
        fakeNav.setLeftButtons([button])
        button.addActionHandlers { sender in
            self.dismissAnimated()
        }
        
        listDataSet()
        
        toolkit.performanceDataUpdateCallBack = { toolKit in 
            switch self.segmentType {
            case .CPU:
                let usageModel = self.baseCellModel(name: "CPU Usage", value: String(format: "%.1lf%%", self.toolkit.currentCPU))
                if let cell = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 0, section: 2)) as? PTFusionCell {
                    cell.cellModel = usageModel
                }
                
                
                let usageMaxModel = self.baseCellModel(name: "Max CPU Usage", value: String(format: "%.1lf%%", self.toolkit.maxCPU))
                if let cellMax = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 1, section: 2)) as? PTFusionCell {
                    cellMax.cellModel = usageMaxModel
                }

                if let cellChart = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 0, section: 3)) as? PTPerformanceChartCell {
                    self.configureChartCell(chartCell: cellChart, value: self.toolkit.maxCPU, measurements: self.toolkit.cpuMeasurements, markedValueFormat: "%.1lf%%")
                }
            case .Memory:
                let usageModel = self.baseCellModel(name: "Memory Usage", value: String(format: "%.1lfMB", self.toolkit.currentMemory))
                if let cell = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 0, section: 2)) as? PTFusionCell {
                    cell.cellModel = usageModel
                }
                
                let usageMaxModel = self.baseCellModel(name: "Max Memory Usage", value: String(format: "%.1lfMB", self.toolkit.maxMemory))
                if let cellMax = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 1, section: 2)) as? PTFusionCell {
                    cellMax.cellModel = usageMaxModel
                }

                if let cellChart = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 0, section: 3)) as? PTPerformanceChartCell {
                    self.configureChartCell(chartCell: cellChart, value: self.toolkit.maxMemory, measurements: self.toolkit.memoryMeasurements, markedValueFormat: "%.1lfMB")
                }
            case .FPS:
                let usageModel = self.baseCellModel(name: "FPS", value: "\(self.toolkit.currentFPS)")
                if let cell = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 0, section: 2)) as? PTFusionCell {
                    cell.cellModel = usageModel
                }
                
                let usageMaxModel = self.baseCellModel(name: "Min FPS", value: "\(self.toolkit.minFPS)")
                if let cellMax = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 1, section: 2)) as? PTFusionCell {
                    cellMax.cellModel = usageMaxModel
                }

                if let cellChart = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 0, section: 3)) as? PTPerformanceChartCell {
                    self.configureChartCell(chartCell: cellChart, value: self.toolkit.maxMemory, measurements: self.toolkit.fpsMeasurements, markedValueFormat: "%.0lf")
                }
            case .Leak:
                let usageModel = self.baseCellModel(name: "All Leak", value: "\(PTPerformanceLeakDetector.leaks.count)")
                if let cell = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 0, section: 2)) as? PTFusionCell {
                    cell.cellModel = usageModel
                }
            }
        }
    }
    
    func listDataSet() {
        var sections = [PTSection]()
        
        let floatingView_row = PTRows(ID: PTFusionCell.ID,dataModel: floatingViewCellModel)
        let floatingView_section = PTSection(headerID:"Floating",rows: [floatingView_row])
        sections.append(floatingView_section)
        
        let segment_row = PTRows(ID: PTPerformanceSegmentCell.ID)
        let segment_section = PTSection(headerID:"Segment",rows: [segment_row])
        sections.append(segment_section)

        switch segmentType {
        case .CPU:
            let usageModel = self.baseCellModel(name: "CPU Usage", value: "\(toolkit.currentCPU)%")
            let cpuUsage_row = PTRows(ID: PTFusionCell.ID,dataModel: usageModel)
            
            let usageMaxModel = self.baseCellModel(name: "Max CPU Usage", value: "\(toolkit.maxCPU)%")
            let cpuUsageMax_row = PTRows(ID: PTFusionCell.ID,dataModel: usageMaxModel)

            let value_section = PTSection(headerID:"PerformanceValue",rows: [cpuUsage_row,cpuUsageMax_row])
            sections.append(value_section)
        case .Memory:
            let usageModel = self.baseCellModel(name: "Memory Usage", value: "\(toolkit.currentMemory)MB")
            let cpuUsage_row = PTRows(ID: PTFusionCell.ID,dataModel: usageModel)
            
            let usageMaxModel = self.baseCellModel(name: "Max Memory Usage", value: "\(toolkit.maxMemory)MB")
            let cpuUsageMax_row = PTRows(ID: PTFusionCell.ID,dataModel: usageMaxModel)

            let memoryWarningModel = self.baseCellModel(name: "Set Memory warning", value: "")
            let memoryWarning_row = PTRows(ID: PTFusionCell.ID,dataModel: memoryWarningModel)

            let value_section = PTSection(headerID:"PerformanceValue",rows: [cpuUsage_row,cpuUsageMax_row,memoryWarning_row])
            sections.append(value_section)
        case .FPS:
            let usageModel = self.baseCellModel(name: "FPS", value: "\(toolkit.currentFPS)")
            let cpuUsage_row = PTRows(ID: PTFusionCell.ID,dataModel: usageModel)
            
            let usageMaxModel = self.baseCellModel(name: "Min FPS", value: "\(toolkit.minFPS)")
            let cpuUsageMax_row = PTRows(ID: PTFusionCell.ID,dataModel: usageMaxModel)

            let value_section = PTSection(headerID:"PerformanceValue",rows: [cpuUsage_row,cpuUsageMax_row])
            sections.append(value_section)
        case .Leak:
            let usageModel = self.baseCellModel(name: "All Leak", value: "\(PTPerformanceLeakDetector.leaks.count)")
            let cpuUsage_row = PTRows(ID: PTFusionCell.ID,dataModel: usageModel)
            
            let createLeakModel = PTFusionCellModel()
            createLeakModel.name = "Create Leak"
            createLeakModel.disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 14))
            
            let createLeak_row = PTRows(ID: PTFusionCell.ID,dataModel: createLeakModel)

            let showLeakModel = PTFusionCellModel()
            showLeakModel.name = "⚠️show leaks"
            showLeakModel.accessoryType = .DisclosureIndicator
            showLeakModel.disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 14))

            let showLeak_row = PTRows(ID: PTFusionCell.ID,dataModel: showLeakModel)

            let value_section = PTSection(headerID:"PerformanceValue",rows: [cpuUsage_row,createLeak_row,showLeak_row])
            sections.append(value_section)
        }
        
        switch segmentType {
        case .CPU,.FPS,.Memory:
            let chart_row = PTRows(ID: PTPerformanceChartCell.ID)
            let chart_section = PTSection(headerID:"Chart",rows: [chart_row])
            sections.append(chart_section)
        case .Leak:
            break
        }

        newCollectionView.showCollectionDetail(collectionData: sections)
    }
    
    func baseCellModel(name:String,value:String) -> PTFusionCellModel {
        let model = PTFusionCellModel()
        model.name = name
        model.content = value
        return model
    }
    
    private func configureChartCell(chartCell: PTPerformanceChartCell, value: CGFloat, measurements: [CGFloat], markedValueFormat: String) {
        chartCell.chartView.maxValue = value
        chartCell.chartView.markedValue = value
        chartCell.chartView.markedValueFormat = markedValueFormat
        chartCell.chartView.measurements = measurements
        chartCell.chartView.measurementsLimit = toolkit.measurementsLimit
        chartCell.chartView.measurementInterval = toolkit.timeBetweenMeasurements
        chartCell.chartView.markedTimesInterval = toolkit.controllerMarked
    }
}
