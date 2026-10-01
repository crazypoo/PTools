import Foundation
import PToolsModelLegacyKakaJSON
import KakaJSON

final class LegacyKakaModel: Convertible {
    var value = ""
    required init() {}
}

_ = try? PTLegacyKakaJSONAdapter.decode(LegacyKakaModel.self, data: Data(#"{"value":"ok"}"#.utf8))
