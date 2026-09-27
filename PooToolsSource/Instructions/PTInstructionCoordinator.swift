// English: The coordinator owns the instruction state machine and reuses OverlayCore for presentation.
// Español: El coordinador posee la máquina de estados y reutiliza OverlayCore para presentar.
// 中文：协调器负责引导状态机，并复用 OverlayCore 完成展示。

import UIKit
#if SWIFT_PACKAGE
import PToolsOverlay
#endif

@MainActor
public final class PTInstructionCoordinator: NSObject {
    public private(set) var state: PTInstructionState = .idle
    public private(set) var currentStepID: PTInstructionID?

    private enum Command {
        case next
        case previous
        case skip
        case skipStep
        case jump(PTInstructionID)
        case cancel
    }

    private let configuration: PTInstructionConfiguration
    private let store: PTInstructionStore
    private weak var presenter: UIViewController?
    private var host: PTOverlayHost?
    private var lifecycle: PTOverlayLifecycle?
    private var maskView: PTInstructionMaskView?
    private var cardView: PTInstructionCardView?
    private weak var childViewController: UIViewController?
    private var targetGestures: [UITapGestureRecognizer] = []
    private var controlActions: [(UIControl, UIAction, UIControl.Event)] = []
    private var overlayTapGesture: UITapGestureRecognizer?
    private var commandContinuation: CheckedContinuation<Command, Never>?
    private var currentStepContext: PTInstructionStepContext?
    private var currentResolved: [PTAnchorResolver.Resolved] = []
    private var displayLink: CADisplayLink?
    private var tourID: PTInstructionID?
    private var lastTargetFrames: [CGRect] = []

    init(configuration: PTInstructionConfiguration,
         store: PTInstructionStore) {
        self.configuration = configuration
        self.store = store
        super.init()
    }

    public func present(_ tour: PTInstructionTour,
                        in viewController: UIViewController) async throws -> PTInstructionResult {
        guard state == .idle else { throw PTInstructionFailure.alreadyRunning }
        guard !tour.steps.isEmpty else { throw PTInstructionFailure.emptyTour }

        var ids = Set<PTInstructionID>()
        for step in tour.steps where !ids.insert(step.id).inserted {
            throw PTInstructionFailure.duplicateStepID(step.id)
        }

        if await shouldSkip(tour) {
            return .skipped
        }

        guard let host = PTOverlayHost(context: .viewController(viewController),
                                       mode: .attached,
                                       layer: .tips),
              let window = host.window else {
            throw PTInstructionFailure.hostUnavailable
        }

        presenter = viewController
        self.host = host
        tourID = tour.id
        activeTour = tour
        lifecycle = window.windowScene.map { scene in
            PTOverlayLifecycle(scene: scene) { [weak self] event in
                self?.handle(event)
            }
        }

        state = .presenting
        await store.save(.init(tourID: tour.id,
                               version: tour.version,
                               lastStepID: nil,
                               status: .started))

        defer {
            cleanup()
            state = .finished
            currentStepID = nil
        }

        var index = await resumeIndex(for: tour)
        while index < tour.steps.count {
            if Task.isCancelled { return .cancelled }
            let step = tour.steps[index]
            if let condition = step.condition, !(await condition()) {
                index += 1
                continue
            }

            state = .resolvingTarget
            do {
                currentResolved = try await resolve(step: step, window: window)
            } catch let error as PTInstructionFailure {
                switch (error, step.targetWaitPolicy) {
                case (.targetUnavailable, .skip), (.targetTimeout, .skip):
                    index += 1
                    continue
                default:
                    throw error
                }
            }

            let frames = targetFrames(for: currentResolved, in: host.containerView)
            let context = PTInstructionStepContext(tourID: tour.id,
                                                   stepID: step.id,
                                                   targetFrame: frames.first,
                                                   coordinator: self)
            currentStepContext = context
            currentStepID = step.id
            if let beforePresent = step.beforePresent {
                try await beforePresent(context)
            }

            state = .presenting
            try render(step: step, targetFrames: frames, in: host.containerView)
            state = .visible
            startTracking(step: step, host: host)
            await store.save(.init(tourID: tour.id,
                                   version: tour.version,
                                   lastStepID: step.id,
                                   status: .started))
            let command = await waitForCommand()
            stopTracking()

            switch command {
            case .next:
                index += 1
            case .previous:
                index = max(0, index - 1)
            case .skip:
                await store.save(.init(tourID: tour.id,
                                       version: tour.version,
                                       lastStepID: step.id,
                                       status: .skipped))
                return .skipped
            case .skipStep:
                guard step.isSkippable else { continue }
                index += 1
            case let .jump(id):
                guard let destination = tour.steps.firstIndex(where: { $0.id == id }) else {
                    continue
                }
                index = destination
            case .cancel:
                return .cancelled
            }

            if let afterDismiss = step.afterDismiss {
                try await afterDismiss(context)
            }
            await store.save(.init(tourID: tour.id,
                                   version: tour.version,
                                   lastStepID: step.id,
                                   status: index >= tour.steps.count ? .completed : .started))
            hideCurrentViews()
        }

        return .completed
    }

