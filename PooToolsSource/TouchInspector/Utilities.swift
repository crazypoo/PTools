//
//  File.swift
//  
//
//  Created by Janum Trivedi.
//

import Foundation
import UIKit

extension CGPoint {
    var shortDescription: String {
        String(describing: CGPoint( x: round(x * 100) / 100.0, y: round(y * 100) / 100.0))
    }
}

func animateBlock(_ block: @escaping PTActionTask, completion: PTActionTask? = nil) {
    let options = UIView.AnimationOptions(arrayLiteral: .curveEaseInOut, .allowUserInteraction, .beginFromCurrentState)
    UIView.animate(withDuration: 0.15, delay: 0, options: options) {
        PTGCDManager.gcdMain {
            block()
        }
    } completion: { _ in
        PTGCDManager.gcdMain {
            completion?()
        }
    }
}

