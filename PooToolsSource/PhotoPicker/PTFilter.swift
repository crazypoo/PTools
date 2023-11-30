//
//  PTFilter.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 29/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Harbeth

public typealias PTFilterApplierType = (_ image: UIImage) -> UIImage

public typealias maxminTuple = (current: Float, min: Float, max: Float)?
public typealias FilterCallback = (_ value: Float) -> C7FilterProtocol
public typealias FilterResult = (filter: C7FilterProtocol, maxminValue: maxminTuple, callback: FilterCallback?)

public class PTHarBethFilter:NSObject {
    
    public static let share = PTHarBethFilter()
    
    public var tools:[PTHarBethFilter.FiltersTool] = PTHarBethFilter.FiltersTool.allCases
    
    public func getFilterResults() -> [FilterResult] {
        var ssss = [FilterResult]()
        tools.enumerated().forEach { index,value in
            ssss.append(value.getFilterResult())
        }
        return ssss
    }
    
    @objc public enum FiltersTool: Int, CaseIterable {
        case brightness
        case contrast
        case saturation
        
        func getFilterResult() -> FilterResult {
            switch self {
            case .brightness:
                var filter = C7Luminance()
                filter.luminance = 1
                return (filter, (0, -1, 1), {
                    filter.luminance = $0
                    return filter
                })
            case .contrast:
                var filter = C7Contrast()
                filter.contrast = 1
                return (filter, (1, 0, 4), {
                    filter.contrast = $0
                    return filter
                })
            case .saturation:
                var filter = C7Saturation()
                filter.saturation = 1
                return (filter, (1, 0, 2), {
                    filter.saturation = $0
                    return filter
                })
            }
        }
        
        func filterValue(_ value: Float) -> Float {
            switch self {
            case .brightness:
                // 亮度范围-1---1，默认0，这里除以3，取 -0.33---0.33
                return value
            case .contrast:
                // 对比度范围0---4，默认1，这里计算下取0.5---2.5
                let v: Float
                if value < 0 {
                    v = 1 + value * (1 / 2)
                } else {
                    v = 1 + value * (3 / 2)
                }
                return v
            case .saturation:
                // 饱和度范围0---2，默认1
                return value + 1
            default:
                return 0
            }
        }
    }
}

@objc public enum PTFilterType: Int {
    case normal
    case chrome
    case fade
    case instant
    case process
    case transfer
    case tone
    case linear
    case sepia
    case mono
    case noir
    case tonal
    
    var coreImageFilterName: String {
        switch self {
        case .normal:
            return ""
        case .chrome:
            return "CIPhotoEffectChrome"
        case .fade:
            return "CIPhotoEffectFade"
        case .instant:
            return "CIPhotoEffectInstant"
        case .process:
            return "CIPhotoEffectProcess"
        case .transfer:
            return "CIPhotoEffectTransfer"
        case .tone:
            return "CILinearToSRGBToneCurve"
        case .linear:
            return "CISRGBToneCurveToLinear"
        case .sepia:
            return "CISepiaTone"
        case .mono:
            return "CIPhotoEffectMono"
        case .noir:
            return "CIPhotoEffectNoir"
        case .tonal:
            return "CIPhotoEffectTonal"
        }
    }
}

public class PTFilter: NSObject {
    public var name: String
    
    let applier: PTFilterApplierType?
    
    @objc public init(name: String, filterType: PTFilterType) {
        self.name = name
        
        if filterType != .normal {
            applier = { image -> UIImage in
                guard let ciImage = image.pt.toCIImage() else {
                    return image
                }
                
                let filter = CIFilter(name: filterType.coreImageFilterName)
                filter?.setValue(ciImage, forKey: kCIInputImageKey)
                guard let outputImage = filter?.outputImage?.pt.toUIImage() else {
                    return image
                }
                return outputImage
            }
        } else {
            applier = nil
        }
    }
    
    /// 可传入 applier 自定义滤镜
    @objc public init(name: String, applier: PTFilterApplierType?) {
        self.name = name
        self.applier = applier
    }
}

extension PTFilter {
    class func clarendonFilter(image: UIImage) -> UIImage {
        guard let ciImage = image.pt.toCIImage() else {
            return image
        }
        
        let backgroundImage = getColorImage(red: 127, green: 187, blue: 227, alpha: Int(255 * 0.2), rect: ciImage.extent)
        let outputCIImage = ciImage.applyingFilter("CIOverlayBlendMode", parameters: [
            "inputBackgroundImage": backgroundImage
        ])
        .applyingFilter("CIColorControls", parameters: [
            "inputSaturation": 1.35,
            "inputBrightness": 0.05,
            "inputContrast": 1.1
        ])
        guard let outputImage = outputCIImage.pt.toUIImage() else {
            return image
        }
        return outputImage
    }
    
    class func nashvilleFilter(image: UIImage) -> UIImage {
        guard let ciImage = image.pt.toCIImage() else {
            return image
        }
        
