//
//  PTCollectionLayoutSwitchLabViewController.swift
//  PooTools_Example
//
// English: Demonstrate runtime PTCollectionView layout switching and queued updates.
// Español: Demuestra el cambio de layout en tiempo de ejecución y las actualizaciones en cola.
// 中文：演示 PTCollectionView 运行时布局切换和串行更新。
//

import UIKit
import PooTools

@MainActor
private final class PTCollectionLayoutSwitchTagModel: PTTagLayoutModel {
    let stableID: String
    var isSelected = false
    var isNested = false

    init(stableID: String, title: String, selected: Bool, nested: Bool = false) {
        self.stableID = stableID
        self.isSelected = selected
        self.isNested = nested
        super.init()
        name = title
    }
}

@MainActor
private final class PTCollectionLayoutSwitchCell: PTBaseNormalCell {
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.numberOfLines = 2
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
    }

    required init?(coder: NSCoder) { nil }

    func render(row: PTRows) {
        let model = row.dataModel as? PTCollectionLayoutSwitchTagModel
        titleLabel.text = model?.name ?? row.title
        let selected = model?.isSelected ?? false
        contentView.backgroundColor = selected ? .systemBlue : .secondarySystemBackground
        titleLabel.textColor = selected ? .white : .label
        accessibilityLabel = titleLabel.text
        accessibilityTraits = selected ? [.button, .selected] : [.button]
    }

    override func reconfigureContent(with context: PTCollectionCellContext) -> Bool {
        render(row: context.row)
        return true
    }
}

// English: Demonstrate a PTCollectionView embedded in another PTCollectionView cell.
// Español: Demuestra un PTCollectionView incrustado dentro de una celda de otro PTCollectionView.
// 中文：演示在 PTCollectionView Cell 内嵌套另一个 PTCollectionView。
@MainActor
private final class PTCollectionLayoutSwitchNestedItemCell: UICollectionViewCell {
    static let reuseID = "PTCollectionLayoutSwitchNestedItemCell"
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.textAlignment = .center
        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2)
        ])
        contentView.backgroundColor = .tertiarySystemBackground
        contentView.layer.cornerRadius = 6
        contentView.layer.masksToBounds = true
    }

    required init?(coder: NSCoder) { nil }

    func render(row: PTRows) {
        titleLabel.text = row.title
    }
}

// English: Keep nested-list sizing inside the actual cell hierarchy instead of using screen width.
// Español: Mantiene el tamaño de la lista anidada dentro de la jerarquía real de la celda, no del ancho de pantalla.
// 中文：嵌套列表尺寸必须基于真实 Cell 层级，而不是整机屏幕宽度。
@MainActor
private final class PTCollectionLayoutSwitchNestedCell: UICollectionViewCell {
    static let reuseID = "PTCollectionLayoutSwitchNestedCell"
    private let nestedList: PTCollectionView

