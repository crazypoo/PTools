//
//  PTImageEditorConfig.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

/// Adjust slider type
@objc public enum PTAdjustSliderType: Int {
    case vertical
    case horizontal
}

public class PTImageEditorConfig: NSObject {
    static let share = PTImageEditorConfig()
    
    /// The maximum number of frames for GIF images. To avoid crashes due to memory spikes caused by loading GIF images with too many frames, it is recommended that this value is not too large. Defaults to 50.
    public var maxFrameCountForGIF = 50

    //MARK: Text Sticker
    /// The default text sticker color. If this color not in textStickerTextColors, will pick the first color in textStickerTextColors as the default.
    public var textStickerDefaultTextColor = UIColor.white
    /// The default font of text sticker.
    public var textStickerDefaultFont: UIFont?

    //MARK: Adjust
    
    /// Adjust Slider Type
    public var adjustSliderType: PTAdjustSliderType = .vertical
    /// The normal color of adjust slider.
    /// 编辑图片，调整饱和度、对比度、亮度时，右侧slider背景色
    public var adjustSliderNormalColor: UIColor = .white
    
    /// The theme color of framework.
    /// 框架主题色
    public var themeColor: UIColor = .purple

    private var pri_adjustSliderTintColor: UIColor?
    /// The tint color of adjust slider.
    /// 编辑图片，调整饱和度、对比度、亮度时，右侧slider背景高亮色
    public var adjustSliderTintColor: UIColor {
        get {
            pri_adjustSliderTintColor ?? themeColor
        }
        set {
            pri_adjustSliderTintColor = newValue
        }
    }
    
    /// Give an impact feedback when the adjust slider value is zero. Defaults to true.
    public var impactFeedbackWhenAdjustSliderValueIsZero = true
    /// Impact feedback style. Defaults to .medium
    public var impactFeedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium
    @discardableResult
    func impactFeedbackStyle(_ style: UIImpactFeedbackGenerator.FeedbackStyle) -> PTImageEditorConfig {
        impactFeedbackStyle = style
        return self
    }

    //MARK: Cut
    private var pri_clipRatios: [PTImageClipRatio] = [.custom,.circle,.wh1x1,.wh3x4,.wh4x3,.wh2x3,.wh3x2,.wh9x16,.wh16x9]
    /// Edit ratios for image editor.
    public var clipRatios: [PTImageClipRatio] {
        get {
            if pri_clipRatios.isEmpty {
                return [.custom]
            } else {
                return pri_clipRatios
            }
        }
        set {
            pri_clipRatios = newValue
        }
    }
    
    /// Whether to keep clipped area dimmed during adjustments. Defaults to false
    public var dimClippedAreaDuringAdjustments = false
    
    //MARK: Edit
    
    @objc public enum EditTool: Int, CaseIterable {
        case draw
        case clip
        case textSticker
        case mosaic
        case filter
        case adjust
    }
    
    private var pri_tools: [PTImageEditorConfig.EditTool] = PTImageEditorConfig.EditTool.allCases
    /// Edit image tools. (Default order is draw, clip, imageSticker, textSticker, mosaic, filtter)
    /// Because Objective-C Array can't contain Enum styles, so this property is invalid in Objective-C.
    /// - warning: If you want to use the image sticker feature, you must provide a view that implements ZLImageStickerContainerDelegate.
    public var tools: [PTImageEditorConfig.EditTool] {
        get {
            if pri_tools.isEmpty {
                return PTImageEditorConfig.EditTool.allCases
            } else {
                return pri_tools
            }
        }
        set {
            pri_tools = newValue
        }
    }
    
    //MARK: Filter
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

    /// Minimum zoom scale, allowing the user to make the edited photo smaller, so it does not overlap top and bottom tools menu. Defaults to 1.0
    public var minimumZoomScale = 1.0
    
    private var pri_adjust_tools: [PTHarBethFilter.FiltersTool] = [.brightness,.contrast,.saturation]
    public var adjust_tools: [PTHarBethFilter.FiltersTool] {
        get {
            if pri_adjust_tools.isEmpty {
                return [.brightness,.contrast,.saturation]
            } else {
                return pri_adjust_tools
            }
        }
        set {
            pri_adjust_tools = newValue
        }
    }
}
