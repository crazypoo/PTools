// English: Scene-aware banner presenter, stack layout, timer, and lifecycle handling.
// Español: Presenter consciente de la escena con layout apilado, temporizadores y ciclo de vida.
// 中文：负责 Scene、堆叠布局、定时器和生命周期的 Banner Presenter。

import UIKit
#if canImport(PToolsCore)
import PToolsCore
#endif
#if canImport(PToolsOverlay)
import PToolsOverlay
#endif

@MainActor
public final class PTBannerQueue {
    private struct Entry {
        let banner: PTBanner
        let handle: PTBannerHandle
        let position: PTBannerEnqueuePosition
        let sequence: UInt64
    }

    private(set) var configuration: PTBannerQueueConfiguration
    private var entries: [Entry] = []
    private var sequence: UInt64 = 0
    private var recentContent: [String: Date] = [:]

    init(configuration: PTBannerQueueConfiguration) {
        self.configuration = configuration
    }

    func enqueue(_ banner: PTBanner,
                 handle: PTBannerHandle,
                 position: PTBannerEnqueuePosition) -> [PTBannerHandle] {
        if isDuplicate(banner) {
            return [handle]
        }

        sequence &+= 1
        entries.append(Entry(banner: banner, handle: handle, position: position, sequence: sequence))
        guard configuration.overflow != .keepAll,
              entries.count > configuration.maxQueueCount else { return [] }

        switch configuration.overflow {
        case .keepAll:
            return []
        case .dropNewest:
            let dropped = entries.removeLast()
            return [dropped.handle]
        case .dropOldest:
            guard let oldestIndex = entries.indices.min(by: { entries[$0].sequence < entries[$1].sequence }) else { return [] }
            let dropped = entries.remove(at: oldestIndex)
            return [dropped.handle]
        }
    }

    func dequeue() -> (banner: PTBanner, handle: PTBannerHandle)? {
        guard let index = entries.indices.min(by: { lhs, rhs in
            let left = entries[lhs]
            let right = entries[rhs]
            if left.banner.priority.rawValue != right.banner.priority.rawValue {
                return left.banner.priority.rawValue > right.banner.priority.rawValue
            }
            if left.position != right.position {
                return left.position == .front
            }
            return left.sequence < right.sequence
        }) else { return nil }
        let entry = entries.remove(at: index)
        return (entry.banner, entry.handle)
    }

    func remove(id: UUID) -> PTBannerHandle? {
        guard let index = entries.firstIndex(where: { $0.banner.id == id }) else { return nil }
        return entries.remove(at: index).handle
    }

    var isEmpty: Bool { entries.isEmpty }

    private func isDuplicate(_ banner: PTBanner) -> Bool {
        switch configuration.deduplication {
        case .none:
            return false
        case .byID:
            return entries.contains { $0.banner.id == banner.id }
        case let .byContent(window):
            let key = contentKey(for: banner)
            let now = Date()
            recentContent = recentContent.filter { now.timeIntervalSince($0.value) < window }
            if recentContent[key] != nil { return true }
            recentContent[key] = now
            return false
        }
    }

    private func contentKey(for banner: PTBanner) -> String {
        func text(_ value: PTBannerText?) -> String {
            switch value {
            case let .string(value):
                return value
            case let .attributed(value):
                return value.string
            case nil:
                return ""
            }
        }
        return "\(text(banner.content.title))|\(text(banner.content.subtitle))|\(banner.style)"
    }
}

@MainActor
public final class PTBannerPresenter {
    public typealias Completion = @MainActor @Sendable (PTBannerResult) -> Void

    @MainActor
    private final class Record {
        var banner: PTBanner
        let handle: PTBannerHandle
        let view: PooToolsBannerView
        let animator = PTOverlayAnimator()
        let completion: Completion
        var timer: Task<Void, Never>?
        var startedAt = Date()
        var remainingDuration: TimeInterval?
        var isSuspended = false

        init(banner: PTBanner,
             handle: PTBannerHandle,
             view: PooToolsBannerView,
             completion: @escaping Completion) {
            self.banner = banner
            self.handle = handle
            self.view = view
            self.completion = completion
        }
    }

    public let scene: UIWindowScene
    private let host: PTOverlayHost
    private var lifecycle: PTOverlayLifecycle?
    private var stacks: [PTBannerPosition: UIStackView] = [:]
    private var records: [UUID: Record] = [:]
    private var order: [UUID] = []

    public var activeCount: Int { records.count }

