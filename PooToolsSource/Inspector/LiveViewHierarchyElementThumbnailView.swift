//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class LiveViewHierarchyElementThumbnailView: ViewHierarchyElementThumbnailView {
    override var isHidden: Bool {
        didSet {
            if isHidden {
                stopLiveUpdatingSnapshot()
            }
            else {
                startLiveUpdatingSnapshot()
            }
        }
    }

    deinit {
        stopLiveUpdatingSnapshot()
    }

    private var displayLink: CADisplayLink? {
        didSet {
            if let oldLink = oldValue {
                oldLink.invalidate()
            }
            if let newLink = displayLink {
                newLink.preferredFramesPerSecond = 30
                newLink.add(to: .current, forMode: .default)
            }
        }
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if superview?.window == nil {
            stopLiveUpdatingSnapshot()
        }
        else {
            startLiveUpdatingSnapshot()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard let window = window else {
            hoverGestureRecognizer.isEnabled = false
            return
        }

        window.addGestureRecognizer(hoverGestureRecognizer)
        hoverGestureRecognizer.isEnabled = true

        hoverGestureRecognizer.isEnabled = ProcessInfo().isiOSAppOnMac == false

        startLiveUpdatingSnapshot()
    }

    @objc
    func startLiveUpdatingSnapshot() {
        debounce(#selector(makeDisplayLinkIfNeeded), after: .average)
    }

    @objc
    func makeDisplayLinkIfNeeded() {
        guard displayLink == nil else { return }
        displayLink = CADisplayLink(target: self, selector: #selector(refresh))
    }

    @objc
    func stopLiveUpdatingSnapshot() {
        Self.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(makeDisplayLinkIfNeeded),
            object: nil
        )

        displayLink = nil
    }

    @objc
    func refresh() {
        guard element.underlyingView?.isAssociatedToWindow == true else {
            return stopLiveUpdatingSnapshot()
        }

        if backgroundStyle.color != backgroundColor {
            backgroundColor = backgroundStyle.color
        }

        if !isHidden, superview?.isHidden == false {
            updateViews(afterScreenUpdates: false)
        }
    }

    private lazy var hoverGestureRecognizer = UIHoverGestureRecognizer(
        target: self,
        action: #selector(hovering(_:))
    )

    @objc
    func hovering(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            stopLiveUpdatingSnapshot()

        case .ended, .cancelled:
            startLiveUpdatingSnapshot()

        default:
            break
        }
    }
}
