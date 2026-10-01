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

`pod install --no-repo-update` and the real `PooTools.xcworkspace` host are the
host-level checks. The complete reproducible gate is:

```sh
bash Scripts/PTModel/validate_f1_f3.sh
```

It verifies this consumer contract, PooTools-Example Swift 6 / iOS 17 settings,
Appz Swift 5 compatibility, Debug/Release Simulator builds, installation and
launch. `ModelLegacySmartCodable` and `ModelLegacyKakaJSON` remain explicit
opt-in subspecs and are not part of this consumer.
