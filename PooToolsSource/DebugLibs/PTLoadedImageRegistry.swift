//
//  PTLoadedImageRegistry.swift
//  PooTools
//
// English: Maintains a lock-protected snapshot of dyld images without touching UIKit from callbacks.
// Español: Mantiene un snapshot protegido por bloqueo de las imágenes de dyld sin tocar UIKit desde los callbacks.
// 中文：维护受锁保护的 dyld 镜像快照，回调中不接触 UIKit。
//

import Foundation
import Darwin
import MachO
import os.lock

private struct PTLoadedImageRegistryState: Sendable {
    var images: [String: PTLoadedImageSnapshot] = [:]
    var callbacksRegistered = false
    var callbackAddCount = 0
    var callbackRemoveCount = 0
    var unresolvedPathCount = 0
}

enum PTLoadedImageRegistry {
    private static let state = OSAllocatedUnfairLock(initialState: PTLoadedImageRegistryState())

    static func snapshots() -> [PTLoadedImageSnapshot] {
        ensureStarted()
        return state.withLock { $0.images.values.sorted { lhs, rhs in
            if lhs.name == rhs.name {
                return lhs.identifier < rhs.identifier
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }}
    }

    static func refresh() -> [PTLoadedImageSnapshot] {
        ensureStarted()
        fallbackEnumeration()
        return snapshotsWithoutStarting()
    }

    static func diagnostics() -> (add: Int, remove: Int, unresolvedPath: Int) {
        state.withLock { ($0.callbackAddCount, $0.callbackRemoveCount, $0.unresolvedPathCount) }
    }

    static func mainExecutableSlide() -> Int? {
        ensureStarted()
        return state.withLock { $0.images.values.first(where: \.isMainExecutable)?.vmAddressSlide }
    }

    // English: Keep this insertion primitive small so dyld callbacks never perform inspection work.
    // Español: Mantiene pequeña esta operación para que los callbacks de dyld nunca inspeccionen datos pesados.
    // 中文：保持插入操作足够轻量，确保 dyld 回调不执行重型诊断。
    static func upsert(_ snapshot: PTLoadedImageSnapshot) {
        state.withLock { $0.images[snapshot.identifier] = snapshot }
    }

    static func remove(identifier: String) {
        state.withLock { _ = $0.images.removeValue(forKey: identifier) }
        PTLoadedLibraryInspectionCache.remove(identifier: identifier)
    }

    static func remove(headerAddress: UInt) {
        state.withLock { state in
            state.images = state.images.filter { $0.value.headerAddress != headerAddress }
        }
        PTLoadedLibraryInspectionCache.removeAll(matchingHeaderAddress: headerAddress)
    }

    private static func ensureStarted() {
        let shouldRegister = state.withLock { currentState -> Bool in
            guard !currentState.callbacksRegistered else { return false }
            currentState.callbacksRegistered = true
            return true
        }

        guard shouldRegister else { return }

        // English: Registration immediately replays current images, so no lock may be held here.
        // Español: El registro repite inmediatamente las imágenes actuales, por lo que aquí no se puede mantener el bloqueo.
        // 中文：注册时会立即回放当前镜像，因此这里不能持有锁。
        _dyld_register_func_for_add_image(ptLoadedImageAddCallback)
        _dyld_register_func_for_remove_image(ptLoadedImageRemoveCallback)

        if snapshotsWithoutStarting().isEmpty {
            fallbackEnumeration()
        }
    }

    private static func snapshotsWithoutStarting() -> [PTLoadedImageSnapshot] {
        state.withLock { $0.images.values.sorted { lhs, rhs in
            lhs.identifier < rhs.identifier
        }}
    }

    private static func fallbackEnumeration() {
        let imageCount = _dyld_image_count()
        guard imageCount > 0 else { return }

        for index in 0..<imageCount {
            guard let header = _dyld_get_image_header(index) else { continue }
            let imageName = _dyld_get_image_name(index).map { String(cString: $0) }
            let slide = _dyld_get_image_vmaddr_slide(index)
            if let snapshot = PTDyldImageProvider.makeSnapshot(header: header,
                                                               slide: slide,
                                                               source: .initialDyldEnumeration,
                                                               pathOverride: imageName) {
                upsert(snapshot)
            } else {
                state.withLock { $0.unresolvedPathCount += 1 }
            }
        }
    }

    fileprivate static func recordAdd(_ header: UnsafePointer<mach_header>?, slide: Int) {
        state.withLock { $0.callbackAddCount += 1 }
        guard let header,
              let snapshot = PTDyldImageProvider.makeSnapshot(header: header,
                                                              slide: slide,
                                                              source: .dyldAddCallback,
                                                              pathOverride: nil) else {
            state.withLock { $0.unresolvedPathCount += 1 }
            return
        }
        upsert(snapshot)
    }

    fileprivate static func recordRemove(_ header: UnsafePointer<mach_header>?, slide: Int) {
        state.withLock { $0.callbackRemoveCount += 1 }
        guard let header else { return }
        // English: The image may already be unmapped during removal, so only use its stable header address.
        // Español: La imagen puede estar ya descargada durante la eliminación; solo usamos su dirección de cabecera estable.
        // 中文：移除回调期间镜像可能已经解除映射，因此只使用稳定的头地址。
        remove(headerAddress: UInt(bitPattern: UnsafeRawPointer(header)))
    }
}

private func ptLoadedImageAddCallback(_ header: UnsafePointer<mach_header>?, _ slide: Int) {
    PTLoadedImageRegistry.recordAdd(header, slide: slide)
}

private func ptLoadedImageRemoveCallback(_ header: UnsafePointer<mach_header>?, _ slide: Int) {
    PTLoadedImageRegistry.recordRemove(header, slide: slide)
}

protocol PTLoadedImageProvider: Sendable {
    func snapshots() -> [PTLoadedImageSnapshot]
    func refresh() -> [PTLoadedImageSnapshot]
}

struct PTDyldImageProvider: PTLoadedImageProvider, Sendable {
    func snapshots() -> [PTLoadedImageSnapshot] {
        PTLoadedImageRegistry.snapshots()
    }

