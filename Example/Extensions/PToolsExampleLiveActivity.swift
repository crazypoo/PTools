// English: Minimal Live Activity host sample; redact business data before publishing.
// Español: Ejemplo mínimo de Live Activity; redacta los datos de negocio antes de publicarlos.
// 中文：最小 Live Activity 宿主示例，发布前必须脱敏业务数据。

#if canImport(ActivityKit) && canImport(WidgetKit) && canImport(SwiftUI)
import ActivityKit
import SwiftUI
import WidgetKit

struct PToolsExampleActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String
    }

    var displayName: String
}

struct PToolsExampleLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PToolsExampleActivityAttributes.self) { context in
            Text(context.state.status)
                .activityBackgroundTint(.clear)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.status)
                }
            } compactLeading: {
                Image(systemName: "bolt")
            } compactTrailing: {
                Text("Live")
            } minimal: {
                Image(systemName: "bolt")
            }
        }
    }
}
#endif