    public init?(context: PTOverlayPresentationContext,
                mode: PTOverlayPresentationMode) {
        guard let scene = PTOverlaySceneResolver.scene(for: context),
              let host = PTOverlayHost(context: context, mode: mode, layer: .banner) else { return nil }
        self.scene = scene
        self.host = host
        host.containerView.hitTestPolicy = .passthroughOutsideContent
        lifecycle = PTOverlayLifecycle(scene: scene) { [weak self] event in
            self?.handleLifecycle(event)
        }
    }

    deinit {
        lifecycle = nil
    }

    public func present(_ banner: PTBanner,
                        handle: PTBannerHandle,
                        completion: @escaping Completion) {
        let view = PooToolsBannerView(banner: banner)
        view.onTapRequest = { [weak self, weak handle] in
            guard let self, let handle else { return }
            banner.onTap?()
            self.triggerHaptic(for: banner)
            if banner.configuration.allowsTapToDismiss {
                self.dismiss(id: handle.id, result: .tapped)
            }
        }
        view.onSwipeRequest = { [weak self, weak handle] in
            guard let self, let handle else { return }
            self.triggerHaptic(for: banner)
            self.dismiss(id: handle.id, result: .swiped)
        }

        let stack = stack(for: banner.configuration.position,
                          keyboardAvoidance: banner.configuration.keyboardAvoidance)
        stack.addArrangedSubview(view)
        if banner.configuration.maximumVisibleHeight > 0 {
            view.heightAnchor.constraint(lessThanOrEqualToConstant: banner.configuration.maximumVisibleHeight).isActive = true
        }
        let record = Record(banner: banner, handle: handle, view: view, completion: completion)
        records[handle.id] = record
        order.append(handle.id)
        handle.setState(.preparing)
        host.containerView.layoutIfNeeded()
        handle.setState(.presenting)
        record.animator.present(view: view, transition: transition(for: banner)) { [weak self, weak handle] in
            guard let self, let handle, let record = self.records[handle.id] else { return }
            handle.setState(.visible)
            self.startTimer(for: record)
        }
        announceIfNeeded(banner, view: view)
        triggerHaptic(for: banner)
    }

    public func update(_ banner: PTBanner, id: UUID) {
        guard let record = records[id] else { return }
        record.banner = banner
        record.view.apply(banner)
        record.timer?.cancel()
        record.remainingDuration = nil
        if record.isSuspended == false {
            startTimer(for: record)
        }
    }

    public func dismiss(id: UUID, result: PTBannerResult) {
        guard let record = records[id] else { return }
        record.timer?.cancel()
        record.timer = nil
        record.handle.setState(.dismissing)
        record.animator.dismiss(view: record.view,
                                transition: transition(for: record.banner)) { [weak self] in
            self?.complete(id: id, result: result)
        }
    }

    public func dismissAll(result: PTBannerResult) {
        order.forEach { dismiss(id: $0, result: result) }
    }

    public func suspendLatest() {
        guard let id = order.last, let record = records[id], record.isSuspended == false else { return }
        suspend(record)
    }

    public func suspendAll() {
        records.values.forEach { suspend($0) }
    }

    public func resumeSuspended() {
        records.values.filter(\.isSuspended).forEach { record in
            record.isSuspended = false
            record.handle.setState(.visible)
            startTimer(for: record)
        }
    }

    public func close() {
        records.values.forEach { record in
            record.timer?.cancel()
            record.animator.stop()
            record.view.removeFromSuperview()
        }
        records.removeAll(keepingCapacity: false)
        order.removeAll(keepingCapacity: false)
        lifecycle = nil
        host.detach()
    }

    private func complete(id: UUID, result: PTBannerResult) {
        guard let record = records.removeValue(forKey: id) else { return }
        order.removeAll { $0 == id }
        record.timer?.cancel()
        record.view.removeFromSuperview()
        record.handle.finish(result)
        record.completion(result)
    }

    private func stack(for position: PTBannerPosition,
                       keyboardAvoidance: PTBannerKeyboardAvoidance) -> UIStackView {
        if let stack = stacks[position] { return stack }
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        host.containerView.addSubview(stack)
        host.containerView.interactiveContentViews.append(stack)

        let horizontalInset: CGFloat = 12
        var constraints = [NSLayoutConstraint](arrayLiteral:
            stack.leadingAnchor.constraint(equalTo: host.containerView.leadingAnchor, constant: horizontalInset),
            stack.trailingAnchor.constraint(equalTo: host.containerView.trailingAnchor, constant: -horizontalInset)
        )
        switch position {
        case .top:
            constraints.append(stack.topAnchor.constraint(equalTo: host.containerView.safeAreaLayoutGuide.topAnchor, constant: 8))
        case .bottom:
            constraints.append(stack.bottomAnchor.constraint(equalTo: host.containerView.safeAreaLayoutGuide.bottomAnchor, constant: -8))
            if keyboardAvoidance == .automatic {
                constraints.append(stack.bottomAnchor.constraint(lessThanOrEqualTo: host.containerView.keyboardLayoutGuide.topAnchor, constant: -8))
            }
        }
        NSLayoutConstraint.activate(constraints)
        stacks[position] = stack
        return stack
    }

