//
//  PTMemory.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 6/6/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

open class PTMemory: NSObject {
    static let share = PTMemory()
    
    public var closed:Bool = true

    private var timer:Timer?
    private var avatar : PFloatingButton?
    private lazy var fpsLabel : UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.backgroundColor = .black
        label.textAlignment = .center
        return label
    }()

    open func startMonitoring() {
        if avatar == nil {
            avatar = PFloatingButton.init(view: AppWindows as Any, frame: CGRect(x: CGFloat.kSCREEN_WIDTH - 150, y: CGFloat.statusBarHeight(), width: 150, height: 30))
            avatar?.adjustsImageWhenHighlighted = false
            avatar?.tag = 9999
            avatar?.autoDocking = false
            
            avatar?.addSubview(fpsLabel)
            fpsLabel.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                let memoryString = self.reportMemory()
                self.fpsLabel.text = memoryString
                let labelW = self.fpsLabel.sizeFor(size: CGSize(width: CGFloat(MAXFLOAT), height: 30)).width + 20
                
                self.avatar!.frame = CGRect(x: self.avatar!.frame.origin.x, y: self.avatar!.frame.origin.y, width: labelW, height: self.avatar!.frame.size.height)
            }
            closed = false
        }
    }
    
    open func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        avatar?.removeFromSuperview()
        avatar = nil
        closed = true
    }
    
    func reportMemory() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedBytes = info.resident_size
            let usedMB = usedBytes / 1024 / 1024
            return "\(usedMB) MB/\(UIDevice.pt.memoryTotal)GB"
        } else {
            let errorString = String(cString: mach_error_string(kerr), encoding: .ascii) ?? "unknown error"
            return "Error with task_info(): \(errorString)"
        }
    }
}
