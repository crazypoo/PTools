//
//  PTLoadedLibrariesViewModel.swift
//  PooTools
//
// English: Owns MainActor UI state while discovery and deep inspection stay outside the UI actor.
// Español: Mantiene el estado de UI en MainActor mientras el descubrimiento y la inspección profunda quedan fuera.
// 中文：由 MainActor 管理 UI 状态，把镜像发现和深度诊断放在 UI Actor 之外。
//

import Foundation

@MainActor
final class PTLoadedLibrariesViewModel {
    enum LibraryFilter {
        case all
        case `public`
        case `private`
    }

    private let provider: any PTLoadedImageProvider
    private let inspector: PTLoadedLibraryInspector
    private let configuration: PTLoadedLibsConfiguration
    private var snapshotsByID: [String: PTLoadedImageSnapshot] = [:]
    private var allLibraries: [PTLoadedLibrary] = []
    private(set) var filteredLibraries: [PTLoadedLibrary] = []
    private var currentFilter: LibraryFilter = .all
    private var searchText = ""
    private var updateGeneration = 0

    // English: The callback is MainActor-isolated so cells never receive background mutations.
    // Español: El callback está aislado en MainActor para que las celdas nunca reciban mutaciones en segundo plano.
    // 中文：回调隔离在 MainActor，避免 Cell 接收到后台线程的可变数据。
    var onLoadingStateChanged: (@MainActor @Sendable (Int) -> Void)?

    init(provider: any PTLoadedImageProvider = PTDyldImageProvider(),
         configuration: PTLoadedLibsConfiguration = .default) {
        self.provider = provider
        self.configuration = configuration
        inspector = PTLoadedLibraryInspector(configuration: configuration)
    }

    func loadLibraries() {
        update(with: provider.snapshots())
    }

    func refreshLibraries() {
        update(with: provider.refresh())
    }

    func filterLibraries(by filter: LibraryFilter) {
        currentFilter = filter
        applyFilters()
        notify(index: nil)
    }

    func searchLibraries(with text: String) {
        searchText = text
        applyFilters()
        notify(index: nil)
    }

    func toggleLibraryExpansion(at index: Int) {
        guard filteredLibraries.indices.contains(index) else { return }
        toggleLibraryExpansion(id: filteredLibraries[index].id)
    }

    func toggleLibraryExpansion(id: String) {
        guard let allIndex = allLibraries.firstIndex(where: { $0.id == id }) else { return }
        if allLibraries[allIndex].isExpanded {
            allLibraries[allIndex].isExpanded = false
            applyFilters()
            notify(index: filteredLibraries.firstIndex(where: { $0.id == id }))
            return
        }

        guard let snapshot = snapshotsByID[id] else {
            allLibraries[allIndex].inspectionState = .unavailable(reason: "Image snapshot unavailable")
            applyFilters()
            notify(index: filteredLibraries.firstIndex(where: { $0.id == id }))
            return
        }

        allLibraries[allIndex].isExpanded = true
        allLibraries[allIndex].inspectionState = .loading
        applyFilters()
        notify(index: filteredLibraries.firstIndex(where: { $0.id == id }))

        let inspector = self.inspector
        let generation = updateGeneration
        Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) {
                inspector.inspectObjectiveCClasses(snapshot)
            }.value

