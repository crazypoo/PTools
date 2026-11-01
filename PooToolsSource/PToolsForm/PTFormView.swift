// English: Embeddable Form UIView owns collection rendering, focus, validation presentation and events.
// Español: UIView de formulario insertable, independiente del controlador de pantalla.
// 中文：可嵌入任意 UIViewController 的表单视图，与页面容器解耦。
#if canImport(UIKit)
import UIKit
import SnapKit
#if SWIFT_PACKAGE
import ptools
import PToolsCore
import PToolsTheme
import PToolsAccessibility
#endif

@MainActor
public final class PTFormView: UIView {
    public let form: PTFormEngine
    public let listView: PTCollectionView
    public let rendererRegistry: PTFormFieldRendererRegistry
    public let sectionRendererRegistry: PTFormSectionRendererRegistry
    public let formTheme: PTFormThemeAdapter
    public let configuration: PTFormConfiguration
    public var onEvent: (@MainActor @Sendable (PTFormEvent) -> Void)?
    public var showsValidationSummary = false
    /// Approve or reject editable field changes, e.g. biometric authentication before a toggle commits.
    public var onValueChangeRequest: (@MainActor (PTFormFieldID, PTFormValue) async throws -> PTFormValue)?
    /// Optional async business action. The action row stays busy until this completes.
    public var onActionRequest: (@MainActor (PTFormActionID) async throws -> Void)?

    private let keyboardCoordinator = PTFormKeyboardCoordinator()
    private let collectionAdapter: PTFormCollectionAdapter
    private var cachedFields: [PTFormFieldID: PTFormField] = [:]
    private var latestLocations: [PTFormFieldLocation] = []
    private var validationIssues: [PTFormFieldID: String] = [:]
    private var announcedIssueIDs: Set<PTFormFieldID> = []
    private var refreshTask: Task<Void, Never>?
    private var refreshTicket: UInt64 = 0
    private var pendingFieldIDs: Set<PTFormFieldID> = []

    public init(form: PTFormEngine,
                configuration: PTFormConfiguration = .grouped,
                rendererRegistry: PTFormFieldRendererRegistry = .init(),
                sectionRendererRegistry: PTFormSectionRendererRegistry = .init(),
                themeAdapter: PTFormThemeAdapter? = nil) {
        self.form = form
        self.configuration = configuration
        self.rendererRegistry = rendererRegistry
        self.sectionRendererRegistry = sectionRendererRegistry
        self.formTheme = themeAdapter ?? rendererRegistry.themeAdapter
        self.listView = PTCollectionView(viewConfig: PTCollectionViewConfig())
        self.collectionAdapter = PTFormCollectionAdapter()
        self.rendererRegistry.themeAdapter = self.formTheme
        super.init(frame: .zero)
        configureView()
    }

    public required init?(coder: NSCoder) {
        form = PTFormEngine(fields: [])
        configuration = .grouped
        rendererRegistry = PTFormFieldRendererRegistry()
        sectionRendererRegistry = PTFormSectionRendererRegistry()
        formTheme = rendererRegistry.themeAdapter
        listView = PTCollectionView(viewConfig: PTCollectionViewConfig())
        collectionAdapter = PTFormCollectionAdapter()
        super.init(coder: coder)
        configureView()
    }

    deinit {
        refreshTask?.cancel()
    }

