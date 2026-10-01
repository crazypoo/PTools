import Foundation
import PToolsModel

struct PTModelConsumer: Codable, Sendable {
    let value: String
}

_ = try? PTModelDecoder().decode(PTModelConsumer.self, from: Data(#"{"value":"ok"}"#.utf8))
