//
//  PTModelUIKit.swift
//
// English: UIKit-only PTModel value codecs stay outside the Foundation model core.
// Español: Los codecs de valores exclusivos de UIKit permanecen fuera del núcleo de modelos Foundation.
// 中文：仅 UIKit 使用的 PTModel 值 codec 保持在 Foundation Model Core 之外。
//

#if canImport(UIKit)
import UIKit
import PToolsModelCore

public enum PTModelUIKitCodec {
    public static func hexColor(_ color: UIColor) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return "#00000000"
        }
        let components = [red, green, blue, alpha].map { max(0, min(255, Int(($0 * 255).rounded()))) }
        return String(format: "#%02X%02X%02X%02X", components[0], components[1], components[2], components[3])
    }

    public static func color(from value: PTJSONValue) throws -> UIColor {
        guard case .string(let raw) = value else {
            throw PTModelError.typeMismatch(expected: "hex color", actual: "non-string")
        }
        let hex = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard hex.count == 6 || hex.count == 8,
              let number = UInt64(hex, radix: 16) else {
            throw PTModelError.conversionFailed("Invalid hex color: \(raw)")
        }
        let red = CGFloat((number >> (hex.count == 8 ? 24 : 16)) & 0xFF) / 255
        let green = CGFloat((number >> (hex.count == 8 ? 16 : 8)) & 0xFF) / 255
        let blue = CGFloat((number >> (hex.count == 8 ? 8 : 0)) & 0xFF) / 255
        let alpha = hex.count == 8 ? CGFloat(number & 0xFF) / 255 : 1
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    // English: Encode common UIKit geometry as compact, stable JSON objects.
    // Español: Codifica geometría UIKit común como objetos JSON compactos y estables.
    // 中文：将常用 UIKit 几何值编码为紧凑稳定的 JSON 对象。
    public static func jsonValue(_ point: CGPoint) throws -> PTJSONValue {
        .object(["x": .number(try PTJSONNumber(String(point.x))),
                 "y": .number(try PTJSONNumber(String(point.y)))])
    }

    public static func jsonValue(_ size: CGSize) throws -> PTJSONValue {
        .object(["width": .number(try PTJSONNumber(String(size.width))),
                 "height": .number(try PTJSONNumber(String(size.height)))])
    }

    public static func jsonValue(_ rect: CGRect) throws -> PTJSONValue {
        .object(["origin": try jsonValue(rect.origin), "size": try jsonValue(rect.size)])
    }

    public static func point(from value: PTJSONValue) throws -> CGPoint {
        let object = try object(from: value)
        return CGPoint(x: try number(object, key: "x"), y: try number(object, key: "y"))
    }

    public static func size(from value: PTJSONValue) throws -> CGSize {
        let object = try object(from: value)
        return CGSize(width: try number(object, key: "width"), height: try number(object, key: "height"))
    }

    public static func rect(from value: PTJSONValue) throws -> CGRect {
        let object = try object(from: value)
        guard let origin = object["origin"], let size = object["size"] else {
            throw PTModelError.conversionFailed("CGRect requires origin and size")
        }
        return CGRect(origin: try point(from: origin), size: try size(from: size))
    }

    private static func object(from value: PTJSONValue) throws -> [String: PTJSONValue] {
        guard case .object(let object) = value else {
            throw PTModelError.typeMismatch(expected: "object", actual: "non-object")
        }
        return object
    }

    private static func number<T: BinaryFloatingPoint>(_ object: [String: PTJSONValue],
                                                       key: String) throws -> T {
        guard let value = object[key], case .number(let number) = value,
              let result = number.doubleValue.flatMap(T.init) else {
            throw PTModelError.conversionFailed("Missing geometry value: \(key)")
        }
        return result
    }
}
#endif
