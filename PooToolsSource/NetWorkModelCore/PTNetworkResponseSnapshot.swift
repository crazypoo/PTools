//
//  PTNetworkResponseSnapshot.swift
//
// English: Keep the transport response snapshot Foundation-only so model-path tests do not pull in UIKit.
// Español: Mantiene la instantánea de respuesta basada solo en Foundation para que las pruebas de rutas no arrastren UIKit.
// 中文：将传输响应快照保持为 Foundation-only，避免模型路径测试引入 UIKit。
//

import Foundation
#if SWIFT_PACKAGE
import PToolsCore
#endif

// English: A response snapshot keeps only Sendable values after the transport callback returns.
// Español: La instantánea conserva solo valores Sendable después de que termina el callback de transporte.
// 中文：传输回调结束后，响应快照只保留 Sendable 值。
public struct PTNetworkResponseSnapshot: Sendable {
    public let url: String
    public let data: Data?
    public let metadata: PTResponseMetadata

    public init(url: String, data: Data?, metadata: PTResponseMetadata) {
        self.url = url
        self.data = data
        self.metadata = metadata
    }
}
