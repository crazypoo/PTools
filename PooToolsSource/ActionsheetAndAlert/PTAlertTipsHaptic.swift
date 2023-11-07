//
//  PTAlertTipsHaptic.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public enum PTAlertTipsHaptic {
    case success
    case warning
    case error
    case none
    
    func impact() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        switch self {
        case .success:
            generator.notificationOccurred(UINotificationFeedbackGenerator.FeedbackType.success)
        case .warning:
            generator.notificationOccurred(UINotificationFeedbackGenerator.FeedbackType.warning)
        case .error:
            generator.notificationOccurred(UINotificationFeedbackGenerator.FeedbackType.error)
        case .none:
            break
        }
        #endif
    }
}
