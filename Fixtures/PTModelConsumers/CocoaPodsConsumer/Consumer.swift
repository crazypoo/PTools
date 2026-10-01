import Foundation
import PooTools

struct ConsumerModel: Codable, Sendable {
    let value: String
}

let model = try PTModelDecoder().decode(
    ConsumerModel.self,
    from: Data(#"{"value":"ok"}"#.utf8)
)
precondition(model.value == "ok")
