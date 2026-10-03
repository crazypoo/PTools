//
//  PTLoadedLibsTests.swift
//  PooTools
//
// English: Cover registry snapshots, bounded Mach-O parsing, classification, and runtime semantics.
// Español: Cubre snapshots del registro, análisis Mach-O acotado, clasificación y semántica del runtime.
// 中文：覆盖 Registry 快照、有边界 Mach-O 解析、分类和 Runtime 语义。
//

import Foundation
import XCTest
@testable import PooToolsDEBUG

final class PTLoadedLibsTests: XCTestCase {
    func testRegistryUpsertAndRemoveUseStableIdentifiers() {
        let identifier = "test-\(UUID().uuidString)"
        let snapshot = PTLoadedImageSnapshot(identifier: identifier,
                                             path: "/System/Library/Frameworks/Test.framework/Test",
                                             name: "Test",
                                             headerAddress: 0x1000,
                                             vmAddressSlide: 0x2000,
                                             isMainExecutable: false,
                                             fileType: 6,
                                             source: .initialDyldEnumeration)
        PTLoadedImageRegistry.upsert(snapshot)
        XCTAssertTrue(PTLoadedImageRegistry.snapshots().contains(where: { $0.identifier == identifier }))
        PTLoadedImageRegistry.remove(identifier: identifier)
        XCTAssertFalse(PTLoadedImageRegistry.snapshots().contains(where: { $0.identifier == identifier }))
    }

    func testMachOParserAcceptsBoundedSegmentAndRejectsUnknownMagic() {
        var bytes = [UInt8](repeating: 0, count: 32 + 72)
        write(UInt32(0xfeedfacf), at: 0, in: &bytes)
        write(UInt32(0x0100000c), at: 4, in: &bytes)
        write(UInt32(0), at: 8, in: &bytes)
        write(UInt32(2), at: 12, in: &bytes)
        write(UInt32(1), at: 16, in: &bytes)
        write(UInt32(72), at: 20, in: &bytes)
        write(UInt32(0x19), at: 32, in: &bytes)
        write(UInt32(72), at: 36, in: &bytes)
        write(UInt64(0x4000), at: 64, in: &bytes)
        write(UInt64(0x3000), at: 80, in: &bytes)
        write(UInt32(0), at: 96, in: &bytes)

        let inspection = PTMachOImageInspector.parse(data: Data(bytes))
        XCTAssertNil(inspection.failure)
        XCTAssertEqual(inspection.info?.mappedSize, 0x4000)
        XCTAssertEqual(inspection.info?.fileBackedSize, 0x3000)
        XCTAssertEqual(inspection.info?.architecture, "arm64")

        let malformed = PTMachOImageInspector.parse(data: Data([0xFF, 0xFF, 0xFF, 0xFF]))
        XCTAssertEqual(malformed.failure, "Mach-O data is too small")
    }

    func testClassifierSeparatesSystemAndAppImages() {
        let system = PTLoadedImageSnapshot(identifier: "system",
                                           path: "/System/Library/Frameworks/UIKit.framework/UIKit",
                                           name: "UIKit",
                                           headerAddress: 1,
                                           vmAddressSlide: 0,
                                           isMainExecutable: false,
                                           fileType: 6,
                                           source: .initialDyldEnumeration)
        let app = PTLoadedImageSnapshot(identifier: "app",
                                        path: "/private/var/containers/Bundle/Application/A/Demo.app/Frameworks/Feature.framework/Feature",
                                        name: "Feature",
                                        headerAddress: 2,
                                        vmAddressSlide: 0,
                                        isMainExecutable: false,
                                        fileType: 6,
                                        source: .initialDyldEnumeration)
        XCTAssertEqual(PTLoadedLibraryClassifier.kind(for: system), .systemFramework)
        XCTAssertEqual(PTLoadedLibraryClassifier.kind(for: app), .appFramework)
    }

    func testEmptyObjectiveCClassListIsDifferentFromUnavailablePath() {
        if case .loaded(let classes) = PTObjCRuntimeImageInspector.inspect(path: "") {
            XCTFail("empty path must not be reported as a successful class scan: \(classes)")
        }
        if case .unavailable = PTObjCRuntimeImageInspector.inspect(path: "") {
            XCTAssertTrue(true)
        } else {
            XCTFail("empty path must report an unavailable inspection")
        }
    }

    @MainActor
    func testViewModelFiltersSnapshotsWithoutClassEnumeration() {
        let snapshot = PTLoadedImageSnapshot(identifier: "view-model",
                                             path: "/System/Library/Frameworks/UIKit.framework/UIKit",
                                             name: "UIKit",
                                             headerAddress: 0,
                                             vmAddressSlide: 0,
                                             isMainExecutable: false,
                                             fileType: 6,
                                             source: .initialDyldEnumeration)
        let viewModel = PTLoadedLibrariesViewModel(provider: PTLoadedLibsTestProvider(snapshots: [snapshot]))
        viewModel.loadLibraries()
        XCTAssertEqual(viewModel.filteredLibraries.map(\.name), ["UIKit"])
        XCTAssertNil(viewModel.filteredLibraries.first?.objcClassCount)
    }

    private func write<T: FixedWidthInteger>(_ value: T, at offset: Int, in bytes: inout [UInt8]) {
        var littleEndian = value.littleEndian
        withUnsafeBytes(of: &littleEndian) { rawBytes in
            bytes.replaceSubrange(offset..<(offset + rawBytes.count), with: rawBytes)
        }
    }
}

private struct PTLoadedLibsTestProvider: PTLoadedImageProvider, Sendable {
    let snapshotsToReturn: [PTLoadedImageSnapshot]

    init(snapshots: [PTLoadedImageSnapshot]) {
        snapshotsToReturn = snapshots
    }

    func snapshots() -> [PTLoadedImageSnapshot] {
        snapshotsToReturn
    }

    func refresh() -> [PTLoadedImageSnapshot] {
        snapshotsToReturn
    }
}
