//
//  PTDebugPerformanceViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif

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
                sectionModel.rows.enumerated().forEach { (index,model) in
                    let cellHeight:CGFloat = cellHeight
                    let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: PTAppBaseConfig.share.defaultViewSpace, y: groupH, width: screenW - PTAppBaseConfig.share.defaultViewSpace * 2, height: cellHeight), zIndex: 1000+index)
                    customers.append(customItem)
                    groupH += cellHeight
                }
                bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(screenW - PTAppBaseConfig.share.defaultViewSpace * 2), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
                return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                    customers
                })

            }
        }
        view.cellInCollection = { collection,itemSection,indexPath in
            let itemRow = itemSection.rows[indexPath.row]
            if itemRow.ID == PTFusionCell.ID {
                let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
                cell.cellModel = (itemRow.dataModel as! PTFusionCellModel)
                if itemSection.headerID == "Floating" {
                    cell.switchValue = PTDebugPerformanceToolKit.shared.floatingShow
                    cell.switchValueChangeBlock = { title,sender in
                        PTDebugPerformanceToolKit.shared.floatingShow = !PTDebugPerformanceToolKit.shared.floatingShow
                    }
                }
                return cell
            } else if itemRow.ID == PTPerformanceSegmentCell.ID {
                let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTPerformanceSegmentCell
                cell.segmentedControl.selectedSegmentIndex = PerformanceType.allCases.firstIndex(of: self.segmentType)!
                cell.segmentTapCallBack = { index in
                    self.segmentType = PerformanceType.allCases[index]
                    self.toolkit.performanceClose()
                    self.newCollectionView.clearAllData { cView in
                        self.listDataSet()
                        self.toolkit.performanceRestart()
                    }
                }
                return cell
            } else if itemRow.ID == PTPerformanceChartCell.ID {
                let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTPerformanceChartCell
                return cell
            } else {
                let cell = collection.dequeueReusableCell(withReuseIdentifier: "CELL", for: indexPath)
                return cell
            }
        }
        view.collectionDidSelect = { collection,model,indexPath in
            let itemRow = model.rows[indexPath.row]
            if itemRow.ID == PTFusionCell.ID {
                let cellModel = (itemRow.dataModel as! PTFusionCellModel)
                if cellModel.name == "Set Memory warning" {
                    UIDevice.pt.impactFeedbackGenerator(style: .heavy)
                    PTDebugPerformanceToolKit.generate()
                } else if cellModel.name == "⚠️show leaks" {
                    PTNSLogConsole("1321231123123123")
                } else if cellModel.name == "Create Leak" {
                    let vc = PTCreateLeakViewController()
                    let sheet = PTSheetViewController(controller: vc,sizes: [.percent(0.9)])
                    let currentVC = PTUtils.getCurrentVC()
                    if currentVC is PTSideMenuControl {
                        let currentVC = (currentVC as! PTSideMenuControl).contentViewController
                        if let presentedVC = currentVC?.presentedViewController {
                            presentedVC.present(sheet, animated: true)
                        } else {
                            currentVC!.present(sheet, animated: true)
                        }
                    } else {
                        if let presentedVC = PTUtils.getCurrentVC().presentedViewController {
                            presentedVC.present(sheet, animated: true)
                        } else {
                            PTUtils.getCurrentVC().present(sheet, animated: true)
                        }
                    }
                }
            }
        }
        return view
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_hideBaseNavBar = true
#else
        navigationController?.navigationBar.isHidden = true
