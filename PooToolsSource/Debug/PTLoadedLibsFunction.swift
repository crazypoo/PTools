//
//  PTLoadedLibsFunction.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 6/4/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import Foundation
import MachO
import ObjectiveC

class PTLoadedLibrary:PTBaseModel {
    var name: String = ""
    var path: String = ""
    var isPrivate: Bool = false
    var size: String = ""
    var address: String = ""
    var classes: [String] = []
    var isExpanded: Bool = false
    var isLoading: Bool = false
    
    init(name: String, path: String, isPrivate: Bool = false, size: String, address: String, classes: [String] = [], isExpanded: Bool = false, isLoading: Bool = false) {
        self.name = name
        self.path = path
        self.isPrivate = isPrivate
        self.size = size
        self.address = address
        self.classes = classes
        self.isExpanded = isExpanded
        self.isLoading = isLoading
    }
    
    required public init() {
        fatalError("init() has not been implemented")
    }
}

extension PTLoadedLibrary: Equatable {
    static func == (lhs: PTLoadedLibrary, rhs: PTLoadedLibrary) -> Bool {
        return lhs.path == rhs.path
    }
}

final class PTLoadedLibrariesViewModel: @unchecked Sendable {
    
    // MARK: - Public Types
    
    enum LibraryFilter {
        case all,`public`,`private`
    }
    
    struct State {
        var libraries: [PTLoadedLibrary] = []
        var filteredLibraries: [PTLoadedLibrary] = []
        var currentFilter: LibraryFilter = .all
        var searchText: String = ""
    }
    
    // MARK: - Properties
    
    private var state = State()
    private let syncQueue = DispatchQueue(label: "com.loadedLibraries.syncQueue", attributes: .concurrent)
    
    var onStateChanged: (([PTLoadedLibrary]) -> Void)?
    var onLibraryUpdated: ((String) -> Void)? // path based update
    
    // MARK: - Public Methods
    
    func loadLibraries() {
        DispatchQueue.global().async {
            let libraries = self.fetchLoadedLibraries()
            self.syncQueue.async(flags: .barrier) {
                self.state.libraries = libraries
                self.applyFilters()
            }
        }
    }
    
    func filterLibraries(by filter: LibraryFilter) {
        syncQueue.async(flags: .barrier) {
            self.state.currentFilter = filter
            self.applyFilters()
        }
    }
    
    func searchLibraries(with text: String) {
        syncQueue.async(flags: .barrier) {
            self.state.searchText = text
            self.applyFilters()
        }
    }
    
    func toggleLibraryExpansion(path: String) {
        syncQueue.async(flags: .barrier) {
            guard let index = self.state.filteredLibraries.firstIndex(where: { $0.path == path }) else { return }
            let library = self.state.filteredLibraries[index]
            library.isExpanded.toggle()
            self.state.filteredLibraries[index] = library
            
            guard library.isExpanded, library.classes.isEmpty, !library.isLoading else {
                DispatchQueue.main.async {
                    self.onLibraryUpdated?(path)
                }
                return
            }

            library.isLoading = true
            self.state.filteredLibraries[index] = library

            DispatchQueue.main.async {
                self.onLibraryUpdated?(path)
            }

            self.loadClassesAsync(for: library)
        }
    }
    
    func generateReport() -> String {
        var report = "=== Loaded Libraries Report ===\n"
        report += "Generated at: \(Date())\n"
        
        let libraries = syncQueue.sync { state.libraries }
        
        report += "Total Libraries: \(libraries.count)\n"
        report += "Private Libraries: \(libraries.filter { $0.isPrivate }.count)\n"
        report += "Public Libraries: \(libraries.filter { !$0.isPrivate }.count)\n\n"
        
        for lib in libraries {
            report += """
            Library: \(lib.name)
              Path: \(lib.path)
              Type: \(lib.isPrivate ? "Private" : "Public")
              Size: \(lib.size)
              Address: \(lib.address)
            """
            if !lib.classes.isEmpty {
                report += "\n  Classes (\(lib.classes.count)):\n"
                for cls in lib.classes.prefix(10) {
                    report += "    - \(cls)\n"
                }
                if lib.classes.count > 10 {
                    report += "    ... and \(lib.classes.count - 10) more\n"
                }
            }
            report += "\n\n"
        }
        return report
    }
    
