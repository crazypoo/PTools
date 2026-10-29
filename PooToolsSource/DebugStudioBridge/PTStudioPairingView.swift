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
                                Text(PTStudioPairingKeychain.load(account: peer.id) == nil
                                     ? "Not paired" : "Paired on this device")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
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
            if autoConnect {
                do { try manager.start() }
                catch { notice = error.localizedDescription }
            }
        }
        .onDisappear {
            PTStudioAutoConnectionManager.shared.onPeersChanged = nil
            token = ""
            fingerprint = ""
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
            notice = "Pairing stored in Keychain. The secure connection starts automatically; verify ACK status before considering it connected."
        } catch {
            notice = error.localizedDescription
        }
    }
}
#endif
