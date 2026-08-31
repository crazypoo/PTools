//
//  PTEditModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

#if SWIFT_PACKAGE
// English: Import the shared filter model when ImageEditor is built as its own package target.
// Español: Importamos el modelo de filtros compartido cuando ImageEditor se compila como target independiente.
// 中文：ImageEditor 作为独立 Package target 编译时，显式导入共享滤镜模型。
import PooToolsHarbethKit
#endif

// English: Typed failures keep editor errors explicit without sending UIKit objects across actors.
// Español: Los fallos tipados mantienen explícitos los errores del editor sin enviar objetos UIKit entre actores.
// 中文：使用类型化错误明确表达编辑失败，避免跨 actor 传递 UIKit 对象。
public enum PTImageEditorError: Error, LocalizedError, Sendable, Equatable {
    case invalidOutputSize
    case outputTooLarge
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidOutputSize:
            return "编辑结果尺寸无效"
        case .outputTooLarge:
            return "编辑结果超过允许的最大尺寸"
        case .cancelled:
            return "编辑已取消"
        }
    }
}

// English: The typed completion result is delivered on the main actor because it contains UIKit values.
// Español: El resultado tipado se entrega en el actor principal porque contiene valores de UIKit.
// 中文：类型化完成结果在主 actor 回调，因为结果中包含 UIKit 对象。
@MainActor
public enum PTImageEditorResult {
    case success(image: UIImage, model: PTEditModel?)
    case cancelled
    case failure(PTImageEditorError)
}

//MARK: 编辑Model
public class PTEditModel:NSObject {
    public let drawPaths: [PTDrawPath]
    
    public let mosaicPaths: [PTDrawPath]
    
    public let clipStatus: PTClipStatus
    
    public let adjustStatus: PTAdjustStatus
    
    public let selectFilter: PTHarBethFilter?
    
    public let stickers: [PTBaseStickertState]
    
    public let actions: [PTMediaEditorAction]
    
    public init(drawPaths: [PTDrawPath],
                mosaicPaths: [PTDrawPath],
                clipStatus: PTClipStatus,
                adjustStatus: PTAdjustStatus,
                selectFilter: PTHarBethFilter,
                stickers: [PTBaseStickertState],
                actions: [PTMediaEditorAction]) {
        self.drawPaths = drawPaths
        self.mosaicPaths = mosaicPaths
        self.clipStatus = clipStatus
        self.adjustStatus = adjustStatus
        self.selectFilter = selectFilter
        self.stickers = stickers
        self.actions = actions
        super.init()
    }
}
