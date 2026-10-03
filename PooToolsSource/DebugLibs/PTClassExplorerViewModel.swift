//
//  PTClassExplorerViewModel.swift
//  PooTools
//
// English: Inspects one Objective-C runtime class and releases every copied runtime buffer.
// Español: Inspecciona una clase del runtime Objective-C y libera cada búfer copiado por el runtime.
// 中文：检查单个 Objective-C Runtime 类，并释放 Runtime 返回的所有复制缓冲区。
//

import Foundation
import ObjectiveC

@MainActor
final class PTClassExplorerViewModel {
    enum Section: Int, CaseIterable {
        case classInfo
        case properties
        case methods
        case instanceState
    }

    struct PropertyInfo {
        let name: String
        let type: String
        let attributes: String

        var description: String {
            "\(name): \(type) [\(attributes)]"
        }
    }

    struct MethodInfo {
        let name: String
        let returnType: String
        let argumentTypes: [String]
        let isClassMethod: Bool

        var description: String {
            let prefix = isClassMethod ? "+" : "-"
            return "\(prefix) \(name)(\(argumentTypes.joined(separator: ", "))) -> \(returnType)"
        }
    }

    struct InstanceProperty {
        let name: String
        let value: String
    }

    private let className: String
    private var classObject: AnyClass?
    private var instance: AnyObject?

    private(set) var classInfo: [(key: String, value: String)] = []
    private(set) var properties: [PropertyInfo] = []
    private(set) var methods: [MethodInfo] = []
    private(set) var instanceProperties: [InstanceProperty] = []

    var canCreateInstance: Bool {
        guard let classObject else { return false }
        return class_conformsToProtocol(classObject, NSObjectProtocol.self)
            && class_respondsToSelector(classObject, NSSelectorFromString("init"))
    }

    init(className: String) {
        self.className = className
        classObject = NSClassFromString(className)
    }

    func loadClassInfo() {
        guard let classObject else { return }
        loadBasicClassInfo(classObject)
        loadProperties(classObject)
        loadMethods(classObject)
    }

    func createInstance() {
        guard let objectType = classObject as? NSObject.Type else { return }
        instance = objectType.init()
        loadInstanceState()
    }

    private func loadBasicClassInfo(_ classObject: AnyClass) {
        var info: [(key: String, value: String)] = [
            ("Class", String(cString: class_getName(classObject))),
            ("Instance Size", "\(class_getInstanceSize(classObject)) bytes")
        ]

        if let superclass = class_getSuperclass(classObject) {
            info.append(("Superclass", String(cString: class_getName(superclass))))
        }

        var protocolCount: UInt32 = 0
        if let protocols = class_copyProtocolList(classObject, &protocolCount) {
            // English: class_copyProtocolList returns owned memory and must be freed once.
            // Español: class_copyProtocolList devuelve memoria propia que debe liberarse una sola vez.
            // 中文：class_copyProtocolList 返回拥有所有权的内存，必须准确释放一次。
            defer { free(UnsafeMutableRawPointer(protocols)) }
            let names = (0..<Int(protocolCount)).map { index in
                String(cString: protocol_getName(protocols[index]))
            }
            if !names.isEmpty {
                info.append(("Protocols", names.joined(separator: ", ")))
            }
        }

        if let imageName = class_getImageName(classObject) {
            info.append(("Image", (String(cString: imageName) as NSString).lastPathComponent))
        }
        classInfo = info
    }

    private func loadProperties(_ classObject: AnyClass) {
        var values: [PropertyInfo] = []
        var count: UInt32 = 0
        guard let properties = class_copyPropertyList(classObject, &count) else {
            self.properties = []
            return
        }
        defer { free(properties) }

        for index in 0..<Int(count) {
            let property = properties[index]
            let name = String(cString: property_getName(property))
            let attributes = property_getAttributes(property).map(String.init(cString:)) ?? ""
            values.append(PropertyInfo(name: name,
                                       type: extractType(from: attributes),
                                       attributes: parsePropertyAttributes(attributes)))
        }
        self.properties = values.sorted { $0.name < $1.name }
    }