    func refresh() -> [PTLoadedImageSnapshot] {
        PTLoadedImageRegistry.refresh()
    }

    fileprivate static func makeSnapshot(header: UnsafePointer<mach_header>,
                                         slide: Int,
                                         source: PTLoadedImageSource,
                                         pathOverride: String?) -> PTLoadedImageSnapshot? {
        let headerAddress = UInt(bitPattern: UnsafeRawPointer(header))
        guard headerAddress != 0 else { return nil }

        let dladdrPath = pathOverride == nil ? path(from: header) : nil
        let resolvedPath = pathOverride ?? dladdrPath ?? ""
        let name = resolvedPath.isEmpty ? "<unnamed image>" : (resolvedPath as NSString).lastPathComponent
        let fileType = header.pointee.filetype
        let isMainExecutable = fileType == MH_EXECUTE
        let identifier = "\(headerAddress)|\(resolvedPath)"
        let resolvedSource = pathOverride != nil ? source : (dladdrPath == nil ? source : .dladdrResolved)

        return PTLoadedImageSnapshot(identifier: identifier,
                                     path: resolvedPath,
                                     name: name,
                                     headerAddress: headerAddress,
                                     vmAddressSlide: slide,
                                     isMainExecutable: isMainExecutable,
                                     fileType: UInt32(fileType),
                                     source: resolvedSource)
    }

    private static func path(from header: UnsafePointer<mach_header>) -> String? {
        var info = Dl_info()
        guard dladdr(UnsafeRawPointer(header), &info) != 0,
              let filename = info.dli_fname else {
            return nil
        }
        return String(cString: filename)
    }
}