        let backgroundImage = getColorImage(red: 247, green: 176, blue: 153, alpha: Int(255 * 0.56), rect: ciImage.extent)
        let backgroundImage2 = getColorImage(red: 0, green: 70, blue: 150, alpha: Int(255 * 0.4), rect: ciImage.extent)
        let outputCIImage = ciImage
            .applyingFilter("CIDarkenBlendMode", parameters: [
                "inputBackgroundImage": backgroundImage
            ])
            .applyingFilter("CISepiaTone", parameters: [
                "inputIntensity": 0.2
            ])
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.2,
                "inputBrightness": 0.05,
                "inputContrast": 1.1
            ])
            .applyingFilter("CILightenBlendMode", parameters: [
                "inputBackgroundImage": backgroundImage2
            ])
        
        guard let outputImage = outputCIImage.pt.toUIImage() else {
            return image
        }
        return outputImage
    }
    
    class func apply1977Filter(image: UIImage) -> UIImage {
        guard let ciImage = image.pt.toCIImage() else {
            return image
        }
        
        let filterImage = getColorImage(red: 243, green: 106, blue: 188, alpha: Int(255 * 0.1), rect: ciImage.extent)
        let backgroundImage = ciImage
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.3,
                "inputBrightness": 0.1,
                "inputContrast": 1.05
            ])
            .applyingFilter("CIHueAdjust", parameters: [
                "inputAngle": 0.3
            ])
        
        let outputCIImage = filterImage
            .applyingFilter("CIScreenBlendMode", parameters: [
                "inputBackgroundImage": backgroundImage
            ])
            .applyingFilter("CIToneCurve", parameters: [
                "inputPoint0": CIVector(x: 0, y: 0),
                "inputPoint1": CIVector(x: 0.25, y: 0.20),
                "inputPoint2": CIVector(x: 0.5, y: 0.5),
                "inputPoint3": CIVector(x: 0.75, y: 0.80),
                "inputPoint4": CIVector(x: 1, y: 1)
            ])
        
        guard let outputImage = outputCIImage.pt.toUIImage() else {
            return image
        }
        return outputImage
    }
    
    class func toasterFilter(image: UIImage) -> UIImage {
        guard let ciImage = image.pt.toCIImage() else {
            return image
        }
        
        let width = ciImage.extent.width
        let height = ciImage.extent.height
        let centerWidth = width / 2.0
        let centerHeight = height / 2.0
        let radius0 = min(width / 4.0, height / 4.0)
        let radius1 = min(width / 1.5, height / 1.5)
        
        let color0 = getColor(red: 128, green: 78, blue: 15, alpha: 255)
        let color1 = getColor(red: 79, green: 0, blue: 79, alpha: 255)
        let circle = CIFilter(name: "CIRadialGradient", parameters: [
            "inputCenter": CIVector(x: centerWidth, y: centerHeight),
            "inputRadius0": radius0,
            "inputRadius1": radius1,
            "inputColor0": color0,
            "inputColor1": color1
        ])?.outputImage?.cropped(to: ciImage.extent)
        
        let outputCIImage = ciImage
            .applyingFilter("CIColorControls", parameters: [
                "inputSaturation": 1.0,
                "inputBrightness": 0.01,
                "inputContrast": 1.1
            ])
            .applyingFilter("CIScreenBlendMode", parameters: [
                "inputBackgroundImage": circle!
            ])
        
        guard let outputImage = outputCIImage.pt.toUIImage() else {
            return image
        }
        return outputImage
    }
    
    class func getColor(red: Int, green: Int, blue: Int, alpha: Int = 255) -> CIColor {
        return CIColor(
            red: CGFloat(Double(red) / 255.0),
            green: CGFloat(Double(green) / 255.0),
            blue: CGFloat(Double(blue) / 255.0),
            alpha: CGFloat(Double(alpha) / 255.0)
        )
    }
    
    class func getColorImage(red: Int, green: Int, blue: Int, alpha: Int = 255, rect: CGRect) -> CIImage {
        let color = getColor(red: red, green: green, blue: blue, alpha: alpha)
        return CIImage(color: color).cropped(to: rect)
    }
}

public extension PTFilter {
    @objc static let all: [PTFilter] = [.normal, .clarendon, .nashville, .apply1977, .toaster, .chrome, .fade, .instant, .process, .transfer, .tone, .linear, .sepia, .mono, .noir, .tonal]
    
    @objc static let normal = PTFilter(name: "Normal", filterType: .normal)
    
    @objc static let clarendon = PTFilter(name: "Clarendon", applier: PTFilter.clarendonFilter)
    
    @objc static let nashville = PTFilter(name: "Nashville", applier: PTFilter.nashvilleFilter)
    
    @objc static let apply1977 = PTFilter(name: "1977", applier: PTFilter.apply1977Filter)
    
    @objc static let toaster = PTFilter(name: "Toaster", applier: PTFilter.toasterFilter)
    
    @objc static let chrome = PTFilter(name: "Chrome", filterType: .chrome)
    
    @objc static let fade = PTFilter(name: "Fade", filterType: .fade)
    
    @objc static let instant = PTFilter(name: "Instant", filterType: .instant)
    
    @objc static let process = PTFilter(name: "Process", filterType: .process)
    
    @objc static let transfer = PTFilter(name: "Transfer", filterType: .transfer)
    
    @objc static let tone = PTFilter(name: "Tone", filterType: .tone)
    
    @objc static let linear = PTFilter(name: "Linear", filterType: .linear)
    
    @objc static let sepia = PTFilter(name: "Sepia", filterType: .sepia)
    
    @objc static let mono = PTFilter(name: "Mono", filterType: .mono)
    
    @objc static let noir = PTFilter(name: "Noir", filterType: .noir)
    
    @objc static let tonal = PTFilter(name: "Tonal", filterType: .tonal)
}
