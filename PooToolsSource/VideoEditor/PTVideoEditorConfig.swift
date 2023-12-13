//
//  PTVideoEditorConfig.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

let PTVideoEditorPodBundleName = "PTVideoEditorResources"

public class PTVideoEditorConfig: NSObject {
    public static let share = PTVideoEditorConfig()
    
    public var themeColor:UIColor = UIColor.purple
    
    private var pri_filters: [PTHarBethFilter] = [.cigaussian,.hueBlend,.alphaBlend,.luminosityBlend,.zoomBlur,.vignette,.pixellated,.crosshatch,.polkadot,.posterize,.monochrome,.voronoioverlay,.monochromedilation,.motionblur,.meanblur,.gaussianblur,.bilateralblur,.mpsgaussian,.colormatrix4x4,.convolution3x3,.sharpen3x3,.sepia,.granularity,.comicstrip,.oilpainting,.sketch]
    /// Filters for image editor.
    public var filters: [PTHarBethFilter] {
        get {
            if pri_filters.isEmpty {
                return [.cigaussian]
            } else {
                return pri_filters
            }
        }
        set {
            pri_filters = newValue
        }
    }
}
