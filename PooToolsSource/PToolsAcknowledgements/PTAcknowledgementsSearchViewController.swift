// English: Render acknowledgements through the canonical PTools search and collection pipeline.
// Español: Renderiza los acknowledgements mediante la canalización canónica de búsqueda y colección de PTools.
// 中文：通过 PTools 的统一搜索和集合列表管线展示开源致谢信息。

#if canImport(UIKit) && (canImport(PooToolsSearch) || POOTOOLS_SEARCH)
import UIKit
import SnapKit
#if canImport(ptools)
import ptools
#endif
#if canImport(PToolsAcknowledgementsCore)
import PToolsAcknowledgementsCore
#endif
#if canImport(PooToolsSearch)
import PooToolsSearch
#endif

@MainActor
private final class PTAcknowledgementRowBox: NSObject {
    let entry: PTAcknowledgement

    init(entry: PTAcknowledgement) {
        self.entry = entry
        super.init()
    }
}

@MainActor
private final class PTAcknowledgementCell: UICollectionViewCell, PTCellRegisterable {
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.numberOfLines = 0
        detailLabel.numberOfLines = 0
        titleLabel.textColor = .label
        detailLabel.textColor = .secondaryLabel
        PTUIAccessibility.applyDynamicType(to: titleLabel, font: .preferredFont(forTextStyle: .body))
        PTUIAccessibility.applyDynamicType(to: detailLabel, font: .preferredFont(forTextStyle: .footnote))
        let stack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        stack.axis = .vertical
        stack.spacing = 4
        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16))
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(entry: PTAcknowledgement, configuration: PTAcknowledgementsConfiguration) {
        titleLabel.text = entry.name
        var details: [String] = []
        if configuration.showsVersions, let version = entry.version {
            details.append(version)
        }
        if configuration.showsSourceBadges, !entry.sourceManagers.isEmpty {
            details.append(entry.sourceManagers.map(\.rawValue).joined(separator: " / "))
        }
        details.append(entry.licenseExpression ?? "UNKNOWN")
        detailLabel.text = details.joined(separator: " · ")
        accessibilityLabel = [titleLabel.text, detailLabel.text].compactMap { $0 }.joined(separator: ", ")
        accessibilityTraits = [.button]
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        detailLabel.text = nil
        accessibilityLabel = nil
        accessibilityTraits = []
    }
}

@MainActor
private final class PTAcknowledgementsHeader: PTBaseCollectionReusableView, @MainActor PTSupplementaryRegisterable {
    static let reuseID = String(describing: PTAcknowledgementsHeader.self)
    static let kind = UICollectionView.elementKindSectionHeader

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    private func configureView() {
        titleLabel.numberOfLines = 1
        titleLabel.textColor = .secondaryLabel
        PTUIAccessibility.applyDynamicType(to: titleLabel, font: .preferredFont(forTextStyle: .subheadline))
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-4)
        }
    }

    func configure(title: String?) {
        titleLabel.text = title
        accessibilityLabel = title
    }
}

@MainActor
public final class PTAcknowledgementsViewController: PTSearchViewController<PTAcknowledgement> {
    private let configuration: PTAcknowledgementsConfiguration
    private let dataSource: any PTAcknowledgementsDataSource
    private let additionalEntries: [PTAcknowledgement]
    private var manifest: PTLicenseManifest?
    private var loadTask: Task<Void, Never>?

