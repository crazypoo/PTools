import Foundation
import CryptoKit
#if SWIFT_PACKAGE
import PToolsStudioProtocolCore
#endif

/// UIKit-free inspector snapshot identity. The Studio wire schema stays v2 and
/// only the value-based fingerprint algorithm is shared. Preview bytes are
/// intentionally excluded so enabling screenshots never changes hierarchy ID.
public enum PTDebugInspectorSnapshotSignature {
    public static func fingerprint(entries: [PTStudioDiagnosticEntry]) -> String? {
        let descriptors = entries.map { entry in
            PTStudioDiagnosticEntry(
                id: entry.id, parentID: entry.parentID,
                kind: entry.kind, name: entry.name, detail: entry.detail,
                frame: entry.frame, attributes: entry.attributes,
                previewBase64: nil)
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(descriptors) else { return nil }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
