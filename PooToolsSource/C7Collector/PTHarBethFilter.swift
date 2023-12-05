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
public typealias FilterResult = (filter: C7FilterProtocol?, maxminValue: maxminTuple, callback: FilterCallback?)

public class PTHarBethFilter:NSObject {
    
    public static let share = PTHarBethFilter(name: "", type: .cigaussian)
    
    public var tools:[PTHarBethFilter.FiltersTool] = PTHarBethFilter.FiltersTool.allCases
    
    public var name:String
    public var type:FiltersTool
    
    public init(name: String, type: FiltersTool) {
        self.name = name
        self.type = type
        super.init()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var texureSize:CGSize = CGSizeMake(CGFloat.kSCREEN_WIDTH, CGFloat.kSCREEN_HEIGHT)
    
    static func overTexture() -> MTLTexture? {
        let color = UIColor.green.withAlphaComponent(0.5)
        guard let texture = try? TextureLoader.emptyTexture(width: Int(PTHarBethFilter.share.texureSize.width), height: Int(PTHarBethFilter.share.texureSize.height)) else {
            return nil
        }
        let filter = C7SolidColor.init(color: color)
        let dest = BoxxIO(element: texture, filter: filter)
        return try? dest.output()
    }

    public func getCurrentFilterImage(image:UIImage?) -> UIImage {
        let dest = BoxxIO(element: image, filter: type.getFilterResult(texture:PTHarBethFilter.overTexture()).filter!)
        return (try? dest.output() ?? image!)!
    }
    
    public func getFilterResults() -> [FilterResult] {
        var ssss = [FilterResult]()
        tools.enumerated().forEach { index,value in
            ssss.append(value.getFilterResult(texture:PTHarBethFilter.overTexture()))
        }
        return ssss
    }
    
    @objc public enum FiltersTool: Int, CaseIterable {
        case none
        case brightness
        case contrast
        case saturation
        case cigaussian
        case hueblend
        case alphablend
        case luminosityblend
        case zoomblur
        case vignette
        case pixellated
        case crosshatch
        case polkadot
        case posterize
        case monochrome
        case voronoioverlay
        case monochromedilation
        case motionblur
        case meanblur
        case gaussianblur
        case bilateralblur
        case mpsgaussian
        case colormatrix4x4
        case convolution3x3
        case sharpen3x3
        case sepia
        case granularity
        case comicstrip
        case oilpainting
        case sketch
        case storyboard

        func getFilterResult(texture:MTLTexture?) -> FilterResult {
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
            case .cigaussian:
                var filter = CIGaussianBlur()
                filter.radius = 15
                return (filter, (CIGaussianBlur.range.value, CIGaussianBlur.range.min, CIGaussianBlur.range.max), {
                    filter.radius = $0
                    return filter
                })
            case .hueblend:
                var filter = C7Blend(with: .hue, blendTexture: texture)
                filter.intensity = 1
                return (filter, (R.iRange.value, R.iRange.min, R.iRange.max), {
                    filter.intensity = $0
                    return filter
                })
            case .alphablend:
                var filter = C7Blend(with: .alpha, blendTexture: texture)
                filter.intensity = 1
                return (filter, (R.iRange.value, R.iRange.min, R.iRange.max), {
                    filter.intensity = $0
                    return filter
                })
            case .luminosityblend:
                var filter = C7Blend(with: .luminosity, blendTexture: texture)
                filter.intensity = 1
                return (filter, (R.iRange.value, R.iRange.min, R.iRange.max), {
                    filter.intensity = $0
                    return filter
                })
            case .zoomblur:
                var filter = C7ZoomBlur()
                filter.radius = 10
                return (filter, (10, 5, 15), {
                    filter.radius = $0
                    return filter
                })
            case .vignette:
                var filter = C7Vignette()
                filter.color = UIColor.systemPink
                return (filter, (0.3, 0.1, filter.end), {
                    filter.start = $0
                    return filter
                })
            case .pixellated:
                var filter = C7Pixellated()
                return (filter, (C7Pixellated.range.value, C7Pixellated.range.min, C7Pixellated.range.max), {
                    filter.scale = $0
                    return filter
                })
            case .crosshatch:
                var filter = C7Crosshatch()
                return (filter, (0.03, 0.01, 0.08), {
                    filter.crosshatchSpacing = $0
                    return filter
                })
            case .polkadot:
                var filter = C7PolkaDot()
                filter.fractionalWidth = 0.05
                return (filter, (0.05, 0.01, 0.2), {
                    filter.fractionalWidth = $0
                    return filter
                })
            case .posterize:
                var filter = C7Posterize()
                filter.colorLevels = 2
                return (filter, (2, 0.5, 5), {
                    filter.colorLevels = $0
                    return filter
                })
            case .monochrome:
                var filter = C7Monochrome()
                return (filter, (R.iRange.value, R.iRange.min, R.iRange.max), {
                    filter.intensity = $0
                    return filter
                })
            case .voronoioverlay:
                var filter = C7VoronoiOverlay()
                return (filter, (0.5, 0.1, 0.6), {
                    filter.time = $0
                    return filter
                })
            case .monochromedilation:
                var filter = C7Monochrome()
                return (filter, (R.iRange.value, R.iRange.min, R.iRange.max), {
                    filter.intensity = $0
                    return filter
                })
            case .motionblur:
                var filter = C7MotionBlur()
                filter.blurAngle = 45
                filter.radius = 5
                return (filter, (5, 1, 10), {
                    filter.radius = $0
                    return filter
                })
            case .meanblur:
                var filter = C7MeanBlur()
                return (filter, (1, 0, 2), {
                    filter.radius = $0
                    return filter
                })
            case .gaussianblur:
                var filter = C7GaussianBlur()
                return (filter, (1, 0, 2), {
                    filter.radius = $0
                    return filter
                })
            case .bilateralblur:
                var filter = C7BilateralBlur()
                return (filter, (1, 0, 1), {
                    filter.radius = $0
                    return filter
                })
            case .mpsgaussian:
                var filter = MPSGaussianBlur()
                return (filter, (MPSGaussianBlur.range.value, MPSGaussianBlur.range.min, MPSGaussianBlur.range.max), {
                    filter.radius = $0
                    return filter
                })
            case .colormatrix4x4:
                var filter = C7ColorMatrix4x4(matrix: Matrix4x4.Color.replaced_red_green)
                return (filter, (R.iRange.value, R.iRange.min, R.iRange.max), {
                    filter.intensity = $0
                    return filter
                })
            case .convolution3x3:
                var filter = C7ConvolutionMatrix3x3(convolutionType: .embossment)
                return (filter, (R.iRange.value, R.iRange.min, R.iRange.max), {
                    filter.intensity = $0
                    return filter
                })
            case .sharpen3x3:
                var filter = C7ConvolutionMatrix3x3(convolutionType: .sharpen(iterations: 1))
                return (filter, (1, 0, 7), {
                    filter.updateConvolutionType(.sharpen(iterations: $0))
                    return filter
                })
            case .sepia:
                let filter = C7Sepia()
                return (filter, nil, nil)
            case .granularity:
                var filter = C7Granularity()
                filter.grain = 0.8
                return (filter, nil, nil)
            case .comicstrip:
                let filter = C7ComicStrip()
                return (filter, nil, nil)
            case .oilpainting:
                let filter = C7OilPainting()
                return (filter, nil, nil)
            case .sketch:
                var filter = C7Sketch()
                filter.edgeStrength = 0.3
                return (filter, nil, nil)
            case .storyboard:
                var filter = C7Storyboard()
                return (filter, (2, 1, 10), {
                    filter.ranks = Int(ceil($0))
                    return filter
                })
            case .none:
                return (nil, nil, nil)
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

public extension PTHarBethFilter {
    @objc static let cigaussian = PTHarBethFilter(name: "CI高斯模糊", type: .cigaussian)
    @objc static let hueBlend = PTHarBethFilter(name: "色相融合", type: .hueblend)
    @objc static let alphaBlend = PTHarBethFilter(name: "透明度融合", type: .alphablend)
    @objc static let luminosityBlend = PTHarBethFilter(name: "亮度融合", type: .luminosityblend)
    @objc static let zoomBlur = PTHarBethFilter(name: "中心点缩放模糊", type: .zoomblur)
    @objc static let vignette = PTHarBethFilter(name: "渐进效果", type: .vignette)
    @objc static let pixellated = PTHarBethFilter(name: "马赛克", type: .pixellated)
    @objc static let crosshatch = PTHarBethFilter(name: "绘制阴影线", type: .crosshatch)
    @objc static let polkadot = PTHarBethFilter(name: "波点", type: .polkadot)
    @objc static let posterize = PTHarBethFilter(name: "色调分离", type: .posterize)
    @objc static let monochrome = PTHarBethFilter(name: "黑白照片", type: .monochrome)
    @objc static let voronoioverlay = PTHarBethFilter(name: "教堂", type: .voronoioverlay)
    @objc static let monochromedilation = PTHarBethFilter(name: "黑白模糊", type: .monochromedilation)
    @objc static let motionblur = PTHarBethFilter(name: "移动模糊", type: .motionblur)
    @objc static let meanblur = PTHarBethFilter(name: "均值模糊", type: .meanblur)
    @objc static let gaussianblur = PTHarBethFilter(name: "高斯模糊", type: .gaussianblur)
    @objc static let bilateralblur = PTHarBethFilter(name: "双边模糊", type: .bilateralblur)
    @objc static let mpsgaussian = PTHarBethFilter(name: "MPS高斯模糊", type: .mpsgaussian)
    @objc static let colormatrix4x4 = PTHarBethFilter(name: "4x4矩阵", type: .colormatrix4x4)
    @objc static let convolution3x3 = PTHarBethFilter(name: "3x3卷积运算", type: .convolution3x3)
    @objc static let sharpen3x3 = PTHarBethFilter(name: "锐化卷积", type: .sharpen3x3)
    @objc static let sepia = PTHarBethFilter(name: "老照片", type: .sepia)
    @objc static let granularity = PTHarBethFilter(name: "颗粒感", type: .granularity)
    @objc static let comicstrip = PTHarBethFilter(name: "连环画", type: .comicstrip)
    @objc static let oilpainting = PTHarBethFilter(name: "油画", type: .oilpainting)
    @objc static let sketch = PTHarBethFilter(name: "扫描", type: .sketch)
    @objc static let storyboard = PTHarBethFilter(name: "分镜", type: .storyboard)
    @objc static let none = PTHarBethFilter(name: "原相机", type: .none)
}
