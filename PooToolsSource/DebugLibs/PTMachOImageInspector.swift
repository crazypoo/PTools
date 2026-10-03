//
//  PTMachOImageInspector.swift
//  PooTools
//
// English: Parses only bounded public Mach-O metadata and never walks unchecked load-command pointers.
// Español: Analiza solo metadatos Mach-O públicos y acotados, sin recorrer punteros de comandos sin validar.
// 中文：只解析有边界保护的公开 Mach-O 元数据，不遍历未经校验的加载命令指针。
//

import Foundation
import MachO

struct PTMachOSegment: Sendable, Hashable {
    let name: String
    let vmSize: UInt64
    let fileSize: UInt64
}

struct PTMachOImageInfo: Sendable, Hashable {
    let fileType: UInt32
    let architecture: String
    let uuid: UUID?
    let mappedSize: UInt64?
    let fileBackedSize: UInt64?
    let segments: [PTMachOSegment]
    let swiftMetadata: PTSwiftMetadataSummary
}

struct PTMachOInspection: Sendable, Hashable {
    let info: PTMachOImageInfo?
    let failure: String?
}

enum PTMachOImageInspector {
    private static let maxLoadCommandBytes = 64 * 1024 * 1024
    private static let maxLoadCommands = 4_096

    static func inspect(_ snapshot: PTLoadedImageSnapshot) -> PTMachOInspection {
        guard snapshot.headerAddress != 0,
              let headerPointer = UnsafeRawPointer(bitPattern: snapshot.headerAddress) else {
            return PTMachOInspection(info: nil, failure: "Header address unavailable")
        }

        let prefix = UnsafeRawBufferPointer(start: headerPointer, count: 32)
        guard let magic = readUInt32(prefix, offset: 0, swapped: false) else {
            return PTMachOInspection(info: nil, failure: "Mach-O header unavailable")
        }

        let is64Bit: Bool
        let isSwapped: Bool
        switch magic {
        case 0xfeedfacf:
            is64Bit = true
            isSwapped = false
        case 0xfeedface:
            is64Bit = false
            isSwapped = false
        case 0xcffaedfe:
            is64Bit = true
            isSwapped = true
        case 0xcefaedfe:
            is64Bit = false
            isSwapped = true
        default:
            return PTMachOInspection(info: nil, failure: "Unknown Mach-O magic")
        }

        guard let sizeofcmds = readUInt32(prefix, offset: 20, swapped: isSwapped),
              sizeofcmds > 0,
              Int(sizeofcmds) <= maxLoadCommandBytes else {
            return PTMachOInspection(info: nil, failure: "Invalid Mach-O load-command size")
        }

        let headerSize = is64Bit ? 32 : 28
        let totalSize = headerSize + Int(sizeofcmds)
        guard totalSize >= headerSize else {
            return PTMachOInspection(info: nil, failure: "Mach-O size overflow")
        }

        let data = Data(bytes: headerPointer, count: totalSize)
        return parse(data: data, is64Bit: is64Bit, isSwapped: isSwapped)
    }

    static func parse(data: Data) -> PTMachOInspection {
        guard data.count >= 28,
              let rawMagic = data.withUnsafeBytes({ readUInt32($0, offset: 0, swapped: false) }) else {
            return PTMachOInspection(info: nil, failure: "Mach-O data is too small")
        }

        let is64Bit: Bool
        let isSwapped: Bool
        switch rawMagic {
        case 0xfeedfacf:
            is64Bit = true
            isSwapped = false
        case 0xfeedface:
            is64Bit = false
            isSwapped = false
        case 0xcffaedfe:
            is64Bit = true
            isSwapped = true
        case 0xcefaedfe:
            is64Bit = false
            isSwapped = true
        default:
            return PTMachOInspection(info: nil, failure: "Unknown Mach-O magic")
        }

        return parse(data: data, is64Bit: is64Bit, isSwapped: isSwapped)
    }

