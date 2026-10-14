//
//  BorderManager.swift
//
//  Created by Duraid Abdul.
//  Copyright © 2021 Duraid Abdul. All rights reserved.
//

import UIKit

// English: Handles enabling and disabling debug borders on a specified view.
// Español: Gestiona la activación y desactivación de bordes de depuración en una vista.
// 中文：负责在指定视图上启用和停用调试边框。
@MainActor
public class BorderManager {
    weak var layer: CALayer?
    
    // English: Debug configuration for the border overlay.
    // Español: Configuración de depuración para la superposición de bordes.
    // 中文：边框覆盖层的调试配置。
    static let outlineWidth = 1 - 1 / UIScreen.main.scale
    let outlineColor: CGColor
    
    // English: Cache the previous layer configuration for restoration.
    // Español: Guarda en caché la configuración anterior de la capa para restaurarla.
    // 中文：缓存图层之前的配置，以便恢复。
    var cachedWidth: CGFloat?
    var cachedColor: CGColor?
    
    public init(view: UIView) {
        layer = view.layer
        
        // English: Use different colors for different UIView types.
        // Español: Usa colores distintos para cada tipo de UIView.
        // 中文：为不同 UIView 类型使用不同颜色。
        if "\(view.classForCoder)".contains("UIImageView") {
            outlineColor = UIColor.systemGreen.withAlphaComponent(0.85).cgColor
        } else if "\(view.classForCoder)".contains("UILabel") {
            outlineColor = UIColor.systemBlue.withAlphaComponent(0.85).cgColor
        } else if "\(view.classForCoder)".contains("UIVisualEffectView") {
            outlineColor = UIColor.systemIndigo.withAlphaComponent(0.85).cgColor
        } else {
            outlineColor = UIColor.systemYellow.withAlphaComponent(0.85).cgColor
        }
    }
    
    // English: Activate the debug border and preserve the original layer values.
    // Español: Activa el borde de depuración y conserva los valores originales de la capa.
    // 中文：启用调试边框并保留图层原始值。
    public func activate() {
        cachedWidth = layer?.borderWidth
        cachedColor = layer?.borderColor
        
        layer?.borderWidth = Self.outlineWidth
        layer?.borderColor = outlineColor
    }
    
    // English: Deactivate the debug border and restore the previous layer values.
    // Español: Desactiva el borde de depuración y restaura los valores anteriores de la capa.
    // 中文：停用调试边框并恢复图层之前的值。
    public func deactivate() {
        
        guard let cachedWidth = cachedWidth, let cachedColor = cachedColor else {
            layer?.borderWidth = 0.0
            layer?.borderColor = UIColor.clear.cgColor
            return
        }
        
        // English: If the width changed after activation, keep the caller's new value.
        // Español: Si el ancho cambió después de la activación, conserva el nuevo valor del llamador.
        // 中文：如果启用后宽度发生变化，则保留调用方设置的新值。
        if layer?.borderWidth == Self.outlineWidth {
            layer?.borderWidth = cachedWidth
        }
        // English: If the color changed after activation, keep the caller's new value.
        // Español: Si el color cambió después de la activación, conserva el nuevo valor del llamador.
        // 中文：如果启用后颜色发生变化，则保留调用方设置的新值。
        if layer?.borderColor == outlineColor {
            layer?.borderColor = cachedColor
        }
    }
}
