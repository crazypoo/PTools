//
//  Publisher+VideoEditorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import Combine
import AVKit

public extension Publishers {
    /// Custom `Publisher` implementation that wraps `AVPlayer.addPeriodicTimeObserver(forInterval:queue:using)` to emit values corresponding to the playhead's progress
    struct PlayheadProgressPublisher: Publisher {
        public typealias Output = CMTime
        public typealias Failure = Never

        private let interval: TimeInterval
        private let player: AVPlayer

        /// Initializes `PlayheadProgressPublisher`tracking the playhead's progress of a given `AVPlayer` instance at a given interval.
        /// - Parameters:
        ///   - interval: The interval at which the underlying playhead observer executes an update
        ///   - player: `AVPlayer` whose playhead values are emited by the `Publisher`
        init(interval: TimeInterval = 0.25, 
             player: AVPlayer) {
            self.player = player
            self.interval = interval
        }

        public func receive<S>(subscriber: S) where S : Subscriber,
                                                    Self.Failure == S.Failure,
                                                    Self.Output == S.Input {
            let subscription = PlayheadProgressSubscription(subscriber: subscriber,
                                                            interval: interval,
                                                            player: player)
            subscriber.receive(subscription: subscription)
        }
    }

    private final class PlayheadProgressSubscription<S: Subscriber>: Subscription where S.Input == CMTime {
        private var subscriber: S?
        private var requested: Subscribers.Demand = .none
        private var timeObserverToken: Any? = nil

        private let interval: TimeInterval
        private let player: AVPlayer

        private let lock = NSRecursiveLock()

        init(subscriber: S,
             interval: TimeInterval = 0.02,
             player: AVPlayer) {
            self.player = player
            self.subscriber = subscriber
            self.interval = interval
        }

        func request(_ demand: Subscribers.Demand) {
            withLock {
                processDemand(demand)
            }
        }

        private func processDemand(_ demand: Subscribers.Demand) {
            requested += demand
            guard timeObserverToken == nil, requested > .none else { return }

            let interval = CMTime(seconds: interval, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] time in
                self?.sendValue(time)
            }
        }

        private func sendValue(_ time: CMTime) {
            withLock {
                guard let subscriber = subscriber, requested > .none else { return }
                requested -= .max(1)
                let newDemand = subscriber.receive(time)
                requested += newDemand
            }
        }

        func cancel() {
            withLock {
                if let timeObserverToken = timeObserverToken {
                    player.removeTimeObserver(timeObserverToken)
                }
                timeObserverToken = nil
                subscriber = nil
            }
        }

        private func withLock(_ operation: () -> Void) {
            lock.lock()
            defer { lock.unlock() }
            operation()
        }
    }
}

//MARK: WeaklyAssign
extension Publisher where Self.Failure == Never {
    func assign<Root: AnyObject>(to keyPath: WritableKeyPath<Root, Self.Output>,
                                 weakly object: Root) -> AnyCancellable {
        sink { [weak object] (output) in
            object?[keyPath: keyPath] = output
        }
    }
}

