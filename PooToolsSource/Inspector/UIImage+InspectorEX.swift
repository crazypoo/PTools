//
//  UIImage+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import QuartzCore
import SafeSFSymbols

extension UIImage {
    func withOptions(_ imageOptions: UIImage.Option...) -> UIImage {
        withOptions(imageOptions)
    }
    
    func withOptions(_ imageOptions: UIImage.Options) -> UIImage {
        var newImage = self
        
        imageOptions.forEach { option in
            switch option {
            case let .renderingMode(renderingMode):
                newImage = newImage.withRenderingMode(renderingMode)
                
            #if swift(>=5.0)
            case let .tintColor(tintColor, renderingMode):
                newImage = newImage.withTintColor(tintColor, renderingMode: renderingMode)
            #endif
                
            case let .size(size):
                newImage = newImage.resized(size)
            }
        }
        
        return newImage
    }
    
    typealias Options = [Option]
    
    enum Option {
        /// The rendering mode controls how UIKit uses color information to display an image.
        case renderingMode(RenderingMode)
        
        #if swift(>=5.0)
        case tintColor(_ tintColor: UIColor, renderingMode: RenderingMode = .automatic)
        #endif

        case size(CGSize)
        
    }
}

public extension UIImage {
    
    func resized(_ newSize: CGSize) -> UIImage {
        guard newSize != size else {
            return self
        }
        
        let aspectRect = AVMakeRect(
            aspectRatio: size,
            insideRect: CGRect(
                origin: .zero,
                size: newSize
            )
        )
        
        let renderer = UIGraphicsImageRenderer(size: aspectRect.size)
        
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: aspectRect.size))
        }.withRenderingMode(renderingMode)
        
    }
    
}

extension UIImage {
    var assetName: String? {
        guard
            let regex = try? NSRegularExpression(pattern: "(?<=named\\().+(?=\\))|(?<=symbol\\()\\w+:\\s\\w+(?=\\))", options: .caseInsensitive),
            let firstMatch = regex.firstMatch(in: description)
        else {
            return nil
        }

        let assetName = description.substring(with: firstMatch.range)

        return assetName
    }

    var sizeDesription: String {
        guard
            let width = formatter.string(from: size.width * scale / screenScale),
            let height = formatter.string(from: size.height * scale / screenScale)
        else {
            return "None"
        }

        let sizeDesription = "w: \(width), h: \(height) @\(Int(screenScale))x"

        return sizeDesription
    }
}

private extension UIImage {
    static var sharedFormatter = NumberFormatter().then {
        $0.maximumFractionDigits = 1
    }

    var formatter: NumberFormatter {
        Self.sharedFormatter
    }

    var screenScale: CGFloat {
        UIScreen.main.scale
    }
}

extension UIImage {
    func maskImage(with mask: UIImage) -> UIImage? {
        guard let cgImage = cgImage else { return .none }
        let bounds = CGRect(origin: .zero, size: size)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return .none }
        context.translateBy(x: 0.0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        guard let mask = mask.cgImage else { return .none }
        context.clip(to: bounds, mask: mask)
        context.draw(cgImage, in: bounds)

        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return maskedImage
    }
}

extension UIImage {
    static func icon(_ name: String) -> UIImage? {
        Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: name)
    }
}

extension UIImage {
    @available(iOS 13, tvOS 13, *)
    public convenience init(_ symbol: SafeSFSymbol, weight: UIImage.SymbolWeight) {
        let configuration = UIImage.SymbolConfiguration(weight: weight)
        self.init(systemName: symbol.name, withConfiguration: configuration)!
    }
}

// MARK: - Element Inspector Panels

extension UIImage {
    static let elementAttributesPanel: UIImage = IconKit.imageOfSliderHorizontal().withRenderingMode(.alwaysTemplate)
    static let elementChildrenPanel: UIImage = IconKit.imageOfRelationshipDiagram().withRenderingMode(.alwaysTemplate)
    static let elementIdentityPanel: UIImage = .icon("identityPanel")!
    static let elementSizePanel: UIImage = IconKit.imageOfSetSquareFill().withRenderingMode(.alwaysTemplate)
}

extension UIImage {
    static let applicationIcon: UIImage = UIImage(.app.badgeFill)
    static let collapseMirroredSymbol: UIImage = .icon("collapse-mirrored")!
    static let collapseSymbol: UIImage = .icon("collapse")!
    static let expandSymbol: UIImage = .icon("expand")!
    static let hiddenViewSymbol: UIImage = .icon("Hidden-32_Normal")!
    static let infoOutlineSymbol: UIImage = .icon("info.circle")!
    static let infoSymbol: UIImage = IconKit.imageOfInfoCircleFill().withRenderingMode(.alwaysTemplate)
    static let missingSymbol: UIImage = .icon("missing-view-32_Normal")!
    static let warningSymbol: UIImage = .icon("exclamationmark.triangle")!
}

extension UIImage {
    static let chevronDownSymbol: UIImage = UIImage(.chevron.downCircle,weight: .regular)
    static let chevronRightSymbol: UIImage = UIImage(.chevron.rightCircle,weight: .regular)
    static let closeSymbol: UIImage =  UIImage(.xmark.circle,weight: .regular)
    static let copySymbol: UIImage = UIImage(.doc.onDoc,weight: .regular)
    static let emptyLayerAction: UIImage = UIImage(.questionmark.diamond,weight: .regular)
    static let layerAction: UIImage = UIImage(.square.stack_3dDownRightFill,weight: .regular)
    static let layerActionHideAll: UIImage = UIImage(.xmark.circleFill,weight: .regular)
    static let layerActionShowAll: UIImage = UIImage(.checkmark.circleFill,weight: .regular)
    static let wireframeAction: UIImage = UIImage(.square.stack_3dDownRight,weight: .regular)
}
