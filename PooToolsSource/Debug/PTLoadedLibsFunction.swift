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

struct PTLoadedLibrary {
    let name: String
    let path: String
    let isPrivate: Bool
    let size: String
    let address: String
    var classes: [String]
    var isExpanded: Bool = false
    var isLoading: Bool = false
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
    
    // MARK: - Properties
    private var allLibraries: [PTLoadedLibrary] = []
    private(set) var filteredLibraries: [PTLoadedLibrary] = []
    private var currentFilter: LibraryFilter = .all
    private var searchText: String = ""

    // Callback for UI updates
    var onLoadingStateChanged: ((Int) -> Void)?
    
    // MARK: - Public Methods
    
    func loadLibraries() {
        allLibraries = fetchLoadedLibraries()
        applyFilters()
    }
    
    func filterLibraries(by filter: LibraryFilter) {
        currentFilter = filter
        applyFilters()
    }
    
    func searchLibraries(with text: String) {
        searchText = text
        applyFilters()
    }
    
    func toggleLibraryExpansion(at index: Int) {
        guard index < filteredLibraries.count else { return }
        filteredLibraries[index].isExpanded.toggle()
        
        // Load classes if expanding and not yet loaded
        if filteredLibraries[index].isExpanded && filteredLibraries[index].classes.isEmpty {
            // Set loading state
            filteredLibraries[index].isLoading = true
            
            // Load classes asynchronously
            let libraryPath = filteredLibraries[index].path
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let classes = self?.fetchClasses(from: libraryPath) ?? []
                
                DispatchQueue.main.async {
                    guard let self = self, index < self.filteredLibraries.count else { return }
                    self.filteredLibraries[index].classes = classes
                    self.filteredLibraries[index].isLoading = false
                    
                    // Notify UI to update
                    self.onLoadingStateChanged?(index)
                }
            }
        }
    }
    
    func generateReport() -> String {
        var report = "=== Loaded Libraries Report ===\n"
        report += "Generated at: \(Date())\n"
        report += "Total Libraries: \(allLibraries.count)\n"
        report += "Private Libraries: \(allLibraries.filter { $0.isPrivate }.count)\n"
        report += "Public Libraries: \(allLibraries.filter { !$0.isPrivate }.count)\n\n"
        
        for library in allLibraries {
            report += "Library: \(library.name)\n"
            report += "  Path: \(library.path)\n"
            report += "  Type: \(library.isPrivate ? "Private" : "Public")\n"
            report += "  Size: \(library.size)\n"
            report += "  Address: \(library.address)\n"
            
            if !library.classes.isEmpty {
                report += "  Classes (\(library.classes.count)):\n"
                for className in library.classes.prefix(10) {
                    report += "    - \(className)\n"
                }
                if library.classes.count > 10 {
                    report += "    ... and \(library.classes.count - 10) more\n"
                }
            }
            report += "\n"
        }
        
        return report
    }
    
    // MARK: - Private Methods
    
    private func applyFilters() {
        filteredLibraries = allLibraries
        
        // Apply library type filter
        switch currentFilter {
        case .all:
            break
        case .public:
            filteredLibraries = filteredLibraries.filter { !$0.isPrivate }
        case .private:
            filteredLibraries = filteredLibraries.filter { $0.isPrivate }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            filteredLibraries = filteredLibraries.filter { library in
                library.name.lowercased().contains(lowercasedSearch) ||
                library.classes.contains { $0.lowercased().contains(lowercasedSearch) }
            }
        }
    }
    
    private func fetchLoadedLibraries() -> [PTLoadedLibrary] {
        var libraries: [PTLoadedLibrary] = []
        
        let imageCount = _dyld_image_count()
        
        for i in 0..<imageCount {
            guard let imageName = _dyld_get_image_name(i) else { continue }
            let name = String(cString: imageName)
            guard let header = _dyld_get_image_header(i) else { continue }
            _ = _dyld_get_image_vmaddr_slide(i)
            
            // Get file size
            let fileSize = getFileSize(at: name)
            
            // Determine if library is private
            let isPrivate = isPrivateLibrary(path: name)
            
            // Format address
            let address = String(format: "0x%lX", Int(bitPattern: header))
            
            // Extract library name from path
            let libraryName = (name as NSString).lastPathComponent
            
            libraries.append(PTLoadedLibrary(
                name: libraryName,
                path: name,
                isPrivate: isPrivate,
                size: fileSize,
                address: address,
                classes: []
            ))
        }
        
        return libraries.sorted { $0.name < $1.name }
    }
    
    private func fetchClasses(from libraryPath: String) -> [String] {
        var classes: [String] = []
        
        guard let handle = dlopen(libraryPath, RTLD_LAZY) else { return classes }
        defer { dlclose(handle) }
        
        // Get all classes registered with the Objective-C runtime
        var classCount: UInt32 = 0
        guard let classList = objc_copyClassList(&classCount) else { return classes }
        // AutoreleasingUnsafeMutablePointer is automatically managed by ARC
        
        // Convert to buffer pointer for safe iteration
        let buffer = UnsafeBufferPointer(start: classList, count: Int(classCount))
        
        for cls in buffer {
            // Check if class belongs to this library
            if let imageName = class_getImageName(cls),
               String(cString: imageName) == libraryPath {
                let className = String(cString: class_getName(cls))
                classes.append(className)
            }
        }
        
        return classes.sorted()
    }
    
    private func isPrivateLibrary(path: String) -> Bool {
        let publicPrefixes = [
            "/System/Library/",
            "/usr/lib/",
            "/Applications/Xcode.app/",
            "/Library/Developer/"
        ]
        
        let privatePrefixes = [
            "/System/Library/PrivateFrameworks/",
            "/usr/lib/system/introspection/"
        ]
        
        // Check private prefixes first
        for prefix in privatePrefixes {
            if path.hasPrefix(prefix) {
                return true
            }
        }
        
        // Check public prefixes
        for prefix in publicPrefixes {
            if path.hasPrefix(prefix) {
                return false
            }
        }
        
        // Default to private for app-specific libraries
        return true
    }
    
    private func getFileSize(at path: String) -> String {
        // Try file attributes first (works on simulator)
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            if let size = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: size, countStyle: .binary)
            }
        } catch {
            // File attributes failed - try alternative methods for device
        }
        
        // Alternative method: Use mach-o introspection for loaded libraries
        if let size = getLibrarySizeFromMachO(path: path) {
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .binary)
        }
        
        // Final fallback: Estimate from memory mapping
        if let size = estimateSizeFromMemoryLayout(path: path) {
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .binary)
        }
        
        return "N/A (Device)"
    }
    
    private func getLibrarySizeFromMachO(path: String) -> Int64? {
        let imageCount = _dyld_image_count()
        
        for i in 0..<imageCount {
            guard let imageName = _dyld_get_image_name(i),
                  String(cString: imageName) == path else { continue }
            
            guard let header = _dyld_get_image_header(i) else { continue }
            
            // Calculate actual file size from segments (not vmsize)
            var totalFileSize: Int64 = 0
            let headerPtr = UnsafeRawPointer(header)
            var cmdPtr = headerPtr.advanced(by: MemoryLayout<mach_header_64>.size)
            
            for _ in 0..<header.pointee.ncmds {
                let cmd = cmdPtr.assumingMemoryBound(to: load_command.self)
                
                if cmd.pointee.cmd == LC_SEGMENT_64 {
                    let segment = cmdPtr.assumingMemoryBound(to: segment_command_64.self)
                    // Use filesize instead of vmsize for accurate disk size
                    if segment.pointee.filesize > 0 {
                        totalFileSize += Int64(segment.pointee.filesize)
                    }
                }
                
                cmdPtr = cmdPtr.advanced(by: Int(cmd.pointee.cmdsize))
            }
            
            return totalFileSize > 0 ? totalFileSize : nil
        }
        
        return nil
    }
    
    private func estimateSizeFromMemoryLayout(path: String) -> Int64? {
        // Simplified estimation - try to get a reasonable approximation
        let imageCount = _dyld_image_count()
        
        for i in 0..<imageCount {
            guard let imageName = _dyld_get_image_name(i),
                  String(cString: imageName) == path else { continue }
            
            guard let header = _dyld_get_image_header(i) else { continue }
            
            // Count only TEXT and DATA segments for a more realistic estimate
            var estimatedSize: Int64 = 0
            let headerPtr = UnsafeRawPointer(header)
            var cmdPtr = headerPtr.advanced(by: MemoryLayout<mach_header_64>.size)
            
            for _ in 0..<header.pointee.ncmds {
                let cmd = cmdPtr.assumingMemoryBound(to: load_command.self)
                
                if cmd.pointee.cmd == LC_SEGMENT_64 {
                    let segment = cmdPtr.assumingMemoryBound(to: segment_command_64.self)
                    let segmentName = withUnsafePointer(to: segment.pointee.segname) {
                        $0.withMemoryRebound(to: CChar.self, capacity: 16) {
                            String(cString: $0)
                        }
                    }
                    
                    // Only count essential segments, not virtual memory
                    if segmentName == "__TEXT" || segmentName == "__DATA" || segmentName == "__DATA_CONST" {
                        estimatedSize += Int64(segment.pointee.filesize)
                    }
                }
                
                cmdPtr = cmdPtr.advanced(by: Int(cmd.pointee.cmdsize))
            }
            
            return estimatedSize > 0 ? estimatedSize : nil
        }
        
        return nil
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
        var instanceMethodCount: UInt32 = 0
        if let instanceMethods = class_copyMethodList(cls, &instanceMethodCount) {
            defer { free(instanceMethods) }
            for i in 0..<Int(instanceMethodCount) {
                let method = instanceMethods[i]
                let name = NSStringFromSelector(method_getName(method))
                let returnType = String(cString: method_copyReturnType(method))
                let argumentCount = method_getNumberOfArguments(method)
                var argTypes: [String] = []
                
                for j in 0..<argumentCount {
                    if let argTypeCStr = method_copyArgumentType(method, j) {
                        argTypes.append(String(cString: argTypeCStr))
                        free(UnsafeMutableRawPointer(mutating: argTypeCStr))
                    } else {
                        argTypes.append("Unknown")
                    }
                }

                free(UnsafeMutableRawPointer(mutating: method_copyReturnType(method)))

                methodList.append(MethodInfo(
                    name: name,
                    returnType: returnType,
                    argumentTypes: argTypes,
                    isClassMethod: false
                ))
            }
        }

        // Class methods
        if let metaClass = object_getClass(cls) {
            var classMethodCount: UInt32 = 0
            if let classMethods = class_copyMethodList(metaClass, &classMethodCount) {
                defer { free(classMethods) }
                for i in 0..<Int(classMethodCount) {
                    let method = classMethods[i]
                    let name = NSStringFromSelector(method_getName(method))
                    let returnType = String(cString: method_copyReturnType(method))
                    let argumentCount = method_getNumberOfArguments(method)
                    var argTypes: [String] = []

                    for j in 0..<argumentCount {
                        if let argTypeCStr = method_copyArgumentType(method, j) {
                            argTypes.append(String(cString: argTypeCStr))
                            free(UnsafeMutableRawPointer(mutating: argTypeCStr))
                        } else {
                            argTypes.append("Unknown")
                        }
                    }

                    free(UnsafeMutableRawPointer(mutating: method_copyReturnType(method)))

                    methodList.append(MethodInfo(
                        name: name,
                        returnType: returnType,
                        argumentTypes: argTypes,
                        isClassMethod: true
                    ))
                }
            }
        }

        self.methods = methodList.sorted {
            $0.name.localizedCompare($1.name) == .orderedAscending
        }
    }
    
    private func loadInstanceState() {
        guard let obj = instance else { return }

        var result: [InstanceProperty] = []
        let mirror = Mirror(reflecting: obj)
        for child in mirror.children {
            if let label = child.label {
                let valueStr = String(describing: child.value)
                result.append(InstanceProperty(name: label, value: valueStr))
            }
        }

        self.instanceProperties = result
    }
    
    // MARK: - Helper Methods
    
    private func parsePropertyAttributes(_ attributes: String) -> String {
        let components = attributes.components(separatedBy: ",")
        return components.filter { !$0.hasPrefix("T") }.joined(separator: ", ")
    }
    
    private func extractTypeFromAttributes(_ attributes: String) -> String {
        let components = attributes.components(separatedBy: ",")
        guard let typeComponent = components.first(where: { $0.hasPrefix("T") }) else {
            return "Unknown"
        }

        let typeCode = typeComponent.dropFirst()
        if typeCode.hasPrefix("@") {
            // Object type, extract class name
            if typeCode.count > 2 {
                return String(typeCode.dropFirst().dropLast())
            } else {
                return "AnyObject"
            }
        } else {
            // Primitive types
            switch typeCode {
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
            default: return "Unknown(\(typeCode))"
            }
        }
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
