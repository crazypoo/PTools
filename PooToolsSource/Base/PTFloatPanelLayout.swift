//
//  PTFloatPanelLayout.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import FloatingPanel

public class PTFloatPanelLayout: FloatingPanelLayout {
    open var initialState: FloatingPanelState {
        .half
    }

    open var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring]  {
        [
            .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
        ]
    }

    open var position: FloatingPanelPosition {
        .bottom
    }

    open func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        return 0.45
    }
}

public class PNProductSpecPanelLayout: FloatingPanelLayout {
    
    public var viewHeight:CGFloat = 18
    
    open var initialState: FloatingPanelState {
        .full
    }

    open var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring]  {
        [
            .full: FloatingPanelLayoutAnchor(absoluteInset: kSCREEN_HEIGHT - viewHeight, edge: .top, referenceGuide: .superview)
        ]
    }

    open var position: FloatingPanelPosition {
        .bottom
    }

    open func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        return 0.45
    }
}