    public init(configuration: PTAcknowledgementsConfiguration = .init(),
                dataSource: any PTAcknowledgementsDataSource = PTBundleAcknowledgementsDataSource(),
                additionalEntries: [PTAcknowledgement] = []) {
        self.configuration = configuration
        self.dataSource = dataSource
        self.additionalEntries = additionalEntries
        let searchConfiguration = PTSearchConfiguration(
            minimumCharacters: 1,
            searchWhileTyping: true,
            searchOnReturn: true,
            clearOnCancel: true,
            clearOnEmptyKeyword: true,
            keepsPreviousResultsWhileLoading: true,
            showsCancelButton: false,
            dismissKeyboardOnScroll: true,
            dismissKeyboardOnSelection: true,
            automaticallyShowsHistory: false,
            automaticallyShowsSuggestions: false,
            enablesPagination: false,
            enablesRefresh: false,
            mode: .custom,
            placement: configuration.showsSearchBar ? .contentTop : .custom
        )
        super.init(configuration: searchConfiguration)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    deinit {
        loadTask?.cancel()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        pt_Title = configuration.title
        collectionView.contentCollectionView.register(PTAcknowledgementCell.self,
                                                       forCellWithReuseIdentifier: PTAcknowledgementCell.reuseID)
        collectionView.contentCollectionView.register(PTAcknowledgementsHeader.self,
                                                       forSupplementaryViewOfKind: PTAcknowledgementsHeader.kind,
                                                       withReuseIdentifier: PTAcknowledgementsHeader.reuseID)
        loadManifest()
    }

    public override func configureListView(_ listView: PTCollectionView) {
        super.configureListView(listView)
        listView.cellInCollection = { [weak self] collectionView, _, indexPath in
            guard let self,
                  let row = self.collectionView.getRow(at: indexPath),
                  let box = row.dataModel as? PTAcknowledgementRowBox else { return nil }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PTAcknowledgementCell.reuseID,
                                                          for: indexPath)
            (cell as? PTAcknowledgementCell)?.configure(entry: box.entry, configuration: self.configuration)
            return cell
        }
        listView.collectionDidSelect = { [weak self] _, _, indexPath in
            guard let self,
                  let row = self.collectionView.getRow(at: indexPath),
                  let box = row.dataModel as? PTAcknowledgementRowBox else { return }
            self.didSelect(item: box.entry, at: indexPath)
        }
        listView.headerInCollection = { kind, collectionView, section, indexPath in
            guard kind == PTAcknowledgementsHeader.kind,
                  let title = section.headerTitle,
                  !title.isEmpty else { return nil }
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: PTAcknowledgementsHeader.reuseID,
                for: indexPath
            ) as? PTAcknowledgementsHeader
            header?.configure(title: title)
            return header
        }
    }

    public override func search(keyword: String) async throws -> [PTAcknowledgement] {
        guard let manifest else { throw PTSearchError.providerUnavailable }
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? manifest.entries : manifest.search(trimmed)
    }

    public override func makeResultSections(for items: [PTAcknowledgement]) -> [PTSection] {
        let groupedEntries: [(String?, [PTAcknowledgement])]
        switch configuration.grouping {
        case .none:
            groupedEntries = [(configuration.header, items)]
        case .name:
            groupedEntries = grouped(items) { String($0.name.prefix(1)).uppercased() }
        case .sourceManager:
            groupedEntries = grouped(items) { $0.sourceManagers.first?.rawValue ?? "Unknown" }
        case .licenseType:
            groupedEntries = grouped(items) { $0.licenseExpression ?? "UNKNOWN" }
        }

        return groupedEntries.enumerated().map { index, group in
            let title = group.0
            let rows = group.1.map { entry in
                let row = PTRows(title: entry.name,
                                 ID: PTAcknowledgementCell.reuseID,
                                 diffId: "PTAcknowledgements.entry.\(entry.id)",
                                 dataModel: PTAcknowledgementRowBox(entry: entry))
                row.cellClass = PTAcknowledgementCell.self
                return row
            }
            let section = PTSection(identifier: "PTAcknowledgements.section.\(index).\(title ?? "all")",
                                    headerTitle: title,
                                    headerID: title?.isEmpty == false ? PTAcknowledgementsHeader.reuseID : nil,
                                    rows: rows)
            if title?.isEmpty == false {
                section.headerClass = PTAcknowledgementsHeader.self
                section.headerHeight = 36
            }
            return section
        }
    }

    public override func didSelect(item: PTAcknowledgement, at indexPath: IndexPath) {
        let detail = PTAcknowledgementDetailViewController(entry: item)
        navigationController?.pushViewController(detail, animated: true)
    }

    private func grouped(_ items: [PTAcknowledgement], by key: (PTAcknowledgement) -> String) -> [(String?, [PTAcknowledgement])] {
        let values = Dictionary(grouping: items, by: key)
        return values.keys.sorted().map { value in
            (value, values[value, default: []].sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            })
        }
    }

    private func loadManifest() {
        loadTask?.cancel()
        let source = dataSource
        let extras = additionalEntries
        loadTask = Task { @MainActor [weak self] in
            do {
                let loaded = try await source.loadManifest()
                let result: PTLicenseManifest
                if extras.isEmpty {
                    result = loaded
                } else {
                    result = try loaded.merging(try PTAcknowledgementsProvider.make(entries: extras))
                }
                guard let self, !Task.isCancelled else { return }
                self.manifest = result
                self.setResults(result.entries, animated: false)
            } catch {
                guard let self, !Task.isCancelled else { return }
                self.setResults([], animated: false)
            }
        }
    }
}
#endif