    public func next() async {
        resumeCommand(.next)
    }

    public func previous() async {
        resumeCommand(.previous)
    }

    public func skip() async {
        resumeCommand(.skip)
    }

    public func skipStep() async {
        resumeCommand(.skipStep)
    }

    public func jump(to id: PTInstructionID) async {
        resumeCommand(.jump(id))
    }

    public func pause() async {
        guard state == .visible else { return }
        state = .paused
        displayLink?.isPaused = true
    }

    public func resume() async {
        guard state == .paused else { return }
        state = .visible
        displayLink?.isPaused = false
    }

    public func cancel() async {
        resumeCommand(.cancel)
    }

    private func shouldSkip(_ tour: PTInstructionTour) async -> Bool {
        guard tour.presentationPolicy != .always,
              let snapshot = await store.snapshot(for: tour) else { return false }
        switch tour.presentationPolicy {
        case .always:
            return false
        case .once:
            return snapshot.status == .completed
        case .oncePerVersion:
            return snapshot.status == .completed && snapshot.version == tour.version
        }
    }

    private func resumeIndex(for tour: PTInstructionTour) async -> Int {
        guard let snapshot = await store.snapshot(for: tour),
              snapshot.status == .started,
              let lastStepID = snapshot.lastStepID,
              let index = tour.steps.firstIndex(where: { $0.id == lastStepID }) else {
            return 0
        }
        return index
    }

    private func resolve(step: PTInstructionStep,
                         window: UIWindow) async throws -> [PTAnchorResolver.Resolved] {
        let anchors = step.target.anchors
        guard !anchors.isEmpty else { return [] }

        let timeout: Date?
        switch step.targetWaitPolicy {
        case .fail, .skip:
            timeout = nil
        case let .wait(seconds):
            timeout = Date().addingTimeInterval(max(0, seconds))
        }

        while true {
            let resolved = anchors.compactMap { anchor -> PTAnchorResolver.Resolved? in
                guard case let .success(value) = PTAnchorResolver.resolve(anchor, context: .window(window)) else {
                    return nil
                }
                return value
            }
            if resolved.count == anchors.count {
                if step.targetRevealPolicy == .scrollIfNeeded {
                    reveal(resolved)
                    await Task.yield()
                }
                return resolved
            }

            switch step.targetWaitPolicy {
            case .fail:
                throw PTInstructionFailure.targetUnavailable(step.id)
            case .skip:
                throw PTInstructionFailure.targetUnavailable(step.id)
            case .wait:
                guard let timeout, Date() < timeout else {
                    throw PTInstructionFailure.targetTimeout(step.id)
                }
                do {
                    try await Task.sleep(for: .milliseconds(40))
                } catch {
                    throw CancellationError()
                }
            }
        }
    }

    private func reveal(_ resolved: [PTAnchorResolver.Resolved]) {
        for item in resolved {
            var view = item.view
            while let current = view {
                if let scrollView = current as? UIScrollView {
                    let rect = item.rect == .zero ? current.bounds : current.convert(current.bounds, to: scrollView)
                    scrollView.scrollRectToVisible(rect, animated: false)
                    break
                }
                view = current.superview
            }
        }
    }

