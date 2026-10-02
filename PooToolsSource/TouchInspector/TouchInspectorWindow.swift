//
//  TouchInspectorWindow.swift
//
//  Copyright 2022 Janum Trivedi
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation
import UIKit

@MainActor
@objcMembers
public class TouchInspectorWindow: UIWindow {

    public var showTouches: Bool = PTDebugPreferences.shared.isTouchOverlayEnabled {
        didSet {
            PTDebugPreferences.shared.isTouchOverlayEnabled = showTouches
            hideOrUpdateOverlays()
        }
    }
    
    public var showHitTesting: Bool = PTDebugPreferences.shared.isHitTestingEnabled {
        didSet {
            PTDebugPreferences.shared.isHitTestingEnabled = showHitTesting
            hideOrUpdateOverlays()
        }
    }
    
    private var touchOverlays: [ObjectIdentifier: TouchOverlayView] = [:]
    
    public override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func sendEvent(_ event: UIEvent) {
        if event.type == .touches, showTouches || showHitTesting {
            handleTouchesEvent(event)
        }
        super.sendEvent(event)
    }
    
    private func handleTouchesEvent(_ event: UIEvent) {
        for touch in event.allTouches ?? [] {
            let touchID = ObjectIdentifier(touch)
            let touchLocationInWindow = touch.location(in: self)
            let touchPhase = touch.phase
            
            if touchPhase == .began {
                createTouchOverlay(for: touchID)
            }
            
            updateTouchOverlay(for: touchID, location: touchLocationInWindow, hitTestedView: hitTest(touchLocationInWindow, with: event))
            
            if touchPhase == .ended || touchPhase == .cancelled {
                removeTouchOverlay(for: touchID)
            }
        }
    }
    
    private func createTouchOverlay(for touchID: ObjectIdentifier) {
        let overlay = TouchOverlayView()
        touchOverlays[touchID] = overlay
        addSubview(overlay)
        overlay.present()
    }

    private func updateTouchOverlay(for touchID: ObjectIdentifier, location: CGPoint, hitTestedView: UIView?) {
        guard let overlay = touchOverlays[touchID] else { return }
        
        overlay.hitTestingOverlay.text = hitTestOverlayDescription(for: location, hitTestedView: hitTestedView)
        overlay.hitTestingOverlay.isHidden = !showHitTesting
        overlay.frame.origin = location
        bringSubviewToFront(overlay)
    }
        
    private func removeTouchOverlay(for touchID: ObjectIdentifier) {
        guard let overlay = touchOverlays[touchID] else { return }
        overlay.hide {
            PTGCDManager.shared.runOnMain {
                overlay.removeFromSuperview()
                self.touchOverlays.removeValue(forKey: touchID)
            }
        }
    }
    
    private func hitTestOverlayDescription(for locationInWindow: CGPoint, hitTestedView: UIView?) -> String {
        let locationInWindowDescription = locationInWindow.shortDescription
        let locationInHitTestedView = self.convert(locationInWindow, to: hitTestedView)
        let locationInHitTestedViewDescription = locationInHitTestedView.shortDescription
        
        return """
        Touch:   \(locationInWindowDescription)
        In View: \(locationInHitTestedViewDescription)
        Hit-Test: \(hitTestedView?.description ?? "nil")
        """
    }
    
    private func hideOrUpdateOverlays() {
        if !showTouches && !showHitTesting {
            touchOverlays.values.forEach { $0.removeFromSuperview() }
            touchOverlays.removeAll()
        } else {
            touchOverlays.values.forEach { $0.hitTestingOverlay.isHidden = !showHitTesting }
        }
    }
}
