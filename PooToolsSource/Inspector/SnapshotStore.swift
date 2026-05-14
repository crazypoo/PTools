//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

final class SnapshotStore<Snapshot>: NSObject {
    typealias Provider = Inspector.Provider<Void, Snapshot?>

    var delay: TimeInterval

    let first: Snapshot

    let maxCount: Int

    var latest: Snapshot { snapshots.last ?? first }

    private lazy var snapshots: [Snapshot] = [first]

    private var snapshotProvider: Provider? {
        didSet {
            debounce(#selector(makeSnapshot), after: delay)
        }
    }

    @MainActor
    init(
        _ initial: Snapshot,
        maxCount: Int? = nil,
        delay: TimeInterval? = nil
    ) {
        first = initial
        self.delay = delay ?? Inspector.sharedInstance.configuration.snapshotExpirationTimeInterval
        self.maxCount = maxCount ?? Inspector.sharedInstance.configuration.snapshotMaxCount
    }

    func scheduleSnapshot(_ provider: Provider) {
        snapshotProvider = provider
    }

    @objc private func makeSnapshot() {
        guard let newSnapshot = snapshotProvider?.value else { return }
        snapshots.append(newSnapshot)
        snapshots = Array(snapshots.suffix(maxCount))
    }
}
