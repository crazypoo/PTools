import Foundation

/// Shared wire types for explicitly authorized developer diagnostics.
/// Deliberately independent of UIKit, AppKit, and capture implementation.
public enum PTStudioDiagnosticDomain: String, Codable, Sendable, CaseIterable {
    case inspector, storage, defaults, database, logging, performance
}

public struct PTStudioRect: Codable, Sendable, Equatable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }
}

public struct PTStudioDiagnosticEntry: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var parentID: String?
    public var kind: String
    public var name: String
    public var detail: String?
    public var frame: PTStudioRect?
    public var attributes: [String: String]
    public var previewBase64: String?

    public init(id: String, parentID: String? = nil, kind: String,
                name: String, detail: String? = nil, frame: PTStudioRect? = nil,
                attributes: [String: String] = [:], previewBase64: String? = nil) {
        self.id = id; self.parentID = parentID
        self.kind = kind; self.name = name; self.detail = detail
        self.frame = frame; self.attributes = attributes
        self.previewBase64 = previewBase64
    }
}

/// Commands must be explicitly permitted by the connected Debug Agent.
/// The session is ephemeral, never a device identity.
public struct PTStudioDiagnosticCommand: Codable, Sendable, Equatable, Identifiable {
    public static let schemaVersion = 2
    public var schemaVersion: Int
    public var id: UUID
    public var sessionID: UUID
    public var domain: PTStudioDiagnosticDomain
    public var operation: String
    public var targetID: String?
    public var arguments: [String: String]

    public init(id: UUID = UUID(), sessionID: UUID,
                domain: PTStudioDiagnosticDomain, operation: String,
                targetID: String? = nil, arguments: [String: String] = [:]) {
        self.schemaVersion = Self.schemaVersion
        self.id = id; self.sessionID = sessionID
        self.domain = domain; self.operation = operation
        self.targetID = targetID; self.arguments = arguments
    }
}

public struct PTStudioDiagnosticReply: Codable, Sendable, Equatable {
    public var schemaVersion: Int
    public var id: UUID
    public var sessionID: UUID
    public var success: Bool
    public var message: String?
    public var entries: [PTStudioDiagnosticEntry]

    public init(id: UUID, sessionID: UUID, success: Bool,
                message: String? = nil, entries: [PTStudioDiagnosticEntry] = []) {
        self.schemaVersion = PTStudioDiagnosticCommand.schemaVersion
        self.id = id; self.sessionID = sessionID
        self.success = success; self.message = message; self.entries = entries
    }
}

public enum PTStudioDiagnosticCapability: String, Codable, Sendable {
    case unavailable, readOnly, allowedAfterConsent
}
