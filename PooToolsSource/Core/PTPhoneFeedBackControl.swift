//
//  PTPhoneFeedBackControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/4/7.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation
import UIKit
import AudioToolbox

public class PTPhoneFeedbackControl:NSObject {
    /// 系统震动
    public class func systemVibrateShake() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    // MARK: - UINotificationFeedbackGenerator
    public class func addNotifi(_ type: UINotificationFeedbackGenerator.FeedbackType = .success) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    // MARK: - UIImpactFeedbackGenerator
    public class func addImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
       let generator = UIImpactFeedbackGenerator(style: style)
       generator.prepare()
       generator.impactOccurred()
    }
   
    @available(iOS 13.0, *)
    public class func addNewImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .rigid) {
       let generator = UIImpactFeedbackGenerator(style: style)
       generator.prepare()
       generator.impactOccurred()
    }
   
    // MARK: - UISelectionFeedbackGenerator
    public class func addSelect() {
       let generator = UISelectionFeedbackGenerator()
       generator.selectionChanged()
   }
}