    private func startTimer(for record: Record) {
        record.timer?.cancel()
        guard record.banner.configuration.duration != .persistent else { return }
        let duration = record.remainingDuration ?? duration(for: record.banner)
        guard duration > 0 else {
            dismiss(id: record.handle.id, result: .autoDismissed)
            return
        }
        record.remainingDuration = duration
        record.startedAt = Date()
        let id = record.handle.id
        record.timer = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            } catch {
                return
            }
            guard Task.isCancelled == false else { return }
            self?.dismiss(id: id, result: .autoDismissed)
        }
    }

    private func suspend(_ record: Record) {
        guard record.isSuspended == false else { return }
        if record.banner.configuration.duration != .persistent {
            let elapsed = Date().timeIntervalSince(record.startedAt)
            record.remainingDuration = max(0, (record.remainingDuration ?? duration(for: record.banner)) - elapsed)
        }
        record.timer?.cancel()
        record.timer = nil
        record.isSuspended = true
        record.handle.setState(.visible)
    }

    private func duration(for banner: PTBanner) -> TimeInterval {
        switch banner.configuration.duration {
        case let .seconds(seconds):
            return max(0, seconds)
        case .persistent:
            return 0
        case .automatic:
            func text(_ value: PTBannerText?) -> String {
                switch value {
                case let .string(value): return value
                case let .attributed(value): return value.string
                case nil: return ""
                }
            }
            let count = text(banner.content.title).count + text(banner.content.subtitle).count
            return min(7, max(2.5, 2.5 + Double(count) / 35))
        }
    }

    private func transition(for banner: PTBanner) -> PTOverlayTransition {
        switch banner.configuration.layoutMode {
        case .floating:
            return .spring
        case .compact, .standard, .growing:
            return banner.configuration.position == .top ? .slideFromTop : .slideFromBottom
        }
    }

    private func triggerHaptic(for banner: PTBanner) {
        let haptic = banner.configuration.haptic
        let resolved: PTBannerHaptic = haptic == .automatic ? automaticHaptic(for: banner.style) : haptic
        switch resolved {
        case .none:
            break
        case .light:
            PTFeedbackCenter.shared.emit(.selectionChanged)
        case .medium:
            PTFeedbackCenter.shared.emit(.selectionChanged)
        case .heavy:
            PTFeedbackCenter.shared.emit(.selectionChanged)
        case .success, .warning, .error:
            PTFeedbackCenter.shared.emit(resolved == .success ? .success : resolved == .warning ? .warning : .error)
        case .automatic:
            break
        }
    }

    private func automaticHaptic(for style: PTBannerStyle) -> PTBannerHaptic {
        switch style {
        case .success: return .success
        case .warning: return .warning
        case .danger: return .error
        default: return .light
        }
    }

    private func announceIfNeeded(_ banner: PTBanner, view: PooToolsBannerView) {
        switch banner.configuration.accessibilityAnnouncement {
        case .disabled:
            return
        case .enabled:
            UIAccessibility.post(notification: .announcement, argument: view.accessibilityLabel)
        case .automatic:
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement, argument: view.accessibilityLabel)
            }
        }
    }

    private func handleLifecycle(_ event: PTOverlayLifecycleEvent) {
        switch event {
        case .didEnterBackground:
            suspendAll()
        case .didBecomeActive:
            resumeSuspended()
        case .didDisconnect:
            dismissAll(result: .dropped)
            PTOverlayRegistryStore.shared.removeRegistry(for: scene)
        }
    }
}

@MainActor
public final class PTBannerCenter {
    public static let shared = PTBannerCenter()

    private final class SceneState {
        let scene: UIWindowScene
        let presenter: PTBannerPresenter
        let queue: PTBannerQueue
        var handles: [UUID: PTBannerHandle] = [:]

        init(scene: UIWindowScene, presenter: PTBannerPresenter, queue: PTBannerQueue) {
            self.scene = scene
            self.presenter = presenter
            self.queue = queue
        }
    }

    public var queueConfiguration = PTBannerQueueConfiguration()

    private var sceneStates: [String: SceneState] = [:]

    private init() {}

