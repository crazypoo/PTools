#if os(iOS) && DEBUG
import SwiftUI

/// Ready-to-present first-pairing UI for an authorized developer's Debug app.
/// Credentials are written only to Keychain; Bonjour never carries a secret.
/// Release builds do not compile this view.
@MainActor
public struct PTStudioPairingView: View {
    @AppStorage("PTStudio.autoConnectEnabled") private var autoConnect = false
    @State private var peers: [PTStudioDiscoveredPeer] = []
    @State private var selectedPeerID: String?
    @State private var token = ""
    @State private var fingerprint = ""
    @State private var notice: String?
    @State private var bridgeStatus: PTStudioBridgeStatus?
    @State private var discoveryError: String?

    public init() {}

    public var body: some View {
        Form {
            Section("Secure Studio discovery") {
                Toggle("Automatically reconnect to paired Studio", isOn: Binding(
                    get: { autoConnect },
                    set: { setEnabled($0) }
                ))
                Text("Discovery stays off until you opt in. Only a previously approved Mac can start the Debug Bridge.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Macs discovered on this Wi-Fi") {
                HStack {
                    Text("Bonjour service: _ptstudio._tcp")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Refresh") { refresh() }
                        .disabled(!autoConnect)
                }
                if peers.isEmpty {
                    Text(autoConnect ? "No PTNetworkStudio bridge discovered." : "Enable discovery to find your Mac.")
                        .foregroundStyle(.secondary)
                }
                ForEach(peers) { peer in
                    Button {
                        selectedPeerID = peer.id
                        notice = nil
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(peer.name)
                                Text("\(peer.tlsHost):\(peer.port)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                Text(connectionLabel(for: peer))
                                    .font(.caption)
                                    .foregroundStyle(connectionColor(for: peer))
                                if PTStudioAutoConnectionManager.shared.currentPeer?.id == peer.id,
                                   let bridgeStatus,
                                   bridgeStatus.consecutiveSendFailures > 0 {
                                    Text("Retries: \(bridgeStatus.consecutiveSendFailures)")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                            Spacer()
                            if selectedPeerID == peer.id {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                    }
                }
            }

            if let selectedPeerID,
               let peer = peers.first(where: { $0.id == selectedPeerID }) {
                Section("Approve pairing with \(peer.name)") {
                    Text("First install and explicitly trust the Studio Development CA. Confirm the pairing token and 64-character leaf SHA-256 in the Mac's iPhone Bridge screen.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SecureField("Pairing token", text: $token)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                    TextField("Leaf certificate SHA-256 (64 hex characters)", text: $fingerprint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Approve and save to Keychain") { approve(peer) }
                        .disabled(token.utf8.count < 24 || fingerprint.trimmingCharacters(
                            in: .whitespacesAndNewlines).count != 64)
                    if PTStudioPairingKeychain.load(account: peer.id) != nil {
                        Button("Revoke this pairing", role: .destructive) {
                            PTStudioAutoConnectionManager.shared.revokePairing(peerID: peer.id)
                            notice = "Pairing revoked."
                        }
                    }
                }
            }

            Section("Secure delivery") {
                if let peer = PTStudioAutoConnectionManager.shared.currentPeer {
                    Text("Selected Mac: \(peer.name)")
                    Text("TLS / ACK: \(deliveryLabel)")
                    if let bridgeStatus {
                        if let ack = bridgeStatus.lastAcknowledgedSequence {
                            Text("Last ACK sequence: \(ack)")
                        }
                        if let lastError = bridgeStatus.lastSendError {
                            Text(lastError).foregroundStyle(.orange)
                                .textSelection(.enabled)
                        }
                    }
                } else {
                    Text("No active Bridge transport. A saved pairing is not a connection.")
                        .foregroundStyle(.secondary)
                }
                Text("The Mac must show an authenticated session; the Bridge needs a valid TLS certificate and a matching Token.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let discoveryError {
                Section("Discovery error") {
                    Text(discoveryError).foregroundStyle(.orange).textSelection(.enabled)
                }
            }
            if let notice {
                Section { Text(notice).font(.footnote).textSelection(.enabled) }
            }
        }
        .navigationTitle("PTNetworkStudio pairing")
        .onAppear {
            let manager = PTStudioAutoConnectionManager.shared
            peers = manager.discovery.peers
            manager.onPeersChanged = { updated in
                peers = updated
            }
            manager.onError = { message in discoveryError = message }
            if autoConnect {
                do { try manager.start() }
                catch { notice = error.localizedDescription }
            }
        }
        .onDisappear {
            PTStudioAutoConnectionManager.shared.onPeersChanged = nil
            PTStudioAutoConnectionManager.shared.onError = nil
            token = ""
            fingerprint = ""
        }
        .task {
            while !Task.isCancelled {
                bridgeStatus = await PTStudioBridge.shared.status()
                do { try await Task.sleep(for: .seconds(1)) }
                catch { break }
            }
        }
    }

    private var deliveryLabel: String {
        switch bridgeStatus?.deliveryState {
        case .connected: return "Connected — authenticated ACK received"
        case .retrying: return "Retrying — inspect the error below"
        case .awaitingAcknowledgement: return "Connecting — awaiting ACK"
        case .stopped, .none: return "Not connected"
        }
    }

    private func connectionLabel(for peer: PTStudioDiscoveredPeer) -> String {
        guard PTStudioPairingKeychain.load(account: peer.id) != nil else {
            return "Not paired"
        }
        guard PTStudioAutoConnectionManager.shared.currentPeer?.id == peer.id else {
            return "Paired — offline"
        }
        return deliveryLabel
    }

    private func connectionColor(for peer: PTStudioDiscoveredPeer) -> Color {
        guard PTStudioPairingKeychain.load(account: peer.id) != nil else {
            return .secondary
        }
        guard PTStudioAutoConnectionManager.shared.currentPeer?.id == peer.id else {
            return .orange
        }
        switch bridgeStatus?.deliveryState {
        case .connected: return .green
        case .retrying: return .red
        default: return .orange
        }
    }

    private func refresh() {
        do {
            try PTStudioAutoConnectionManager.shared.refresh()
            discoveryError = nil
        } catch {
            discoveryError = error.localizedDescription
        }
    }

    private func setEnabled(_ enabled: Bool) {
        let manager = PTStudioAutoConnectionManager.shared
        if enabled {
            do {
                try manager.start()
                autoConnect = true
                peers = manager.discovery.peers
                notice = nil
            } catch {
                autoConnect = false
                notice = error.localizedDescription
            }
        } else {
            autoConnect = false
            manager.stop()
            peers = []
            notice = nil
        }
    }

    private func approve(_ peer: PTStudioDiscoveredPeer) {
        do {
            try PTStudioAutoConnectionManager.shared.approvePairing(
                peerID: peer.id, token: token, fingerprintHex: fingerprint)
            token = ""
            fingerprint = ""
            notice = "Credentials saved to Keychain. Waiting for the Mac's authenticated HTTPS ACK. Saved pairing alone is not connected."
        } catch {
            notice = error.localizedDescription
        }
    }
}
#endif