    private func render(step: PTInstructionStep,
                        targetFrames: [CGRect],
                        in container: PTOverlayContainerView) throws {
        hideCurrentViews()
        container.accessibilityIdentifier = "pt.instructions.overlay"
        let mask = PTInstructionMaskView(frame: container.bounds)
        mask.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mask.update(rects: targetFrames,
                    spotlight: step.spotlight,
                    animated: false)
        container.addSubview(mask)
        maskView = mask

        let card = PTInstructionCardView()
        card.onNext = allowsNext(for: step) ? { [weak self] in self?.resumeCommand(.next) } : nil
        card.onPrevious = allowsPrevious(for: step) ? { [weak self] in self?.resumeCommand(.previous) } : nil
        card.onSkip = step.isSkippable ? { [weak self] in self?.resumeCommand(.skip) } : nil
        card.apply(configuration: configuration)

        switch step.content {
        case let .message(message):
            card.configure(message: message, configuration: configuration)
        case let .view(makeView):
            card.configure(customView: makeView())
        case let .viewController(makeViewController):
            let viewController = makeViewController()
            presenter?.addChild(viewController)
            viewController.didMove(toParent: presenter)
            childViewController = viewController
            card.configure(customView: viewController.view)
        }

        container.addSubview(card)
        cardView = card
        container.interactiveContentViews = [card]
        container.hitTestPolicy = .custom
        container.customHitTest = { [weak card, weak mask, weak container] point, event in
            guard let container else { return nil }
            if let card, card.bounds.contains(card.convert(point, from: container)) {
                return card.hitTest(card.convert(point, from: container), with: event)
            }
            guard let mask else { return container }
            switch step.touchForwarding {
            case .all:
                return nil
            case .target, .cutout:
                return mask.containsCutout(point) ? nil : container
            case .none:
                return container
            }
        }

        installAdvanceHandlers(for: step, resolved: currentResolved, in: container)
        updateLayout(step: step, targetFrames: targetFrames, container: container)
        if configuration.idleAnimation == .pulse, !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 1.1,
                           delay: 0,
                           options: [.autoreverse, .repeat, .allowUserInteraction]) {
                card.transform = CGAffineTransform(scaleX: 1.015, y: 1.015)
            }
        }
        PTOverlayAnimator().present(view: card, transition: configuration.transition)
    }

    private func updateLayout(step: PTInstructionStep,
                              targetFrames: [CGRect],
                              container: PTOverlayContainerView) {
        guard let card = cardView, let window = host?.window else { return }
        let available = PTScreenCollisionResolver.availableBounds(for: window,
                                                                  edgeInsets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        let width = min(configuration.maximumContentWidth, max(220, available.width))
        card.bounds = CGRect(origin: .zero, size: CGSize(width: width, height: 1))
        card.layoutIfNeeded()
        let size = card.systemLayoutSizeFitting(CGSize(width: width, height: .greatestFiniteMagnitude),
                                                withHorizontalFittingPriority: .required,
                                                verticalFittingPriority: .fittingSizeLevel)
        let anchorRect = targetFrames.first ?? CGRect(x: available.midX, y: available.midY, width: 1, height: 1)
        let arrow = PTArrowAppearance(fillColor: configuration.cardColor)
        let geometry = PTPopoverPositioningEngine.resolve(anchorRect: anchorRect,
                                                          contentSize: CGSize(width: width, height: max(44, size.height)),
                                                          availableBounds: available,
                                                          preferredPlacement: step.placement,
                                                          arrow: arrow)
        card.frame = geometry.frame
        card.updateArrow(placement: geometry.placement,
                         point: geometry.arrowPoint,
                         appearance: arrow)
    }

    private func installAdvanceHandlers(for step: PTInstructionStep,
                                        resolved: [PTAnchorResolver.Resolved],
                                        in container: PTOverlayContainerView) {
        removeAdvanceHandlers()
        if allowsOverlayTap(for: step) {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(overlayTapped(_:)))
            gesture.cancelsTouchesInView = false
            container.addGestureRecognizer(gesture)
            overlayTapGesture = gesture
        }

        guard allowsTargetTap(for: step) else { return }
        for item in resolved {
            guard let view = item.view else { continue }
            if let control = view as? UIControl {
                let action = UIAction { [weak self] _ in self?.resumeCommand(.next) }
                let event = UIControl.Event(rawValue: controlEvent(for: step) ?? UIControl.Event.primaryActionTriggered.rawValue)
                control.addAction(action, for: event)
                controlActions.append((control, action, event))
            } else {
                let gesture = UITapGestureRecognizer(target: self, action: #selector(targetTapped))
                view.addGestureRecognizer(gesture)
                view.isUserInteractionEnabled = true
                targetGestures.append(gesture)
            }
        }
    }

    private func allowsNext(for step: PTInstructionStep) -> Bool {
        switch step.advancePolicy {
        case .nextButton, .any: return true
        case .overlayTap, .targetTap, .controlEvent, .manual: return false
        }
    }

    private func allowsPrevious(for step: PTInstructionStep) -> Bool {
        switch step.advancePolicy {
        case .nextButton, .any:
            return true
        default:
            return false
        }
    }

    private func allowsOverlayTap(for step: PTInstructionStep) -> Bool {
        switch step.advancePolicy {
        case .overlayTap, .any:
            return true
        default:
            return false
        }
    }

    private func allowsTargetTap(for step: PTInstructionStep) -> Bool {
        switch step.advancePolicy {
        case .targetTap, .any, .controlEvent:
            return true
        default:
            return false
        }
    }

    private func controlEvent(for step: PTInstructionStep) -> UInt? {
        if case let .controlEvent(event) = step.advancePolicy { return event }
        return nil
    }

    private func waitForCommand() async -> Command {
        await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { continuation in
                commandContinuation = continuation
            }
        }, onCancel: {
            Task { @MainActor [weak self] in
                self?.resumeCommand(.cancel)
            }
        })
    }

    private func resumeCommand(_ command: Command) {
        guard let continuation = commandContinuation else { return }
        commandContinuation = nil
        continuation.resume(returning: command)
    }

    @objc private func overlayTapped(_ gesture: UITapGestureRecognizer) {
        guard let container = host?.containerView,
              let mask = maskView,
              let card = cardView else { return }
        let point = gesture.location(in: container)
        guard !card.frame.contains(point), !mask.containsCutout(point) else { return }
        resumeCommand(.next)
    }

    @objc private func targetTapped() {
        resumeCommand(.next)
    }

    private func startTracking(step: PTInstructionStep, host: PTOverlayHost) {
        guard !step.target.anchors.isEmpty else { return }
        let link = CADisplayLink(target: self, selector: #selector(trackTarget))
        link.add(to: .main, forMode: .common)
        displayLink = link
        lastTargetFrames = targetFrames(for: currentResolved, in: host.containerView)
    }

    @objc private func trackTarget() {
        guard state == .visible,
              let stepID = currentStepID,
              let step = currentStep(for: stepID),
              let container = host?.containerView,
              let window = host?.window else { return }
        let resolved = step.target.anchors.compactMap { anchor -> PTAnchorResolver.Resolved? in
            guard case let .success(value) = PTAnchorResolver.resolve(anchor, context: .window(window)) else { return nil }
            return value
        }
        guard resolved.count == step.target.anchors.count else { return }
        let frames = targetFrames(for: resolved, in: container)
        guard frames != lastTargetFrames else { return }
        currentResolved = resolved
        lastTargetFrames = frames
        maskView?.update(rects: frames, spotlight: step.spotlight, animated: true)
        updateLayout(step: step, targetFrames: frames, container: container)
    }

    private func currentStep(for id: PTInstructionID) -> PTInstructionStep? {
        // The coordinator only needs the active step during display-link tracking.
        // El coordinador solo necesita el paso activo durante el seguimiento del display link.
        // 协调器只在 DisplayLink 跟踪时需要当前步骤。
        return activeTour?.steps.first(where: { $0.id == id })
    }

    private var activeTour: PTInstructionTour?

    private func targetFrames(for resolved: [PTAnchorResolver.Resolved],
                              in container: PTOverlayContainerView) -> [CGRect] {
        resolved.map { item in
            guard let window = host?.window else { return item.rect }
            return window.convert(item.rect, to: container)
        }
    }

    private func stopTracking() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func removeAdvanceHandlers() {
        if let gesture = overlayTapGesture {
            host?.containerView.removeGestureRecognizer(gesture)
        }
        overlayTapGesture = nil
        targetGestures.forEach { gesture in
            gesture.view?.removeGestureRecognizer(gesture)
        }
        targetGestures.removeAll()
        controlActions.forEach { control, action, event in
            control.removeAction(action, for: event)
        }
        controlActions.removeAll()
    }

    private func hideCurrentViews() {
        removeAdvanceHandlers()
        childViewController?.willMove(toParent: nil)
        childViewController?.view.removeFromSuperview()
        childViewController?.removeFromParent()
        childViewController = nil
        cardView?.layer.removeAllAnimations()
        cardView?.removeFromSuperview()
        maskView?.removeFromSuperview()
        cardView = nil
        maskView = nil
    }

    private func cleanup() {
        stopTracking()
        hideCurrentViews()
        host?.containerView.customHitTest = nil
        host?.containerView.interactiveContentViews = []
        host?.containerView.accessibilityIdentifier = nil
        host?.detach()
        host = nil
        lifecycle = nil
        presenter = nil
        currentResolved = []
        currentStepContext = nil
        activeTour = nil
        tourID = nil
    }

    private func handle(_ event: PTOverlayLifecycleEvent) {
        switch event {
        case .didEnterBackground:
            guard state == .visible else { return }
            state = .paused
            displayLink?.isPaused = true
            host?.detach()
        case .didBecomeActive:
            guard state == .paused else { return }
            host?.attach()
            displayLink?.isPaused = false
            state = .visible
            if let stepID = currentStepID,
               let step = currentStep(for: stepID),
               let container = host?.containerView {
                updateLayout(step: step,
                             targetFrames: targetFrames(for: currentResolved, in: container),
                             container: container)
            }
        case .didDisconnect:
            if configuration.dismissOnSceneDisconnect {
                resumeCommand(.cancel)
            }
        }
    }
}