    private static func parse(data: Data, is64Bit: Bool, isSwapped: Bool) -> PTMachOInspection {
        let headerSize = is64Bit ? 32 : 28
        guard data.count >= headerSize,
              let cpuType = data.withUnsafeBytes({ readUInt32($0, offset: 4, swapped: isSwapped) }),
              let cpuSubtype = data.withUnsafeBytes({ readUInt32($0, offset: 8, swapped: isSwapped) }),
              let fileType = data.withUnsafeBytes({ readUInt32($0, offset: 12, swapped: isSwapped) }),
              let commandCount = data.withUnsafeBytes({ readUInt32($0, offset: 16, swapped: isSwapped) }),
              let commandBytes = data.withUnsafeBytes({ readUInt32($0, offset: 20, swapped: isSwapped) }) else {
            return PTMachOInspection(info: nil, failure: "Mach-O header fields are truncated")
        }

        guard commandCount > 0,
              commandCount <= UInt32(maxLoadCommands),
              commandBytes > 0,
              Int(commandBytes) <= maxLoadCommandBytes,
              Int(commandBytes) <= data.count - headerSize else {
            return PTMachOInspection(info: nil, failure: "Mach-O load commands are outside bounds")
        }

        let commandEnd = headerSize + Int(commandBytes)
        var commandOffset = headerSize
        var segments: [PTMachOSegment] = []
        var swiftSections: [String] = []
        var swiftTypeSectionSize: UInt64?
        var uuid: UUID?
        var mappedSize: UInt64 = 0
        var fileBackedSize: UInt64 = 0

        for _ in 0..<Int(commandCount) {
            guard commandOffset >= headerSize,
                  commandOffset <= commandEnd - 8,
                  let command = data.withUnsafeBytes({ readUInt32($0, offset: commandOffset, swapped: isSwapped) }),
                  let commandSize = data.withUnsafeBytes({ readUInt32($0, offset: commandOffset + 4, swapped: isSwapped) }),
                  commandSize >= 8,
                  Int(commandSize) <= commandEnd - commandOffset else {
                return PTMachOInspection(info: nil, failure: "Malformed Mach-O load command")
            }

            let commandLength = Int(commandSize)
            switch command {
            case 0x19:
                guard commandLength >= 72 else {
                    return PTMachOInspection(info: nil, failure: "Truncated 64-bit segment command")
                }
                let segmentName = readCString(data: data, offset: commandOffset + 8, maxLength: 16)
                guard let vmSize = data.withUnsafeBytes({ readUInt64($0, offset: commandOffset + 32, swapped: isSwapped) }),
                      let fileSize = data.withUnsafeBytes({ readUInt64($0, offset: commandOffset + 48, swapped: isSwapped) }),
                      let sectionCount = data.withUnsafeBytes({ readUInt32($0, offset: commandOffset + 64, swapped: isSwapped) }),
                      sectionCount <= UInt32(maxLoadCommands) else {
                    return PTMachOInspection(info: nil, failure: "Invalid 64-bit segment fields")
                }
                let mappedResult = mappedSize.addingReportingOverflow(vmSize)
                guard !mappedResult.overflow else {
                    return PTMachOInspection(info: nil, failure: "Mapped size overflow")
                }
                mappedSize = mappedResult.partialValue

                let fileBackedResult = fileBackedSize.addingReportingOverflow(fileSize)
                guard !fileBackedResult.overflow else {
                    return PTMachOInspection(info: nil, failure: "File-backed size overflow")
                }
                fileBackedSize = fileBackedResult.partialValue
                segments.append(PTMachOSegment(name: segmentName, vmSize: vmSize, fileSize: fileSize))
                let sectionStart = commandOffset + 72
                let sectionSize = 80
                for sectionIndex in 0..<Int(sectionCount) {
                    let sectionOffset = sectionStart + sectionIndex * sectionSize
                    guard sectionOffset >= commandOffset,
                          sectionOffset <= commandOffset + commandLength - sectionSize else {
                        return PTMachOInspection(info: nil, failure: "64-bit section table exceeds command bounds")
                    }
                    let sectionName = readCString(data: data, offset: sectionOffset, maxLength: 16)
                    if sectionName.hasPrefix("__swift5_") {
                        swiftSections.append(sectionName)
                        if sectionName == "__swift5_types" {
                            swiftTypeSectionSize = data.withUnsafeBytes {
                                readUInt64($0, offset: sectionOffset + 40, swapped: isSwapped)
                            }
                        }
                    }
                }
            case 0x1:
                guard commandLength >= 56 else {
                    return PTMachOInspection(info: nil, failure: "Truncated 32-bit segment command")
                }
                let segmentName = readCString(data: data, offset: commandOffset + 8, maxLength: 16)
                guard let vmSize = data.withUnsafeBytes({ readUInt32($0, offset: commandOffset + 28, swapped: isSwapped) }),
                      let fileSize = data.withUnsafeBytes({ readUInt32($0, offset: commandOffset + 36, swapped: isSwapped) }),
                      let sectionCount = data.withUnsafeBytes({ readUInt32($0, offset: commandOffset + 48, swapped: isSwapped) }),
                      sectionCount <= UInt32(maxLoadCommands) else {
                    return PTMachOInspection(info: nil, failure: "Invalid 32-bit segment fields")
                }
                let vmSize64 = UInt64(vmSize)
                let fileSize64 = UInt64(fileSize)
                guard !mappedSize.addingReportingOverflow(vmSize64).overflow,
                      !fileBackedSize.addingReportingOverflow(fileSize64).overflow else {
                    return PTMachOInspection(info: nil, failure: "Segment size overflow")
                }
                mappedSize += vmSize64
                fileBackedSize += fileSize64
                segments.append(PTMachOSegment(name: segmentName, vmSize: vmSize64, fileSize: fileSize64))
                let sectionStart = commandOffset + 56
                let sectionSize = 68
                for sectionIndex in 0..<Int(sectionCount) {
                    let sectionOffset = sectionStart + sectionIndex * sectionSize
                    guard sectionOffset >= commandOffset,
                          sectionOffset <= commandOffset + commandLength - sectionSize else {
                        return PTMachOInspection(info: nil, failure: "32-bit section table exceeds command bounds")
                    }
                    let sectionName = readCString(data: data, offset: sectionOffset, maxLength: 16)
                    if sectionName.hasPrefix("__swift5_") {
                        swiftSections.append(sectionName)
                        if sectionName == "__swift5_types" {
                            swiftTypeSectionSize = data.withUnsafeBytes {
                                readUInt32($0, offset: sectionOffset + 36, swapped: isSwapped).map(UInt64.init)
                            }
                        }
                    }
                }
            case 0x1b:
                guard commandLength >= 24,
                      commandOffset + 24 <= data.count else {
                    return PTMachOInspection(info: nil, failure: "Truncated UUID command")
                }
                let bytes = Array(data[(commandOffset + 8)..<(commandOffset + 24)])
                if bytes.count == 16 {
                    uuid = UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3],
                                       bytes[4], bytes[5], bytes[6], bytes[7],
                                       bytes[8], bytes[9], bytes[10], bytes[11],
                                       bytes[12], bytes[13], bytes[14], bytes[15]))
                }
            default:
                break
            }

            commandOffset += commandLength
        }

        guard commandOffset == commandEnd else {
            return PTMachOInspection(info: nil, failure: "Mach-O command table did not terminate at its boundary")
        }

        let swiftMetadata = PTSwiftMetadataInspector.summary(sectionNames: swiftSections,
                                                               typeSectionSize: swiftTypeSectionSize)
        let info = PTMachOImageInfo(fileType: fileType,
                                    architecture: architecture(cpuType: cpuType, cpuSubtype: cpuSubtype),
                                    uuid: uuid,
                                    mappedSize: mappedSize == 0 ? nil : mappedSize,
                                    fileBackedSize: fileBackedSize == 0 ? nil : fileBackedSize,
                                    segments: segments,
                                    swiftMetadata: swiftMetadata)
        return PTMachOInspection(info: info, failure: nil)
    }

    private static func architecture(cpuType: UInt32, cpuSubtype: UInt32) -> String {
        switch cpuType {
        case 0x0100000c:
            return cpuSubtype & 0xFF == 2 ? "arm64e" : "arm64"
        case 0x01000007:
            return "x86_64"
        case 12:
            return "armv7"
        case 7:
            return "i386"
        default:
            return "cpu(0x\(String(cpuType, radix: 16)))"
        }
    }

    private static func readUInt32(_ buffer: UnsafeRawBufferPointer,
                                   offset: Int,
                                   swapped: Bool) -> UInt32? {
        guard offset >= 0, buffer.count >= 4, offset <= buffer.count - 4 else { return nil }
        let value = buffer.loadUnaligned(fromByteOffset: offset, as: UInt32.self)
        return swapped ? value.byteSwapped : value
    }

    private static func readUInt64(_ buffer: UnsafeRawBufferPointer,
                                   offset: Int,
                                   swapped: Bool) -> UInt64? {
        guard offset >= 0, buffer.count >= 8, offset <= buffer.count - 8 else { return nil }
        let value = buffer.loadUnaligned(fromByteOffset: offset, as: UInt64.self)
        return swapped ? value.byteSwapped : value
    }

    private static func readCString(data: Data, offset: Int, maxLength: Int) -> String {
        guard offset >= 0, offset < data.count, maxLength > 0 else { return "" }
        let end = min(offset.addingReportingOverflow(maxLength).overflow ? data.count : offset + maxLength,
                      data.count)
        let bytes = data[offset..<end]
        let length = bytes.firstIndex(of: 0).map { data.distance(from: data.startIndex, to: $0) - offset } ?? bytes.count
        return String(decoding: data[offset..<(offset + max(0, length))], as: UTF8.self)
    }
}
