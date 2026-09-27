// English: Render opt-in platform diagnostics without exposing mutable service state.
// Español: Muestra diagnósticos de plataforma opcionales sin exponer estado mutable de los servicios.
// 中文：提供可选的平台诊断界面，但不暴露服务的可变状态。

import UIKit
#if SWIFT_PACKAGE
import PToolsBackgroundTasks
import PToolsConnectivity
import PToolsNotifications
#endif

@MainActor
public final class PTPlatformDiagnosticsViewController: UIViewController, UITableViewDataSource {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var rows: [String] = []
    private var refreshTask: Task<Void, Never>?

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Platform Diagnostics"
        view.backgroundColor = .systemBackground
        tableView.dataSource = self
        tableView.alwaysBounceVertical = true
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
        refresh()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refresh()
    }

    deinit {
        refreshTask?.cancel()
    }

    public func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PTPlatformDiagnosticCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "PTPlatformDiagnosticCell")
        cell.textLabel?.text = rows[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = nil
        return cell
    }

    private func refresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            let connectivity = await PTConnectivityMonitor.shared.current()
            let connectivityDiagnostics = await PTConnectivityMonitor.shared.diagnostics()
            let background = PTBackgroundTasks.shared.diagnosticsSnapshot()
            let notificationStatus = await PTNotificationCenter.shared.authorizationStatus()
            let values = [
                "Connectivity: \(connectivity.status.rawValue)",
                "Interfaces: \(connectivity.interfaces.map(\.rawValue).sorted().joined(separator: ", "))",
                "Expensive: \(connectivity.isExpensive), Constrained: \(connectivity.isConstrained)",
                "Connectivity transitions: \(connectivityDiagnostics.transitionCount)",
                "Background registrations: \(background.count)",
                "Notifications authorization: \(notificationStatus.rawValue)",
                "Storage: typed actor backends available",
                "Routing: use PooToolsRouter registered route handlers"
            ]
            guard !Task.isCancelled else { return }
            self?.rows = values
            self?.tableView.reloadData()
        }
    }
}