@MainActor
public final class PTInstructionSessionRegistry {
    public static let shared = PTInstructionSessionRegistry()

    private var sessions: [String: PTInstructionCoordinator] = [:]

    private init() {}

    // English: A session key keeps independent instruction tours isolated per scene.
    // Español: La clave de sesión mantiene aislados los tutoriales independientes por escena.
    // 中文：会话键确保不同 Scene 的引导流程彼此隔离。
    public func key(for viewController: UIViewController) -> String {
        if let identifier = viewController.viewIfLoaded?.window?.windowScene?.session.persistentIdentifier
            ?? viewController.navigationController?.viewIfLoaded?.window?.windowScene?.session.persistentIdentifier {
            return "scene:\(identifier)"
        }
        return "controller:\(ObjectIdentifier(viewController))"
    }

    public func coordinator(for key: String) -> PTInstructionCoordinator? {
        sessions[key]
    }

    public func insert(_ coordinator: PTInstructionCoordinator, for key: String) -> Bool {
        guard sessions[key] == nil else { return false }
        sessions[key] = coordinator
        return true
    }

    public func remove(_ coordinator: PTInstructionCoordinator, for key: String) {
        guard sessions[key] === coordinator else { return }
        sessions.removeValue(forKey: key)
    }

    public var activeCoordinators: [PTInstructionCoordinator] {
        Array(sessions.values)
    }
}

@MainActor
public final class PTInstructionCenter {
    public static let shared = PTInstructionCenter()

    public var store: PTInstructionStore = PTUserDefaultsInstructionStore.shared
    public var activeCoordinator: PTInstructionCoordinator? {
        PTInstructionSessionRegistry.shared.activeCoordinators.first
    }

    private init() {}

    public func present(_ tour: PTInstructionTour,
                        in viewController: UIViewController,
                        configuration: PTInstructionConfiguration = .init()) async throws -> PTInstructionResult {
        let registry = PTInstructionSessionRegistry.shared
        let key = registry.key(for: viewController)
        let coordinator = PTInstructionCoordinator(configuration: configuration, store: store)
        guard registry.insert(coordinator, for: key) else {
            throw PTInstructionFailure.alreadyRunning
        }
        defer { registry.remove(coordinator, for: key) }
        return try await coordinator.present(tour, in: viewController)
    }

    public func cancelActive() async {
        await activeCoordinator?.cancel()
    }

    public func pauseActive() async {
        await activeCoordinator?.pause()
    }

    public func resumeActive() async {
        await activeCoordinator?.resume()
    }

    public func reset(tour: PTInstructionTour) async {
        await store.reset(tour: tour)
    }
}