            guard let self,
                  generation == self.updateGeneration,
                  let updatedIndex = self.allLibraries.firstIndex(where: { $0.id == id }) else { return }
            self.allLibraries[updatedIndex].apply(classes: result)
            self.applyFilters()
            self.notify(index: self.filteredLibraries.firstIndex(where: { $0.id == id }))
        }
    }

    func generateReport() -> String {
        let diagnostics = diagnostics
        var report = "=== PTools Loaded Libraries Report ===\n"
        report += "PTools Version: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown")\n"
        report += "OS: \(ProcessInfo.processInfo.operatingSystemVersionString)\n"
        report += "Architecture: \(PTLoadedLibrariesViewModel.processArchitecture)\n"
        report += "Process: \(ProcessInfo.processInfo.processName)\n"
        report += "Generated At: \(Date())\n\n"
        report += "Image Registry:\n"
        report += "- Total: \(diagnostics.imageCount)\n"
        report += "- Registry: \(diagnostics.registryCount)\n"
        report += "- App Images: \(diagnostics.appImageCount)\n"
        report += "- System Images: \(diagnostics.systemImageCount)\n"
        report += "- Shared Cache Candidates: \(diagnostics.sharedCacheCandidateCount)\n"
        report += "- Callback Adds: \(diagnostics.callbackAddCount)\n"
        report += "- Callback Removes: \(diagnostics.callbackRemoveCount)\n"
        report += "- Path Resolution Failures: \(diagnostics.unresolvedPathCount)\n"
        report += "- File Metadata Unavailable: \(diagnostics.fileUnavailableCount)\n"
        report += "- Mach-O Parse Failures: \(diagnostics.machOFailureCount)\n"
        report += "- Objective-C Runtime Failures: \(diagnostics.objcRuntimeFailureCount)\n\n"

        for library in allLibraries {
            report += "Library: \(library.name)\n"
            report += "  Path: \(redactedPath(library.path))\n"
            report += "  Kind: \(library.kind.displayName)\n"
            report += "  Architecture: \(library.architecture ?? "Unavailable")\n"
            report += "  Backing: \(library.backing.displayName)\n"
            report += "  File Size: \(library.fileSizeDescription)\n"
            report += "  Mapped Size: \(library.mappedSizeDescription)\n"
            report += "  Address: \(library.address)\n"
            report += "  Slide: \(library.slide)\n"
            report += "  Objective-C Classes: \(library.objcClassesDescription)\n"
            report += "  Swift Metadata: \(library.swiftMetadataDescription)\n"
            if !library.classes.isEmpty {
                report += "  Objective-C Classes (first 10):\n"
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

    var diagnostics: PTLoadedLibsDiagnostics {
        let registry = PTLoadedImageRegistry.diagnostics()
        let machOFailures = allLibraries.filter { library in
            library.mappedSize == nil && library.inspectionState == .partiallyLoaded
        }.count
        let objcFailures = allLibraries.filter { library in
            if case .failed = library.objcInspection { return true }
            if case .unavailable = library.objcInspection { return true }
            return false
        }.count
        let appImageCount = allLibraries.count { library in
            switch library.kind {
            case .mainExecutable, .appFramework, .appDylib:
                return true
            case .systemFramework, .systemPrivateFramework, .systemDylib, .injectedImage, .unknown:
                return false
            }
        }
        let systemImageCount = allLibraries.count { library in
            switch library.kind {
            case .systemFramework, .systemPrivateFramework, .systemDylib:
                return true
            case .mainExecutable, .appFramework, .appDylib, .injectedImage, .unknown:
                return false
            }
        }
        let sharedCacheCandidateCount = allLibraries.count { $0.backing == .sharedCacheLikely }
        return PTLoadedLibsDiagnostics(imageCount: snapshotsByID.count,
                                       registryCount: allLibraries.count,
                                       callbackAddCount: registry.add,
                                       callbackRemoveCount: registry.remove,
                                       unresolvedPathCount: registry.unresolvedPath,
                                       fileUnavailableCount: allLibraries.filter { $0.fileSize == nil }.count,
                                       machOFailureCount: machOFailures,
                                       objcRuntimeFailureCount: objcFailures,
                                       appImageCount: appImageCount,
                                       systemImageCount: systemImageCount,
                                       sharedCacheCandidateCount: sharedCacheCandidateCount)
    }

    private func update(with snapshots: [PTLoadedImageSnapshot]) {
        updateGeneration &+= 1
        let oldLibraries = Dictionary(uniqueKeysWithValues: allLibraries.map { ($0.id, $0) })
        snapshotsByID = Dictionary(uniqueKeysWithValues: snapshots.map { ($0.identifier, $0) })
        allLibraries = snapshots.map { snapshot in
            var library = PTLoadedLibrary(snapshot: snapshot)
            if let oldLibrary = oldLibraries[snapshot.identifier] {
                library.isExpanded = oldLibrary.isExpanded
                library.fileSize = oldLibrary.fileSize
                library.mappedSize = oldLibrary.mappedSize
                library.architecture = oldLibrary.architecture
                library.uuid = oldLibrary.uuid
                library.backing = oldLibrary.backing
                library.capabilities = oldLibrary.capabilities
                library.objcClassCount = oldLibrary.objcClassCount
                library.objcInspection = oldLibrary.objcInspection
                library.swiftMetadata = oldLibrary.swiftMetadata
                library.segments = oldLibrary.segments
                library.classes = oldLibrary.classes
                library.inspectionState = oldLibrary.inspectionState
            }
            return library
        }
        applyFilters()
        notify(index: nil)

        let inspector = self.inspector
        let generation = updateGeneration
        Task { [weak self] in
            let metadata = await Task.detached(priority: .utility) {
                snapshots.map { snapshot in
                    (snapshot.identifier, inspector.inspectMetadata(snapshot))
                }
            }.value

            guard let self, generation == self.updateGeneration else { return }
            for (identifier, details) in metadata {
                guard let index = self.allLibraries.firstIndex(where: { $0.id == identifier }) else { continue }
                self.allLibraries[index].apply(metadata: details)
            }
            self.applyFilters()
            self.notify(index: nil)
        }
    }

    private func applyFilters() {
        var result = allLibraries
        switch currentFilter {
        case .all:
            break
        case .public:
            result = result.filter { !$0.isPrivate }
        case .private:
            result = result.filter(\.isPrivate)
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { library in
                library.name.lowercased().contains(query) ||
                library.path.lowercased().contains(query) ||
                library.kind.displayName.lowercased().contains(query) ||
                (library.architecture?.lowercased().contains(query) == true) ||
                (configuration.runtimeClassSearchEnabled && library.classes.contains { $0.lowercased().contains(query) })
            }
        }
        filteredLibraries = result
    }

    private func notify(index: Int?) {
        onLoadingStateChanged?(index ?? -1)
    }

    private func redactedPath(_ path: String) -> String {
        guard !path.isEmpty else { return "<UNRESOLVED>" }
        let bundlePath = Bundle.main.bundlePath
        if !bundlePath.isEmpty, path.hasPrefix(bundlePath) {
            return path.replacingOccurrences(of: bundlePath, with: "<APP_CONTAINER>")
        }
        return path
    }

    private static var processArchitecture: String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }
}
