// English: Provider reads explicit local inputs only and never performs runtime network discovery.
// Español: Provider solo lee entradas locales explícitas y nunca descubre dependencias por red en runtime.
// 中文：Provider 只读取明确的本地输入，运行时不会联网发现依赖。

import Foundation

public enum PTAcknowledgementsProvider {
    public static let defaultResourceName = "PTAcknowledgements"

    public static func load() throws -> PTLicenseManifest {
        try load(bundle: .main)
    }

    public static func load(bundle: Bundle) throws -> PTLicenseManifest {
        guard let url = bundle.url(forResource: defaultResourceName, withExtension: "json") else {
            throw PTAcknowledgementsError.missingManifest
        }
        return try load(fileURL: url)
    }

    public static func load(fileURL: URL) throws -> PTLicenseManifest {
        guard fileURL.isFileURL else { throw PTAcknowledgementsError.unreadableManifest }
        do {
            return try load(data: Data(contentsOf: fileURL, options: [.mappedIfSafe]))
        } catch let error as PTAcknowledgementsError {
            throw error
        } catch {
            throw PTAcknowledgementsError.unreadableManifest
        }
    }

    public static func load(data: Data) throws -> PTLicenseManifest {
        guard data.count <= 50 * 1024 * 1024 else {
            throw PTAcknowledgementsError.invalidJSON
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(PTLicenseManifest.self, from: data)
        } catch let error as PTAcknowledgementsError {
            throw error
        } catch let error as DecodingError {
            if case let .dataCorrupted(context) = error,
               context.underlyingError is PTAcknowledgementsError {
                throw context.underlyingError ?? PTAcknowledgementsError.invalidJSON
            }
            throw PTAcknowledgementsError.invalidJSON
        } catch {
            throw PTAcknowledgementsError.invalidJSON
        }
    }

    public static func make(
        entries: [PTAcknowledgement],
        generatorVersion: String? = nil,
        appTarget: String? = nil
    ) throws -> PTLicenseManifest {
        try PTLicenseManifest(
            generatorVersion: generatorVersion,
            appTarget: appTarget,
            entries: entries
        )
    }
}

public struct PTBundleAcknowledgementsDataSource: PTAcknowledgementsDataSource, Sendable {
    private let bundleIdentifier: String?

    public init(bundleIdentifier: String? = nil) {
        self.bundleIdentifier = bundleIdentifier
    }

    public func loadManifest() async throws -> PTLicenseManifest {
        let bundle = bundleIdentifier.flatMap(Bundle.init(identifier:)) ?? .main
        return try PTAcknowledgementsProvider.load(bundle: bundle)
    }
}

public struct PTFileAcknowledgementsDataSource: PTAcknowledgementsDataSource, Sendable {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func loadManifest() async throws -> PTLicenseManifest {
        try PTAcknowledgementsProvider.load(fileURL: fileURL)
    }
}

public struct PTInMemoryAcknowledgementsDataSource: PTAcknowledgementsDataSource, Sendable {
    public let manifest: PTLicenseManifest

    public init(manifest: PTLicenseManifest) {
        self.manifest = manifest
    }

    public func loadManifest() async throws -> PTLicenseManifest {
        manifest
    }
}