#endif
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(newCollectionView)
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(20)
        }
        listDataSet()
        
        toolkit.performanceDataUpdateCallBack = { toolKit in 
            switch self.segmentType {
            case .CPU:
                let usageModel = self.baseCellModel(name: "CPU Usage", value: "\(self.toolkit.currentCPU)%")
                let cell = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 0, section: 2)) as! PTFusionCell
                cell.cellModel = usageModel
                
                let usageMaxModel = self.baseCellModel(name: "Max CPU Usage", value: "\(self.toolkit.maxCPU)%")
                let cellMax = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 1, section: 2)) as! PTFusionCell
                cellMax.cellModel = usageMaxModel

                let cellChart = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 0, section: 3)) as! PTPerformanceChartCell
                self.configureChartCell(chartCell: cellChart, value: self.toolkit.maxCPU, measurements: self.toolkit.cpuMeasurements, markedValueFormat: "%.1lf%%")
            case .Memory:
                let usageModel = self.baseCellModel(name: "Memory Usage", value: "\(self.toolkit.currentMemory)MB")
                let cell = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 0, section: 2)) as! PTFusionCell
                cell.cellModel = usageModel
                
                let usageMaxModel = self.baseCellModel(name: "Max Memory Usage", value: "\(self.toolkit.maxMemory)MB")
                let cellMax = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 1, section: 2)) as! PTFusionCell
                cellMax.cellModel = usageMaxModel

                let cellChart = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 0, section: 3)) as! PTPerformanceChartCell
                self.configureChartCell(chartCell: cellChart, value: self.toolkit.maxMemory, measurements: self.toolkit.memoryMeasurements, markedValueFormat: "%.1lfMB")
            case .FPS:
                let usageModel = self.baseCellModel(name: "FPS", value: "\(self.toolkit.currentFPS)")
                let cell = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 0, section: 2)) as! PTFusionCell
                cell.cellModel = usageModel
                
                let usageMaxModel = self.baseCellModel(name: "Min FPS", value: "\(self.toolkit.minFPS)")
                let cellMax = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 1, section: 2)) as! PTFusionCell
                cellMax.cellModel = usageMaxModel

                let cellChart = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 0, section: 3)) as! PTPerformanceChartCell
                self.configureChartCell(chartCell: cellChart, value: self.toolkit.maxMemory, measurements: self.toolkit.fpsMeasurements, markedValueFormat: "%.0lf")
            case .Leak:
                let usageModel = self.baseCellModel(name: "All Leak", value: "\(PTPerformanceLeakDetector.leaks.count)")
                let cell = self.newCollectionView.contentCollectionView.cellForItem(at: IndexPath(row: 0, section: 2)) as! PTFusionCell
                cell.cellModel = usageModel
            }
        }
    }
    
    func listDataSet() {
        var sections = [PTSection]()
        
        let floatingView_row = PTRows(cls: PTFusionCell.self,ID: PTFusionCell.ID,dataModel: floatingViewCellModel)
        let floatingView_section = PTSection(headerID:"Floating",rows: [floatingView_row])
        sections.append(floatingView_section)
        
        let segment_row = PTRows(cls: PTPerformanceSegmentCell.self,ID: PTPerformanceSegmentCell.ID)
        let segment_section = PTSection(headerID:"Segment",rows: [segment_row])
        sections.append(segment_section)

        switch segmentType {
        case .CPU:
            let usageModel = self.baseCellModel(name: "CPU Usage", value: "\(toolkit.currentCPU)%")
            let cpuUsage_row = PTRows(cls: PTFusionCell.self,ID: PTFusionCell.ID,dataModel: usageModel)
            
            let usageMaxModel = self.baseCellModel(name: "Max CPU Usage", value: "\(toolkit.maxCPU)%")
            let cpuUsageMax_row = PTRows(cls: PTFusionCell.self,ID: PTFusionCell.ID,dataModel: usageMaxModel)

            let value_section = PTSection(headerID:"PerformanceValue",rows: [cpuUsage_row,cpuUsageMax_row])
            sections.append(value_section)
        case .Memory:
            let usageModel = self.baseCellModel(name: "Memory Usage", value: "\(toolkit.currentMemory)MB")
            let cpuUsage_row = PTRows(cls: PTFusionCell.self,ID: PTFusionCell.ID,dataModel: usageModel)
            
            let usageMaxModel = self.baseCellModel(name: "Max Memory Usage", value: "\(toolkit.maxMemory)MB")
            let cpuUsageMax_row = PTRows(cls: PTFusionCell.self,ID: PTFusionCell.ID,dataModel: usageMaxModel)

            let memoryWarningModel = self.baseCellModel(name: "Set Memory warning", value: "")
            let memoryWarning_row = PTRows(cls: PTFusionCell.self,ID: PTFusionCell.ID,dataModel: memoryWarningModel)

            let value_section = PTSection(headerID:"PerformanceValue",rows: [cpuUsage_row,cpuUsageMax_row,memoryWarning_row])
            sections.append(value_section)
        case .FPS:
            let usageModel = self.baseCellModel(name: "FPS", value: "\(toolkit.currentFPS)")
            let cpuUsage_row = PTRows(cls: PTFusionCell.self,ID: PTFusionCell.ID,dataModel: usageModel)
            
            let usageMaxModel = self.baseCellModel(name: "Min FPS", value: "\(toolkit.minFPS)")
            let cpuUsageMax_row = PTRows(cls: PTFusionCell.self,ID: PTFusionCell.ID,dataModel: usageMaxModel)

            let value_section = PTSection(headerID:"PerformanceValue",rows: [cpuUsage_row,cpuUsageMax_row])
            sections.append(value_section)
        case .Leak:
            let usageModel = self.baseCellModel(name: "All Leak", value: "\(PTPerformanceLeakDetector.leaks.count)")
            let cpuUsage_row = PTRows(cls: PTFusionCell.self,ID: PTFusionCell.ID,dataModel: usageModel)
            
            let createLeakModel = PTFusionCellModel()
            createLeakModel.name = "Create Leak"
            createLeakModel.disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 14))
            
            let createLeak_row = PTRows(cls: PTFusionCell.self,ID: PTFusionCell.ID,dataModel: createLeakModel)

            let showLeakModel = PTFusionCellModel()
            showLeakModel.name = "⚠️show leaks"
            showLeakModel.accessoryType = .DisclosureIndicator
            showLeakModel.disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 14))

            let showLeak_row = PTRows(cls: PTFusionCell.self,ID: PTFusionCell.ID,dataModel: showLeakModel)

            let value_section = PTSection(headerID:"PerformanceValue",rows: [cpuUsage_row,createLeak_row,showLeak_row])
            sections.append(value_section)
        }
        
        switch segmentType {
        case .CPU,.FPS,.Memory:
            let chart_row = PTRows(cls: PTPerformanceChartCell.self,ID: PTPerformanceChartCell.ID)
            let chart_section = PTSection(headerID:"Chart",rows: [chart_row])
            sections.append(chart_section)
        case .Leak:
            break
        }

        newCollectionView.showCollectionDetail(collectionData: sections)
    }
    
    func baseCellModel(name:String,value:String) ->PTFusionCellModel {
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
