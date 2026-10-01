# PTModel Consumer Fixtures

These six small consumer manifests are the R3 compatibility boundary. They are intentionally outside `PooToolsSource` so the dependency audit can prove that third-party codecs appear only in opt-in consumers.

| Fixture | Contract |
| --- | --- |
| `SmartCodableLegacyApp` | Legacy SmartCodable adapter only |
| `KakaJSONLegacyApp` | Legacy KakaJSON adapter only |
| `MixedLegacyApp` | Both legacy adapters in one consumer |
| `PTModelOnlyApp` | Foundation-only PTModel path |
| `SwiftPMConsumer` | SwiftPM product wiring |
| `CocoaPodsConsumer` | CocoaPods subspec wiring |

R4 runtime, differential, device and TSan checks remain outside these compile-shape fixtures.