    // MARK: - Internal Filter Logic
    
    private func applyFilters() {
        var result = state.libraries
        
        switch state.currentFilter {
        case .public:
            result = result.filter { !$0.isPrivate }
        case .private:
            result = result.filter { $0.isPrivate }
        case .all:
            break
        }

        if !state.searchText.isEmpty {
            let search = state.searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(search) ||
                $0.classes.contains(where: { $0.lowercased().contains(search) })
            }
        }
        
        state.filteredLibraries = result
        
        DispatchQueue.main.async {
            self.onStateChanged?(result)
        }
    }
    
    // MARK: - Class Fetching
    
    private func loadClassesAsync(for library: PTLoadedLibrary) {
        let path = library.path
        DispatchQueue.global().async {
            let fetched = self.fetchClasses(from: path)
            self.syncQueue.async(flags: .barrier) {
                guard let index = self.state.filteredLibraries.firstIndex(where: { $0.path == path }) else { return }
                let updated = self.state.filteredLibraries[index]
                updated.classes = fetched
                updated.isLoading = false
                self.state.filteredLibraries[index] = updated
                
                DispatchQueue.main.async {
                    self.onLibraryUpdated?(path)
                }
            }
        }
    }
}

extension PTLoadedLibrariesViewModel {
    
    fileprivate func fetchLoadedLibraries() -> [PTLoadedLibrary] {
        var libraries: [PTLoadedLibrary] = []
        let count = _dyld_image_count()
        
        for i in 0..<count {
            guard let cName = _dyld_get_image_name(i) else { continue }
            let path = String(cString: cName)
            let header = _dyld_get_image_header(i)
            let address = String(format: "0x%lX", Int(bitPattern: header))

            let libraryName = (path as NSString).lastPathComponent
            let isPrivate = checkIfPrivate(path)
            let size = formattedFileSize(at: path)
            
            libraries.append(PTLoadedLibrary(
                name: libraryName,
                path: path,
                isPrivate: isPrivate,
                size: size,
                address: address
            ))
        }
        
        return libraries.sorted { $0.name < $1.name }
    }

    private func fetchClasses(from libraryPath: String) -> [String] {
        var classes: [String] = []
        
        guard let handle = dlopen(libraryPath, RTLD_LAZY) else { return classes }
        defer { dlclose(handle) }

        var classList: AutoreleasingUnsafeMutablePointer<AnyClass>? = nil
        var classCount: UInt32 = 0

        // 切換到主線程執行 objc_copyClassList 以避免崩潰
        DispatchQueue.main.sync {
            classList = objc_copyClassList(&classCount)
        }

        guard let list = classList else { return classes }

        // 使用 UnsafeBufferPointer 遍歷 class 列表
        let buffer = UnsafeBufferPointer(start: list, count: Int(classCount))
        for cls in buffer {
            if let imageName = class_getImageName(cls),
               String(cString: imageName) == libraryPath {
                let className = String(cString: class_getName(cls))
                classes.append(className)
            }
        }

        return classes.sorted()
    }
    
    fileprivate func checkIfPrivate(_ path: String) -> Bool {
        let privatePrefixes = ["/System/Library/PrivateFrameworks/", "/usr/lib/system/introspection/"]
        for prefix in privatePrefixes where path.hasPrefix(prefix) {
            return true
        }
        return !path.hasPrefix("/System/Library/") && !path.hasPrefix("/usr/lib/")
    }

    fileprivate func formattedFileSize(at path: String) -> String {
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: path)
            if let size = attrs[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: size, countStyle: .binary)
            }
        } catch {}
        return "Unknown"
    }
}

final class PTClassExplorerViewModel {
    