    private func loadMethods(_ classObject: AnyClass) {
        var values: [MethodInfo] = []
        appendMethods(from: classObject, isClassMethod: false, to: &values)
        if let metaClass = object_getClass(classObject) {
            appendMethods(from: metaClass, isClassMethod: true, to: &values)
        }
        methods = values.sorted {
            $0.name.localizedCompare($1.name) == .orderedAscending
        }
    }

    private func appendMethods(from classObject: AnyClass,
                               isClassMethod: Bool,
                               to values: inout [MethodInfo]) {
        var count: UInt32 = 0
        guard let methodList = class_copyMethodList(classObject, &count) else { return }
        defer { free(methodList) }

        for index in 0..<Int(count) {
            let method = methodList[index]
            let argumentCount = method_getNumberOfArguments(method)
            var argumentTypes: [String] = []
            if argumentCount > 2 {
                for argumentIndex in 2..<argumentCount {
                    argumentTypes.append(copyArgumentType(method, index: argumentIndex))
                }
            }
            values.append(MethodInfo(name: NSStringFromSelector(method_getName(method)),
                                     returnType: copyReturnType(method),
                                     argumentTypes: argumentTypes,
                                     isClassMethod: isClassMethod))
        }
    }

    private func copyReturnType(_ method: Method) -> String {
        let pointer = method_copyReturnType(method)
        // English: The copied return-type string is released exactly once after conversion.
        // Español: La cadena copiada del tipo de retorno se libera exactamente una vez tras convertirla.
        // 中文：复制的返回值类型字符串转换后只释放一次。
        defer { free(UnsafeMutableRawPointer(pointer)) }
        return parseTypeEncoding(String(cString: pointer))
    }

    private func copyArgumentType(_ method: Method, index: UInt32) -> String {
        guard let pointer = method_copyArgumentType(method, index) else { return "Unknown" }
        defer { free(UnsafeMutableRawPointer(pointer)) }
        return parseTypeEncoding(String(cString: pointer))
    }

    private func loadInstanceState() {
        guard let instance else { return }
        instanceProperties = Mirror(reflecting: instance).children.compactMap { child in
            guard let label = child.label else { return nil }
            return InstanceProperty(name: label, value: String(describing: child.value))
        }
    }

    private func parsePropertyAttributes(_ attributes: String) -> String {
        attributes.split(separator: ",")
            .filter { !$0.hasPrefix("T") }
            .joined(separator: ", ")
    }

    private func extractType(from attributes: String) -> String {
        guard let component = attributes.split(separator: ",").first(where: { $0.hasPrefix("T") }) else {
            return "Unknown"
        }
        let code = component.dropFirst()
        if code.hasPrefix("@") {
            guard code.count > 2 else { return "AnyObject" }
            return String(code.dropFirst().dropLast())
        }
        switch code {
        case "i": return "Int"
        case "s": return "Int16"
        case "l": return "Int32"
        case "q": return "Int64"
        case "I": return "UInt"
        case "S": return "UInt16"
        case "L": return "UInt32"
        case "Q": return "UInt64"
        case "f": return "Float"
        case "d": return "Double"
        case "B": return "Bool"
        case "v": return "Void"
        default: return "Unknown(\(code))"
        }
    }

    private func parseTypeEncoding(_ encoding: String) -> String {
        if encoding.hasPrefix("@\"") && encoding.hasSuffix("\"") {
            return String(encoding.dropFirst(2).dropLast())
        }
        switch encoding {
        case "c": return "char"
        case "i": return "int"
        case "s": return "short"
        case "l": return "long"
        case "q": return "long long"
        case "C": return "unsigned char"
        case "I": return "unsigned int"
        case "S": return "unsigned short"
        case "L": return "unsigned long"
        case "Q": return "unsigned long long"
        case "f": return "float"
        case "d": return "double"
        case "B": return "bool"
        case "v": return "void"
        case "*": return "char *"
        case "@": return "id"
        case "#": return "Class"
        case ":": return "SEL"
        default: return encoding
        }
    }
}
