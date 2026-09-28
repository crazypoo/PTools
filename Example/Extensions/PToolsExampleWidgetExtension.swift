// English: Minimal WidgetKit host sample using the typed App Group store.
// Español: Ejemplo mínimo de WidgetKit que usa el almacenamiento tipado de App Group.
// 中文：使用类型化 App Group 存储的最小 WidgetKit 宿主示例。

#if canImport(WidgetKit) && canImport(SwiftUI)
import SwiftUI
import WidgetKit
import PToolsStorageCore
import PToolsWidgetCore

private struct PToolsExampleWidgetValue: Codable, Sendable {
    let title: String
}

private struct PToolsExampleWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: PTWidgetSnapshot<PToolsExampleWidgetValue>
}

private struct PToolsExampleWidgetProvider: TimelineProvider {
    private let key = PTStorageKey<PToolsExampleWidgetValue>("widget.value")

    func placeholder(in context: Context) -> PToolsExampleWidgetEntry {
        .init(date: .now, snapshot: .init(value: .init(title: "PTools")))
    }

    func getSnapshot(in context: Context, completion: @escaping (PToolsExampleWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PToolsExampleWidgetEntry>) -> Void) {
        Task {
            let value = (try? await PTWidgetSharedStore(appGroupIdentifier: "group.example.pootools")
                .read(key)) ?? .init(title: "PTools")
            let entry = PToolsExampleWidgetEntry(date: .now, snapshot: .init(value: value))
            completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(900))))
        }
    }
}

struct PToolsExampleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PToolsExampleWidget", provider: PToolsExampleWidgetProvider()) { entry in
            Text(entry.snapshot.value.title)
        }
        .configurationDisplayName("PTools")
        .description("Typed App Group state example")
    }
}
#endif