    private func configureView() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self]) { [weak self] (_: PTFormView, _: UITraitCollection) in
            guard let self else { return }
            self.rendererRegistry.themeAdapter = self.formTheme
            self.listView.contentCollectionView.reloadData()
        }
        addSubview(listView)
        listView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        switch configuration.safeAreaPolicy {
        case .automatic:
            listView.contentCollectionView.contentInsetAdjustmentBehavior = .automatic
        case .respectContentInsets, .ignore:
            listView.contentCollectionView.contentInsetAdjustmentBehavior = .never
        }
        listView.viewConfig.sectionEdges = NSDirectionalEdgeInsets(top: configuration.contentInsets.top,
                                                                     leading: configuration.contentInsets.leading,
                                                                     bottom: configuration.contentInsets.bottom,
                                                                     trailing: configuration.contentInsets.trailing)
        listView.registerClassCells(classs: [PTFormFieldCell.reuseID: PTFormFieldCell.self])
        listView.registerSupplementaryView(classs: [PTFormDefaultSectionHeader.reuseID: PTFormDefaultSectionHeader.self],
                                            kind: UICollectionView.elementKindSectionHeader)
        listView.registerSupplementaryView(classs: [PTFormDefaultSectionFooter.reuseID: PTFormDefaultSectionFooter.self],
                                            kind: UICollectionView.elementKindSectionFooter)

        listView.headerInCollection = { [weak self] kind, collectionView, section, indexPath in
            guard let self,
                  let box = section.headerDataModel as? PTFormSupplementaryBox else { return nil }
            let context = PTFormSectionRenderContext(sectionID: box.sectionID,
                                                     theme: self.formTheme,
                                                     environment: self.formEnvironment())
            return self.sectionRendererRegistry.dequeueView(content: box.content,
                                                             context: context,
                                                             kind: kind,
                                                             collectionView: collectionView,
                                                             indexPath: indexPath)
        }
        listView.footerInCollection = { [weak self] kind, collectionView, section, indexPath in
            guard let self,
                  let box = section.footerDataModel as? PTFormSupplementaryBox else { return nil }
            let context = PTFormSectionRenderContext(sectionID: box.sectionID,
                                                     theme: self.formTheme,
                                                     environment: self.formEnvironment())
            return self.sectionRendererRegistry.dequeueView(content: box.content,
                                                             context: context,
                                                             kind: kind,
                                                             collectionView: collectionView,
                                                             indexPath: indexPath)
        }
        listView.cellInCollection = { [weak self] collectionView, section, indexPath in
            guard let self,
                  let row = section.rows?[safe: indexPath.item],
                  let box = row.dataModel as? PTFormFieldBox,
                  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PTFormFieldCell.reuseID,
                                                                 for: indexPath) as? PTFormFieldCell else { return nil }
            let field = self.renderField(box.field)
            cell.configure(field: field,
                           sectionID: section.identifier,
                           renderer: self.rendererRegistry.renderer(for: field.rendererIdentifier,
                                                                     kind: field.kind),
                           issue: self.validationIssues[box.field.id],
                           themeAdapter: self.formTheme,
                           environment: self.formEnvironment(),
                           keyboardCoordinator: self.keyboardCoordinator,
                           hasPrevious: self.focusableLocation(for: field.id, step: -1) != nil,
                           hasNext: self.focusableLocation(for: field.id, step: 1) != nil,
                           onChange: { [weak self] value in
                self?.setValue(value, for: box.field.id)
           },
                           onPrevious: { [weak self] in self?.focusPrevious(after: field.id) },
                           onNext: { [weak self] in self?.focusNext(after: field.id) },
                           onDone: { [weak self] in self?.endEditing(true) })
            return cell
        }
        listView.collectionDidSelect = { [weak self] _, section, indexPath in
            guard let field = (section.rows?[safe: indexPath.item]?.dataModel as? PTFormFieldBox)?.field else { return }
            self?.dispatchAction(for: field)
        }
        refreshTask = Task { @MainActor [weak self] in
            await self?.refresh()
        }
    }

    public func refresh() async {
        refreshTicket &+= 1
        let ticket = refreshTicket
        let snapshot = await form.makeSnapshot()
        guard ticket == refreshTicket else { return }
        latestLocations = collectionAdapter.locations(for: snapshot)
        cachedFields = Dictionary(uniqueKeysWithValues: snapshot.fields.map { ($0.id, $0) })
        let sections = collectionAdapter.makeSections(from: snapshot,
                                                       configuration: configuration,
                                                       themeAdapter: formTheme,
                                                       validationIssues: validationIssues)
        listView.showCollectionDetail(collectionData: sections, animated: false)
    }

    private func dispatchAction(for field: PTFormField) {
        guard field.isEnabled, !field.isReadOnly, !field.isLoading,
              !pendingFieldIDs.contains(field.id), let actionID = field.actionID else { return }
        onEvent?(.action(actionID))
        guard let operation = onActionRequest else { return }
        Task { @MainActor [weak self] in
            do {
                try await self?.performAction(for: field.id) { try await operation(actionID) }
            } catch {
                PTFeedbackCenter.shared.emit(.error)
            }
        }
    }

    /// Execute an async row action without changing the field value or dirty state.
    public func performAction(for id: PTFormFieldID,
                              operation: @escaping @MainActor () async throws -> Void) async throws {
        guard !pendingFieldIDs.contains(id) else { return }
        pendingFieldIDs.insert(id)
        defer { pendingFieldIDs.remove(id) }
        try await form.setFieldLoading(true, for: id)
        await refresh()
        do {
            try await operation()
        } catch {
            try? await form.setFieldLoading(false, for: id)
            await refresh()
            throw error
        }
        try? await form.setFieldLoading(false, for: id)
        await refresh()
    }

    /// Host changes can be batched through the engine and rendered as one snapshot.
    public func performUpdates(_ mutations: [PTFormMutation]) async throws {
        try await form.performUpdates(mutations)
        await refresh()
    }

    private func setValue(_ value: PTFormValue, for id: PTFormFieldID) {
        if let field = cachedFields[id], field.actionID != nil {
            dispatchAction(for: field)
            return
        }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let needsApproval = onValueChangeRequest != nil
            if needsApproval {
                guard !pendingFieldIDs.contains(id) else { return }
                pendingFieldIDs.insert(id)
            }
            do {
                if needsApproval {
                    try await form.setFieldLoading(true, for: id)
                    await refresh()
                }
                let committed = try await onValueChangeRequest?(id, value) ?? value
                try await form.setValue(committed, for: id)
                onEvent?(.valueChanged(id, committed))
                if configuration.validationPolicy.trigger == .onChange {
                    let result = await form.validateField(id)
                    applyValidation(result, for: id)
                    onEvent?(.validationChanged(id))
                } else {
                    validationIssues[id] = nil
                }
            } catch {
                // Never commit a rejected switch value; a refresh restores the displayed value.
                PTFeedbackCenter.shared.emit(.error)
            }
            if needsApproval {
                try? await form.setFieldLoading(false, for: id)
                pendingFieldIDs.remove(id)
            }
            await refresh()
        }
    }

    public func validate() async -> PTFormValidationResult {
        let result = await form.validateAll()
        validationIssues = Dictionary(result.issues.map { ($0.fieldID, $0.message) }, uniquingKeysWith: { _, last in last })
        if let issue = result.issues.first {
            PTFormAccessibilityAdapter.announceValidationFailure(issue)
            PTFeedbackCenter.shared.emit(.validationFailure)
            if configuration.validationPolicy.focusesFirstInvalidField {
                focusField(issue.fieldID)
            }
        }
        if let issue = result.issues.first {
            onEvent?(.validationChanged(issue.fieldID))
        }
        await refresh()
        return result
    }

    public func submit(_ operation: @escaping @Sendable ([PTFormFieldID: PTFormValue]) async throws -> Void) async throws {
        let result = await validate()
        guard result.isValid else { throw PTFormError.invalid(result) }
        do {
            try await form.submit(operation)
            PTFeedbackCenter.shared.emit(.success)
            onEvent?(.submissionChanged(.succeeded))
        } catch {
            PTFeedbackCenter.shared.emit(.error)
            throw error
        }
    }

    private func focusNext(after id: PTFormFieldID) {
        guard let location = focusableLocation(for: id, step: 1) else {
            endEditing(true)
            return
        }
        focus(location: location)
    }

    private func focusPrevious(after id: PTFormFieldID) {
        guard let location = focusableLocation(for: id, step: -1) else { return }
        focus(location: location)
    }

    public func focusField(_ id: PTFormFieldID) {
        guard let location = latestLocations.first(where: { $0.fieldID == id }) else { return }
        focus(location: location)
    }

    public func scrollToField(_ id: PTFormFieldID, animated: Bool = true) {
        guard let location = latestLocations.first(where: { $0.fieldID == id }) else { return }
        listView.contentCollectionView.scrollToItem(at: IndexPath(item: location.itemIndex,
                                                                  section: location.sectionIndex),
                                                    at: .centeredVertically,
                                                    animated: animated)
    }

    private func focus(location: PTFormFieldLocation) {
        let indexPath = IndexPath(item: location.itemIndex, section: location.sectionIndex)
        listView.contentCollectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
        Task { @MainActor [weak self] in
            await Task.yield()
            (self?.listView.contentCollectionView.cellForItem(at: indexPath) as? PTFormFieldCell)?.focusField()
        }
    }

    private func focusableLocation(for id: PTFormFieldID, step: Int) -> PTFormFieldLocation? {
        let locations = latestLocations.filter { location in
            guard let field = cachedFields[location.fieldID], field.isEnabled, !field.isReadOnly else { return false }
            return rendererRegistry.renderer(for: field.rendererIdentifier, kind: field.kind).focusBehavior != .notFocusable
        }
        guard let start = locations.firstIndex(where: { $0.fieldID == id }) else { return nil }
        let index = start + step
        return locations.indices.contains(index) ? locations[index] : nil
    }

    private func renderField(_ field: PTFormField) -> PTFormField {
        var result = field
        if result.configuration == nil {
            result.configuration = configuration.defaultFieldConfiguration
        }
        if field.kind == .action || field.kind == .detail || field.kind == .status {
            result.configuration?.titlePlacement = .hidden
        }
        switch configuration.interactionMode {
        case .editable:
            break
        case .readOnly:
            result.isReadOnly = true
        case .disabled:
            result.isEnabled = false
        }
        return result
    }

    private func formEnvironment() -> PTFormEnvironment {
        PTFormEnvironment(isReduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
                          isHighContrastEnabled: traitCollection.accessibilityContrast == .high,
                          layoutDirection: effectiveUserInterfaceLayoutDirection == .rightToLeft ? .rightToLeft : .leftToRight)
    }

    private func applyValidation(_ result: PTFormValidationResult, for id: PTFormFieldID) {
        validationIssues[id] = result.issues.first?.message
        if let issue = result.issues.first, announcedIssueIDs.insert(id).inserted {
            PTFormAccessibilityAdapter.announceValidationFailure(issue)
            PTFeedbackCenter.shared.emit(.validationFailure)
        } else if result.issues.isEmpty {
            announcedIssueIDs.remove(id)
        }
    }

    public static func display(_ value: PTFormValue) -> String {
        switch value { case .empty: ""; case .string(let v): v; case .number(let v): String(v); case .boolean(let v): v ? "On" : "Off"; case .date(let v): v.formatted(); case .data: "Data" }
    }
}
#endif
