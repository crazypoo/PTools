//
//  PTVideoEditorConfig.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 1/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SafeSFSymbols

@objcMembers
public class PTVideoEditorConfig: NSObject {
    public static let share = PTVideoEditorConfig()
        
    public var themeColor:UIColor = UIColor.purple
    public var dismissImage:UIImage = "❌".emojiToImage(emojiFont: .appfont(size: 20))
    public var cutImage:UIImage = "✂️".emojiToImage(emojiFont: .appfont(size: 20))
    public var doneImage:UIImage = "✅".emojiToImage(emojiFont: .appfont(size: 20))
    public var playImage:UIImage = UIImage(.play.circleFill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    public var playImageSelected:UIImage = UIImage(.pause.circleFill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    public var muteImage:UIImage = UIImage(.speaker).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    public lazy var muteImageSelected:UIImage = UIImage(.speaker.zzz).withTintColor(self.themeColor)
    
    public var speedImage:UIImage = UIImage(.bolt.horizontalCircle).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    
    public var trimImage:UIImage = UIImage(.timeline.selection).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    public var cropImage:UIImage = UIImage(.crop).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    public var rotateImage:UIImage = UIImage(.rotate.right).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    public var presetsImage:UIImage = UIImage(.tv).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    public var filterImage:UIImage = UIImage(.camera.filters).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    public var rewriteImage:UIImage = UIImage(.repeat).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    public var trimLeftImage:UIImage = UIImage(.arrow.left)
    public var trimRightImage:UIImage = UIImage(.arrow.right)

    public var trimTitle:String = "PT Video editor function trim".localized()
    public var cropTitle:String = "PT Video editor function crop".localized()
    public var rotateTitle:String = "PT Video editor function rotate".localized()
    public var presetsTitle:String = "PT Video editor function export preset".localized()
    public var filterTitle:String = "PT Video editor function filter".localized()
    public var rewriteTitle:String = "PT Video editor function rewrite".localized()
    public var muteTitle:String = "PT Video editor function mute".localized()
    public var speedTitle:String = "PT Video editor function speed".localized()

    public var alertTitleOpps = "PT Alert Opps".localized()
    public var alertTitleDoing = "PT Alert Doning".localized()
    public var alertTitleConvetering = "PT Video editor convetering".localized()
    public var alertTitleOutputing = "PT Video editor ouputing".localized()
    public var alertTitleSaveDone = "PT Video editor function save done".localized()
    public var alertTitleSaveError = "PT Photo picker save video error".localized()
    public var alertTitleOutputType = "PT Video editor output type".localized()
    public var alertTitleOutputTypeOption = "PT Video editor function export preset select current".localized()
    public var alertTitleExportType = "PT Video editor function export preset select".localized()

    private var pri_filters: [PTHarBethFilter] = [.none,.cigaussian,.hueBlend,.alphaBlend,.luminosityBlend,.zoomBlur,.vignette,.pixellated,.crosshatch,.polkadot,.posterize,.monochrome,.voronoioverlay,.monochromedilation,.motionblur,.meanblur,.gaussianblur,.bilateralblur,.mpsgaussian,.colormatrix4x4,.convolution3x3,.sharpen3x3,.sepia,.granularity,.comicstrip,.oilpainting,.sketch]
    /// Filters for image editor.
    public var filters: [PTHarBethFilter] {
        get {
            if pri_filters.isEmpty {
                return [.none,.cigaussian,.hueBlend,.alphaBlend,.luminosityBlend,.zoomBlur,.vignette,.pixellated,.crosshatch,.polkadot,.posterize,.monochrome,.voronoioverlay,.monochromedilation,.motionblur,.meanblur,.gaussianblur,.bilateralblur,.mpsgaussian,.colormatrix4x4,.convolution3x3,.sharpen3x3,.sepia,.granularity,.comicstrip,.oilpainting,.sketch]
            } else {
                return pri_filters
            }
        }
        set {
            pri_filters = newValue
        }
    }
}