    @discardableResult
    public func show(_ banner: PTBanner,
                     context: PTOverlayPresentationContext = .automatic,
                     enqueuePosition: PTBannerEnqueuePosition = .back,
                     interruptionPolicy: PTBannerInterruptionPolicy = .enqueue) -> PTBannerHandle {
        let handle = PTBannerHandle(id: banner.id)
        guard let scene = PTOverlaySceneResolver.scene(for: context),
              let state = state(for: scene, context: context, mode: banner.configuration.presentationMode) else {
            handle.finish(.dropped)
            return handle
        }

        state.handles[banner.id] = handle
        handle.setDismissAction { [weak self] result in
            self?.dismiss(id: banner.id, scene: scene, result: result)
        }
        handle.setUpdateAction { [weak self] updatedBanner in
            self?.update(updatedBanner, scene: scene)
        }

        switch interruptionPolicy {
        case .replace:
            state.presenter.dismissAll(result: .replaced)
            present(banner, handle: handle, state: state)
        case .suspendCurrent:
            state.presenter.suspendLatest()
            present(banner, handle: handle, state: state)
        case .enqueue:
            if state.presenter.activeCount < queueConfiguration.maxVisibleCount {
                present(banner, handle: handle, state: state)
            } else {
                let dropped = state.queue.enqueue(banner, handle: handle, position: enqueuePosition)
                dropped.forEach {
                    state.handles.removeValue(forKey: $0.id)
                    $0.finish(.dropped)
                }
            }
        }
        return handle
    }

    public func present(_ banner: PTBanner,
                        context: PTOverlayPresentationContext = .automatic,
                        enqueuePosition: PTBannerEnqueuePosition = .back,
                        interruptionPolicy: PTBannerInterruptionPolicy = .enqueue) async -> PTBannerResult {
        let handle = show(banner,
                          context: context,
                          enqueuePosition: enqueuePosition,
                          interruptionPolicy: interruptionPolicy)
        return await handle.result()
    }

    public func dismissAll(context: PTOverlayPresentationContext = .automatic) {
        guard let scene = PTOverlaySceneResolver.scene(for: context), let state = sceneStates[id(for: scene)] else { return }
        state.presenter.dismissAll(result: .manuallyDismissed)
        while let next = state.queue.dequeue() {
            state.handles.removeValue(forKey: next.handle.id)
            next.handle.finish(.manuallyDismissed)
        }
    }

    private func state(for scene: UIWindowScene,
                       context: PTOverlayPresentationContext,
                       mode: PTOverlayPresentationMode) -> SceneState? {
        let key = id(for: scene)
        if let state = sceneStates[key] { return state }
        guard let presenter = PTBannerPresenter(context: context, mode: mode) else { return nil }
        let state = SceneState(scene: scene,
                               presenter: presenter,
                               queue: PTBannerQueue(configuration: queueConfiguration))
        sceneStates[key] = state
        return state
    }

    private func present(_ banner: PTBanner, handle: PTBannerHandle, state: SceneState) {
        state.presenter.present(banner, handle: handle) { [weak self, weak state] result in
            guard let self, let state else { return }
            state.handles.removeValue(forKey: handle.id)
            self.drain(state)
            if result != .dropped {
                state.presenter.resumeSuspended()
            }
        }
    }

    private func dismiss(id: UUID, scene: UIWindowScene, result: PTBannerResult) {
        guard let state = sceneStates[self.id(for: scene)] else { return }
        if state.queue.remove(id: id) != nil {
            state.handles.removeValue(forKey: id)?.finish(result)
            return
        }
        state.presenter.dismiss(id: id, result: result)
    }

    private func update(_ banner: PTBanner, scene: UIWindowScene) {
        sceneStates[id(for: scene)]?.presenter.update(banner, id: banner.id)
    }

    private func drain(_ state: SceneState) {
        while state.presenter.activeCount < queueConfiguration.maxVisibleCount,
              let next = state.queue.dequeue() {
            present(next.banner, handle: next.handle, state: state)
        }
    }

    private func id(for scene: UIWindowScene) -> String {
        scene.session.persistentIdentifier
    }
}

@MainActor
public extension UIViewController {
    @discardableResult
    func showBanner(_ banner: PTBanner,
                    enqueuePosition: PTBannerEnqueuePosition = .back,
                    interruptionPolicy: PTBannerInterruptionPolicy = .enqueue) -> PTBannerHandle {
        PTBannerCenter.shared.show(banner,
                                   context: .viewController(self),
                                   enqueuePosition: enqueuePosition,
                                   interruptionPolicy: interruptionPolicy)
    }
}