    override init(frame: CGRect) {
        let config = PTCollectionViewConfig()
        config.viewType = .Gird
        config.rowCount = 2
        config.itemHeight = 34
        config.cellLeadingSpace = 4
        config.cellTrailingSpace = 4
        nestedList = PTCollectionView(viewConfig: config)
        super.init(frame: frame)

        nestedList.registerClassCells(classs: [PTCollectionLayoutSwitchNestedItemCell.reuseID: PTCollectionLayoutSwitchNestedItemCell.self])
        nestedList.cellInCollectionV2 = { collectionView, context in
            collectionView.dequeueReusableCell(withReuseIdentifier: PTCollectionLayoutSwitchNestedItemCell.reuseID,
                                                for: context.indexPath)
        }
        nestedList.configureCell = { _, cell, context in
            (cell as? PTCollectionLayoutSwitchNestedItemCell)?.render(row: context.row)
        }
        nestedList.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nestedList)
        NSLayoutConstraint.activate([
            nestedList.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            nestedList.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            nestedList.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nestedList.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func render() {
        let rows = (0..<4).map { index in
            PTRows(title: "Nested \(index + 1)",
                   ID: PTCollectionLayoutSwitchNestedItemCell.reuseID,
                   diffId: "nested-\(index)")
        }
        nestedList.showCollectionDetail(collectionData: [PTSection(identifier: "nested-section", rows: rows)],
                                        animated: false)
    }
}

@MainActor
final class PTCollectionLayoutSwitchLabViewController: PTBaseViewController {
    private let layoutControl = UISegmentedControl(items: ["Normal", "Gird", "Water", "Custom", "H", "H Sys", "Tag"])
    private let rowStepper = UIStepper()
    private let heightStepper = UIStepper()
    private let spacingStepper = UIStepper()
    private let headerHeightStepper = UIStepper()
    private let headerSpacingStepper = UIStepper()
    private let footerSpacingStepper = UIStepper()
    private let sectionInsetStepper = UIStepper()
    private let headerSwitch = UISwitch()
    private let footerSwitch = UISwitch()
    private let nestedSwitch = UISwitch()
    private let pinHeaderSwitch = UISwitch()
    private let indexSwitch = UISwitch()
    private let decorationControl = UISegmentedControl(items: ["None", "Normal", "Corner"])
    private let dataControl = UISegmentedControl(items: ["1", "100", "1,000"])
    private let policyControl = UISegmentedControl(items: ["First", "Offset", "Top", "None"])
    private let animationSwitch = UISwitch()
    private let statusLabel = UILabel()
    private let list: PTCollectionView
    private var selectedIDs = Set<String>()
    private var currentCount = 1

    init() {
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemHeight = 56
        config.rowCount = 2
        config.cellLeadingSpace = 8
        config.cellTrailingSpace = 8
        config.contentTopSpace = 8
        config.contentBottomSpace = 8
        config.sectionEdges = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        config.indexConfig = PTCollectionIndexViewConfiguration()
        list = PTCollectionView(viewConfig: config)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Collection Layout Switch Lab"
        view.backgroundColor = .systemBackground
        configureControls()
        configureList()
        applyInitialValues()
        reloadData()
    }

    private func configureControls() {
        layoutControl.selectedSegmentIndex = 0
        layoutControl.addTarget(self, action: #selector(layoutChanged), for: .valueChanged)
        dataControl.selectedSegmentIndex = 0
        dataControl.addTarget(self, action: #selector(dataChanged), for: .valueChanged)
        decorationControl.selectedSegmentIndex = 0
        decorationControl.addTarget(self, action: #selector(decorationChanged), for: .valueChanged)
        policyControl.selectedSegmentIndex = 0
        animationSwitch.isOn = true

        rowStepper.minimumValue = 1
        rowStepper.maximumValue = 6
        rowStepper.value = 2
        rowStepper.addTarget(self, action: #selector(configurationChanged), for: .valueChanged)
        heightStepper.minimumValue = 32
        heightStepper.maximumValue = 140
        heightStepper.stepValue = 4
        heightStepper.value = 56
        heightStepper.addTarget(self, action: #selector(configurationChanged), for: .valueChanged)
        spacingStepper.minimumValue = 0
        spacingStepper.maximumValue = 32
        spacingStepper.stepValue = 2
        spacingStepper.value = 8
        spacingStepper.addTarget(self, action: #selector(configurationChanged), for: .valueChanged)

        headerHeightStepper.minimumValue = 44
        headerHeightStepper.maximumValue = 64
        headerHeightStepper.stepValue = 20
        headerHeightStepper.value = 44
        headerHeightStepper.addTarget(self, action: #selector(dataConfigurationChanged), for: .valueChanged)
        headerSpacingStepper.minimumValue = 0
        headerSpacingStepper.maximumValue = 24
        headerSpacingStepper.stepValue = 8
        headerSpacingStepper.value = 0
        headerSpacingStepper.addTarget(self, action: #selector(dataConfigurationChanged), for: .valueChanged)
        footerSpacingStepper.minimumValue = 0
        footerSpacingStepper.maximumValue = 24
        footerSpacingStepper.stepValue = 8
        footerSpacingStepper.value = 0
        footerSpacingStepper.addTarget(self, action: #selector(dataConfigurationChanged), for: .valueChanged)
        sectionInsetStepper.minimumValue = 0
        sectionInsetStepper.maximumValue = 24
        sectionInsetStepper.stepValue = 12
        sectionInsetStepper.value = 12
        sectionInsetStepper.addTarget(self, action: #selector(configurationChanged), for: .valueChanged)

        [headerSwitch, footerSwitch, pinHeaderSwitch, indexSwitch, nestedSwitch].forEach {
            $0.addTarget(self, action: #selector(configurationChanged), for: .valueChanged)
        }
        headerSwitch.addTarget(self, action: #selector(dataConfigurationChanged), for: .valueChanged)
        footerSwitch.addTarget(self, action: #selector(dataConfigurationChanged), for: .valueChanged)
        nestedSwitch.addTarget(self, action: #selector(dataConfigurationChanged), for: .valueChanged)
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Stress", style: .plain, target: self, action: #selector(runStress)),
            UIBarButtonItem(title: "Skeleton", style: .plain, target: self, action: #selector(toggleSkeleton))
        ]

        statusLabel.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 4
        statusLabel.adjustsFontForContentSizeCategory = true

        let controls = UIStackView(arrangedSubviews: [
            layoutControl,
            makeControlRow("Rows", rowStepper),
            makeControlRow("Height", heightStepper),
            makeControlRow("Space", spacingStepper),
            makeControlRow("Header height", headerHeightStepper),
            makeControlRow("Header gap", headerSpacingStepper),
            makeControlRow("Footer gap", footerSpacingStepper),
            makeControlRow("Section inset", sectionInsetStepper),
            makeControlRow("Header", headerSwitch),
            makeControlRow("Footer", footerSwitch),
            makeControlRow("Nested list", nestedSwitch),
            makeControlRow("Pin header", pinHeaderSwitch),
            makeControlRow("Index", indexSwitch),
            decorationControl,
            dataControl,
            policyControl,
            makeControlRow("Animation", animationSwitch),
            statusLabel
        ])
        controls.axis = .vertical
        controls.spacing = 5
        controls.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controls)
        view.addSubview(list)
        list.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controls.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            controls.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            controls.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            list.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            list.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            list.topAnchor.constraint(equalTo: controls.bottomAnchor, constant: 8),
            list.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makeControlRow(_ title: String, _ control: UIView) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        let row = UIStackView(arrangedSubviews: [label, control])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        label.setContentHuggingPriority(.required, for: .horizontal)
        return row
    }

    private func configureList() {
        list.registerClassCells(classs: [PTCollectionLayoutSwitchCell.reuseID: PTCollectionLayoutSwitchCell.self])
        list.registerClassCells(classs: [PTCollectionLayoutSwitchNestedCell.reuseID: PTCollectionLayoutSwitchNestedCell.self])
        list.registerSupplementaryView(classs: [PTTestHeader.ID: PTTestHeader.self], kind: UICollectionView.elementKindSectionHeader)
        list.registerSupplementaryView(classs: [PTTestFooter.ID: PTTestFooter.self], kind: UICollectionView.elementKindSectionFooter)
        list.customerLayoutWithEnvironment = { _, _, environment in
            let groupWidth = max(1, environment.container.contentSize.width - 24)
            let itemHeight: CGFloat = groupWidth > 600 ? 64 : 56
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(itemHeight))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let group = NSCollectionLayoutSize(widthDimension: .absolute(groupWidth), heightDimension: .estimated(itemHeight))
            return NSCollectionLayoutGroup.vertical(layoutSize: group, subitems: [item])
        }
        // English: Exercise the real waterfall callback so the layout lab covers runtime custom-item geometry.
        // Español: Usa el callback real de waterfall para que el laboratorio cubra la geometría de elementos personalizados.
        // 中文：使用真实的瀑布流回调，确保布局实验室覆盖自定义 Item 几何计算。
        list.waterFallLayout = { index, _ in
            56 + CGFloat(index % 4) * 18
        }
        list.headerInCollection = { _, collectionView, section, indexPath in
            guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                                withReuseIdentifier: PTTestHeader.ID,
                                                                                for: indexPath) as? PTTestHeader else { return nil }
            header.sectionModel = section
            return header
        }
        list.footerInCollection = { _, collectionView, section, indexPath in
            guard let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter,
                                                                                withReuseIdentifier: PTTestFooter.ID,
                                                                                for: indexPath) as? PTTestFooter else { return nil }
            footer.sectionModel = section
            return footer
        }
        list.cellInCollectionV2 = { collectionView, context in
            let reuseID = (context.row.dataModel as? PTCollectionLayoutSwitchTagModel)?.isNested == true
                ? PTCollectionLayoutSwitchNestedCell.reuseID
                : PTCollectionLayoutSwitchCell.reuseID
            return collectionView.dequeueReusableCell(withReuseIdentifier: reuseID,
                                                      for: context.indexPath)
        }
        list.configureCell = { _, cell, context in
            if let nestedCell = cell as? PTCollectionLayoutSwitchNestedCell {
                nestedCell.render()
            } else {
                (cell as? PTCollectionLayoutSwitchCell)?.render(row: context.row)
            }
        }
        list.collectionDidSelect = { [weak self] _, _, indexPath in
            self?.toggleSelection(at: indexPath)
        }
        list.collectionViewDidScroll = { [weak self] _ in
            self?.updateStatus()
        }
    }

    private func applyInitialValues() {
        list.viewConfig.sideIndexTitles = nil
        list.viewConfig.decorationItemsType = .NoItems
    }

    private func makeSections(count: Int) -> [PTSection] {
        let sectionCount = count > 1 ? 2 : 1
        let sections = (0..<sectionCount).map { sectionIndex in
            let rowsInSection = count / sectionCount + (sectionIndex < count % sectionCount ? 1 : 0)
            let rows = (0..<rowsInSection).map { rowIndex -> PTRows in
                let id = "layout-switch-\(sectionIndex)-\(rowIndex)"
                let model = PTCollectionLayoutSwitchTagModel(stableID: id,
                                                              title: "\(sectionIndex + 1)-\(rowIndex + 1)",
                                                              selected: selectedIDs.contains(id),
                                                              nested: nestedSwitch.isOn && sectionIndex == 0 && rowIndex == 0)
                return PTRows(title: model.name,
                              ID: model.isNested ? PTCollectionLayoutSwitchNestedCell.reuseID : PTCollectionLayoutSwitchCell.reuseID,
                              diffId: id,
                              diffHash: rowIndex,
                              dataModel: model)
            }
            let section = PTSection(identifier: "layout-switch-section-\(sectionIndex)",
                                    headerTitle: "Section \(sectionIndex + 1)",
                                    headerID: headerSwitch.isOn ? PTTestHeader.ID : "",
                                    footerID: footerSwitch.isOn ? PTTestFooter.ID : "",
                                    footerHeight: footerSwitch.isOn ? 28 : .leastNormalMagnitude,
                                    headerHeight: headerSwitch.isOn ? CGFloat(headerHeightStepper.value) : .leastNormalMagnitude,
                                    rows: rows)
            section.layoutConfiguration = PTSectionLayoutConfiguration(headerSpacing: CGFloat(headerSpacingStepper.value),
                                                                        footerSpacing: CGFloat(footerSpacingStepper.value))
            return section
        }
        return sections
    }

    private func reloadData() {
        list.showCollectionDetail(collectionData: makeSections(count: currentCount), animated: false) { [weak self] _ in
            self?.updateStatus()
        }
    }

    private func toggleSelection(at indexPath: IndexPath) {
        guard let row = list.getRow(at: indexPath),
              let model = row.dataModel as? PTCollectionLayoutSwitchTagModel else { return }
        if selectedIDs.insert(model.stableID).inserted == false {
            selectedIDs.remove(model.stableID)
        }
        model.isSelected = selectedIDs.contains(model.stableID)
        list.reloadItemContent(at: [indexPath])
        updateStatus()
    }

    private func selectedPolicy() -> PTCollectionLayoutScrollPolicy {
        switch policyControl.selectedSegmentIndex {
        case 1: return .contentOffset
        case 2: return .top
        case 3: return .none
        default: return .firstVisibleItem
        }
    }

    private func selectedLayout() -> PTCollectionViewType {
        switch layoutControl.selectedSegmentIndex {
        case 1: return .Gird
        case 2: return .WaterFall
        case 3: return .Custom
        case 4: return .Horizontal
        case 5: return .HorizontalLayoutSystem
        case 6: return .Tag
        default: return .Normal
        }
    }

    @objc private func layoutChanged() {
        list.switchLayout(to: selectedLayout(),
                          animated: animationSwitch.isOn,
                          scrollPolicy: selectedPolicy()) { [weak self] success in
            self?.updateStatus(message: success ? "layout complete" : "layout rejected")
        }
    }

    @objc private func configurationChanged() {
        let rowCount = Int(rowStepper.value)
        let height = CGFloat(heightStepper.value)
        let spacing = CGFloat(spacingStepper.value)
        list.updateLayoutConfiguration(animated: animationSwitch.isOn,
                                       scrollPolicy: selectedPolicy(),
                                       completion: { [weak self] success in
                                           self?.updateStatus(message: success ? "configuration complete" : "configuration rejected")
                                       }) { [weak self] config in
            guard let self else { return }
            config.rowCount = rowCount
            config.itemHeight = self.nestedSwitch.isOn ? max(height, 140) : height
            let sectionInset = CGFloat(self.sectionInsetStepper.value)
            config.sectionEdges = NSDirectionalEdgeInsets(top: sectionInset,
                                                           leading: 0,
                                                           bottom: sectionInset,
                                                           trailing: 0)
            config.cellLeadingSpace = spacing
            config.cellTrailingSpace = spacing
            config.pinHeaderToVisibleBounds = self.pinHeaderSwitch.isOn
            let sectionCount = self.currentCount > 1 ? 2 : 1
            config.sideIndexTitles = self.indexSwitch.isOn
                ? (1...sectionCount).map(String.init)
                : nil
            config.decorationItemsType = self.decorationType()
        }
    }

    @objc private func decorationChanged() {
        configurationChanged()
    }

    @objc private func dataConfigurationChanged() {
        reloadData()
    }

    @objc private func dataChanged() {
        currentCount = [1, 100, 1_000][max(0, min(2, dataControl.selectedSegmentIndex))]
        reloadData()
    }

    private func decorationType() -> PTCollectionViewDecorationItemsType {
        switch decorationControl.selectedSegmentIndex {
        case 1: return .Normal
        case 2: return .Corner
        default: return .NoItems
        }
    }

    @objc private func toggleSkeleton() {
        if list.isSkeletonVisible {
            list.hideSkeleton()
        } else {
            list.showSkeleton()
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(900))
                self?.list.hideSkeleton()
            }
        }
        updateStatus()
    }

    @objc private func runStress() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let types: [PTCollectionViewType] = [.Normal, .Gird, .WaterFall, .Horizontal, .Tag, .Custom, .HorizontalLayoutSystem]
            for index in 0..<14 {
                guard !Task.isCancelled else { return }
                if index > 0 { try? await Task.sleep(for: .milliseconds(35)) }
                self.list.switchLayout(to: types[index % types.count], animated: false, scrollPolicy: .firstVisibleItem)
                if let row = self.list.getRow(at: IndexPath(item: 0, section: 0)) {
                    row.title = "Stress (index)"
                    self.list.updateRow(row)
                }
                if index % 4 == 1 {
                    self.insertStressRow(index)
                } else if index % 4 == 3 {
                    self.deleteStressRow()
                }
            }
            self.updateStatus(message: "stress sequence queued")
        }
    }

    private func insertStressRow(_ index: Int) {
        let id = "stress-\(index)-\(UUID().uuidString)"
        let model = PTCollectionLayoutSwitchTagModel(stableID: id, title: "Inserted \(index)", selected: false)
        let row = PTRows(title: model.name,
                         ID: PTCollectionLayoutSwitchCell.reuseID,
                         diffId: id,
                         dataModel: model)
        list.insertRows([row], at: IndexPath(item: 0, section: 0))
    }

    private func deleteStressRow() {
        guard let row = list.getRow(at: IndexPath(item: 0, section: 0)) else { return }
        list.deleteRows([row], from: 0)
    }

    private func updateStatus(message: String? = nil) {
        let visibleIDs = list.contentCollectionView.indexPathsForVisibleItems
            .sorted()
            .prefix(4)
            .compactMap { list.getRow(at: $0)?.diffId }
            .joined(separator: ",")
        let visibleDisplay = visibleIDs.isEmpty ? "-" : visibleIDs
        let offset = String(format: "%.1f,%.1f",
                            list.contentCollectionView.contentOffset.x,
                            list.contentCollectionView.contentOffset.y)
        let kind = list.activeUpdateKind?.rawValue ?? "idle"
        let spacing = layoutMeasurement()
        statusLabel.text = "type: \(selectedLayout())  visible: \(visibleDisplay)\n" +
            "offset: \(offset)  " +
            "apply: \(list.snapshotApplyCount) pending: \(list.pendingUpdateCount) kind: \(kind)\n" +
            "\(spacing)\n" +
            (message ?? "ready")
    }

    private func layoutMeasurement() -> String {
        let collectionView = list.contentCollectionView
        collectionView.layoutIfNeeded()
        guard headerSwitch.isOn,
              let header = collectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionHeader,
                                                                                   at: IndexPath(item: 0, section: 0)),
              let cell = collectionView.layoutAttributesForItem(at: IndexPath(item: 0, section: 0)) else {
            return "header/cell: -"
        }
        let gap = cell.frame.minY - header.frame.maxY
        return String(format: "header: %.1f  cell: %.1f  gap: %.1f  width: %.1f",
                      header.frame.height,
                      cell.frame.height,
                      gap,
                      collectionView.bounds.width)
    }
}
