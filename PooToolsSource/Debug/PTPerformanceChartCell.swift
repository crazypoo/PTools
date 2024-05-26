//
//  PTPerformanceChartCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

class PTPerformanceChartCell: PTBaseNormalCell {
    static let ID = "PTPerformanceChartCell"
    
    let chartView: PTPerformanceChartView = {
        let chartView = PTPerformanceChartView()
        chartView.graphHeight = 200.0
        chartView.topPadding = 20
        return chartView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(chartView)
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(12)
            make.bottom.equalToSuperview()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
