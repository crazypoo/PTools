//
//  PTPerformanceSegmentCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

class PTPerformanceSegmentCell: PTBaseNormalCell {
    static let ID = "PTPerformanceSegmentCell"
    
    var segmentTapCallBack:((Int)->Void)!
    
    lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl()
        segmentedControl.isUserInteractionEnabled = true
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(
            self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged
        )
        segmentedControl.overrideUserInterfaceStyle = .dark
        return segmentedControl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(8)
        }
        
        
        segmentedControl.removeAllSegments()
        PerformanceType.allCases.enumerated().forEach { index,value in
            self.segmentedControl.insertSegment(withTitle: value.rawValue, at: index, animated: false)
        }
    }
        
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        segmentTapCallBack(sender.selectedSegmentIndex)
    }
}
