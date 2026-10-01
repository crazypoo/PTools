# CocoaPods Consumer

This is the smallest iOS 17 consumer contract for the Foundation-only model
boundary. It deliberately selects `PooTools/Model` and does not pull either
legacy codec.

```ruby
platform :ios, '17.0'

target 'PTModelCocoaPodsConsumer' do
  pod 'PooTools/Model', :path => '../../../'
end
```

Consumer source:

```swift
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
```

`pod install --no-repo-update` and an iOS Simulator build are the host-level
checks. `ModelLegacySmartCodable` and `ModelLegacyKakaJSON` remain explicit
opt-in subspecs and are not part of this consumer.