    // MARK: - Types
    
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
            let args = argumentTypes.joined(separator: ", ")
            return "\(prefix) \(name)(\(args)) -> \(returnType)"
        }
    }
    
    struct InstanceProperty {
        let name: String
        let value: String
    }
    
    // MARK: - Properties
    
    private let className: String
    private var classObject: AnyClass?
    private var instance: AnyObject?
    
    private(set) var classInfo: [(key: String, value: String)] = []
    private(set) var properties: [PropertyInfo] = []
    private(set) var methods: [MethodInfo] = []
    private(set) var instanceProperties: [InstanceProperty] = []
    
    var canCreateInstance: Bool {
        guard let cls = classObject else { return false }
        
        // Check if it's an NSObject subclass and has init method
        if class_conformsToProtocol(cls, NSObjectProtocol.self) {
            return class_respondsToSelector(cls, NSSelectorFromString("init"))
        }
        
        return false
    }
    
    // MARK: - Initialization
    
    init(className: String) {
        self.className = className
        self.classObject = NSClassFromString(className)
    }
    
    // MARK: - Public Methods
    
    func loadClassInfo() {
        guard let cls = classObject else { return }
        
        loadBasicClassInfo(cls)
        loadProperties(cls)
        loadMethods(cls)
    }
    
    func createInstance() {
        guard let cls = classObject as? NSObject.Type else { return }
        
        instance = cls.init()
        loadInstanceState()
    }
    
    // MARK: - Private Methods
    
    private func loadBasicClassInfo(_ cls: AnyClass) {
        var info: [(key: String, value: String)] = []
        
        // Class name
        info.append(("Class", String(cString: class_getName(cls))))
        
        // Superclass
        if let superclass = class_getSuperclass(cls) {
            info.append(("Superclass", String(cString: class_getName(superclass))))
        }
        
        // Instance size
        let instanceSize = class_getInstanceSize(cls)
        info.append(("Instance Size", "\(instanceSize) bytes"))
        
        // Protocols
        var protocolCount: UInt32 = 0
        if let protocols = class_copyProtocolList(cls, &protocolCount) {
            // AutoreleasingUnsafeMutablePointer is automatically managed by ARC
            
            var protocolNames: [String] = []
            for i in 0..<Int(protocolCount) {
                let proto = protocols[i]
                protocolNames.append(String(cString: protocol_getName(proto)))
            }
            
            if !protocolNames.isEmpty {
                info.append(("Protocols", protocolNames.joined(separator: ", ")))
            }
        }
        
        // Image name
        if let imageName = class_getImageName(cls) {
            let imageNameString = String(cString: imageName)
            info.append(("Image", (imageNameString as NSString).lastPathComponent))
        }
        
        classInfo = info
    }
    
    private func loadProperties(_ cls: AnyClass) {
        var propertyList: [PropertyInfo] = []
        
        var propertyCount: UInt32 = 0
        if let properties = class_copyPropertyList(cls, &propertyCount) {
            defer { free(properties) }
            
            for i in 0..<Int(propertyCount) {
                let property = properties[i]
                let name = String(cString: property_getName(property))
                
                var type = "Unknown"
                var attributes = ""
                
                if let attributesCString = property_getAttributes(property) {
                    let attributesString = String(cString: attributesCString)
                    attributes = parsePropertyAttributes(attributesString)
                    type = extractTypeFromAttributes(attributesString)
                }
                
                propertyList.append(PropertyInfo(
                    name: name,
                    type: type,
                    attributes: attributes
                ))
            }
        }
        
        self.properties = propertyList.sorted { $0.name < $1.name }
    }
    
    private func loadMethods(_ cls: AnyClass) {
        var methodList: [MethodInfo] = []
        
        // Instance methods
        var methodCount: UInt32 = 0
        if let methods = class_copyMethodList(cls, &methodCount) {
            defer { free(methods) }
            
            for i in 0..<Int(methodCount) {
                let method = methods[i]
                let selector = method_getName(method)
                let name = NSStringFromSelector(selector)
                
                let methodInfo = createMethodInfo(
                    method: method,
                    name: name,
                    isClassMethod: false
                )
                methodList.append(methodInfo)
            }
        }
        
        // Class methods
        if let metaClass = object_getClass(cls) {
            methodCount = 0
            if let methods = class_copyMethodList(metaClass, &methodCount) {
                defer { free(methods) }
                
                for i in 0..<Int(methodCount) {
                    let method = methods[i]
                    let selector = method_getName(method)
                    let name = NSStringFromSelector(selector)
                    
                    // Skip meta methods
                    if name.hasPrefix(".") { continue }
                    
                    let methodInfo = createMethodInfo(
                        method: method,
                        name: name,
                        isClassMethod: true
                    )
                    methodList.append(methodInfo)
                }
            }
        }
        
        self.methods = methodList.sorted { $0.name < $1.name }
    }
    
    private func loadInstanceState() {
        guard let instance = instance else { return }
        
        var propertyList: [InstanceProperty] = []
        
        // Get values for all properties
        for property in properties {
            let value = getPropertyValue(instance: instance, propertyName: property.name)
            propertyList.append(InstanceProperty(
                name: property.name,
                value: value
            ))
        }
        
        self.instanceProperties = propertyList
    }
    
    // MARK: - Helper Methods
    
    private func parsePropertyAttributes(_ attributes: String) -> String {
        var parsed: [String] = []
        
        if attributes.contains(",R") { parsed.append("readonly") }
        if attributes.contains(",C") { parsed.append("copy") }
        if attributes.contains(",&") { parsed.append("strong") }
        if attributes.contains(",N") { parsed.append("nonatomic") }
        if attributes.contains(",W") { parsed.append("weak") }
        
        return parsed.joined(separator: ", ")
    }
    
    private func extractTypeFromAttributes(_ attributes: String) -> String {
        // Extract type from property attributes
        if let typeStart = attributes.firstIndex(of: "T"),
           let typeEnd = attributes.firstIndex(of: ",") {
            let typeString = String(attributes[attributes.index(after: typeStart)..<typeEnd])
            return parseTypeEncoding(typeString)
        }
        return "Unknown"
    }
    
    private func parseTypeEncoding(_ encoding: String) -> String {
        if encoding.hasPrefix("@\"") && encoding.hasSuffix("\"") {
            // Object type
            return String(encoding.dropFirst(2).dropLast(1))
        }
        
        // Basic type encodings
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
    
    private func createMethodInfo(method: Method, name: String, isClassMethod: Bool) -> MethodInfo {
        let returnType = parseMethodTypeEncoding(method_copyReturnType(method))
        
        var argumentTypes: [String] = []
        let argCount = method_getNumberOfArguments(method)
        
        // Skip self and _cmd
        for i in 2..<argCount {
            if let argType = method_copyArgumentType(method, i) {
                argumentTypes.append(parseMethodTypeEncoding(argType))
            }
        }
        
        return MethodInfo(
            name: name,
            returnType: returnType,
            argumentTypes: argumentTypes,
            isClassMethod: isClassMethod
        )
    }
    
    private func parseMethodTypeEncoding(_ encoding: UnsafeMutablePointer<CChar>?) -> String {
        guard let encoding = encoding else { return "Unknown" }
        defer { free(encoding) }
        
        let typeString = String(cString: encoding)
        return parseTypeEncoding(typeString)
    }
    
    private func getPropertyValue(instance: AnyObject, propertyName: String) -> String {
        let mirror = Mirror(reflecting: instance)
        
        for child in mirror.children {
            if child.label == propertyName {
                if let value = child.value as? CustomStringConvertible {
                    return value.description
                } else {
                    return String(describing: child.value)
                }
            }
        }
        
        // Try using KVC
        if instance.responds(to: NSSelectorFromString(propertyName)) {
            if let value = instance.value(forKey: propertyName) {
                return String(describing: value)
            }
        }
        
        return "N/A"
    }
}
