// English: Minimal AppIntents extension sample; the host owns entitlements and route policy.
// Español: Ejemplo mínimo de AppIntents; el host posee los entitlements y la política de rutas.
// 中文：最小 AppIntents 扩展示例，entitlement 和路由策略由宿主持有。

#if canImport(AppIntents)
import AppIntents
import PToolsAppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct PToolsExampleIntentsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        [AppShortcut(intent: PTOpenRouteIntent(routeID: "home"),
                     phrases: ["Open \(.applicationName) home"],
                     shortTitle: "Open home",
                     systemImageName: "house")]
    }
}
#endif
