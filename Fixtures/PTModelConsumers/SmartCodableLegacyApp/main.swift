import Foundation
import PToolsModelLegacySmartCodable
import SmartCodable

struct LegacySmartModel: SmartCodable {
    let value: String
    init() { value = "" }
}

_ = try? PTLegacySmartCodableAdapter.decode(LegacySmartModel.self, data: Data(#"{"value":"ok"}"#.utf8))
