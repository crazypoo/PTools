//
//  PTCollectionSkeletonLabViewController.swift
//  PooTools_Example
//
// English: Demonstrate the unified PTCollectionView skeleton without changing Diffable content.
// Español: Demuestra el skeleton unificado de PTCollectionView sin cambiar el contenido Diffable.
// 中文：演示统一的 PTCollectionView 骨架，同时不改变 Diffable 内容。
//

import UIKit
#if canImport(PToolsConstraintLayout)
import PToolsConstraintLayout
#endif
import SnapKit
import PooTools
import SnapKit

@MainActor
private final class PTCollectionSkeletonDemoCell: UICollectionViewCell {
    static let reuseIdentifier = "PTCollectionSkeletonDemoCell"

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        titleLabel.ptLayout.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
        }
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
    }

    required init?(coder: NSCoder) { nil }

    func render(row: PTRows) {
        titleLabel.text = row.title
        accessibilityLabel = row.title
    }
}

@MainActor
final class PTCollectionSkeletonLabViewController: PTBaseViewController {
    private let skeletonStyleControl = UISegmentedControl(items: ["Shimmer", "Pulse", "Solid", "None"])
    private let contentControl = UISegmentedControl(items: ["Block", "Card", "Avatar"])
    private let stateLabel = UILabel()
    private let showButton = UIButton(type: .system)
    private let hideButton = UIButton(type: .system)
    private let refreshButton = UIButton(type: .system)
    private let list: PTCollectionView

    init() {
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemHeight = 64
        config.cellLeadingSpace = 12
        config.cellTrailingSpace = 12
        config.contentTopSpace = 12
        config.contentBottomSpace = 12
        config.skeletonItemCount = 6
        config.skeletonCornerRadius = 10
        list = PTCollectionView(viewConfig: config)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Collection Skeleton Lab"
        view.backgroundColor = .systemBackground
        configureControls()
        reloadContent()
    }

    private func configureControls() {
        skeletonStyleControl.selectedSegmentIndex = 0
        contentControl.selectedSegmentIndex = 1
        skeletonStyleControl.addTarget(self, action: #selector(configurationChanged), for: .valueChanged)
        contentControl.addTarget(self, action: #selector(configurationChanged), for: .valueChanged)

        showButton.setTitle("Show", for: .normal)
        hideButton.setTitle("Hide", for: .normal)
        refreshButton.setTitle("Refresh Content", for: .normal)
        showButton.addTarget(self, action: #selector(showSkeleton), for: .touchUpInside)
        hideButton.addTarget(self, action: #selector(hideSkeleton), for: .touchUpInside)
        refreshButton.addTarget(self, action: #selector(refreshContent), for: .touchUpInside)

        stateLabel.font = .preferredFont(forTextStyle: .caption1)
        stateLabel.textColor = .secondaryLabel
        stateLabel.text = "Content"

        let controls = UIStackView(arrangedSubviews: [
            skeletonStyleControl,
            contentControl,
            showButton,
            hideButton,
            refreshButton,
            stateLabel
        ])
        controls.axis = .vertical
        controls.spacing = 8
        view.addSubview(controls)
        controls.ptLayout.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total + 12)
        }
        
        list.registerClassCells(classs: [PTCollectionSkeletonDemoCell.reuseIdentifier: PTCollectionSkeletonDemoCell.self])
        list.cellInCollectionV2 = { collectionView, context in
            collectionView.dequeueReusableCell(withReuseIdentifier: PTCollectionSkeletonDemoCell.reuseIdentifier,
                                                for: context.indexPath)
        }
        list.configureCell = { _, cell, context in
            (cell as? PTCollectionSkeletonDemoCell)?.render(row: context.row)
        }
        view.addSubview(list)
        list.ptLayout.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(controls.ptLayout.bottom)
        }
    }

    private func reloadContent() {
        let rows = (0..<8).map { index in
            PTRows(title: "Content row \(index + 1)",
                   ID: PTCollectionSkeletonDemoCell.reuseIdentifier,
                   diffId: "skeleton-demo-\(index)")
        }
        list.showCollectionDetail(collectionData: [PTSection(identifier: "skeleton-demo", rows: rows)], animated: false)
        stateLabel.text = "Content: \(rows.count) rows"
    }

    private var selectedAnimation: PTCollectionSkeletonAnimationStyle {
        switch skeletonStyleControl.selectedSegmentIndex {
        case 1: return .pulse
        case 2: return .solid
        case 3: return .none
        default: return .shimmer
        }
    }

    private var selectedContent: PTCollectionSkeletonContent {
        switch contentControl.selectedSegmentIndex {
        case 1: return .card
        case 2: return .avatarText
        default: return .block
        }
    }

    private var skeletonConfiguration: PTCollectionSkeletonConfiguration {
        PTCollectionSkeletonConfiguration(
            layout: PTCollectionSkeletonLayout(itemHeight: 64,
                                                verticalSpacing: 12,
                                                cornerRadius: 10),
            appearance: PTCollectionSkeletonAppearance(),
            animation: PTCollectionSkeletonAnimation(style: selectedAnimation),
            transition: .crossDissolve(duration: 0.2),
            content: selectedContent,
            itemCountMode: .fillViewport(extraRows: 1),
            interactionPolicy: .blocksTouches,
            minimumVisibleDuration: 0.35,
            accessibilityLabel: "内容加载中")
    }

    @objc private func configurationChanged() {
        guard list.isSkeletonVisible else { return }
        list.updateSkeleton(configuration: skeletonConfiguration)
    }

    @objc private func showSkeleton() {
        list.showSkeleton(configuration: skeletonConfiguration)
        stateLabel.text = "Skeleton: \(list.skeletonDiagnostics.itemCount) items"
    }

    @objc private func hideSkeleton() {
        list.hideSkeleton()
        stateLabel.text = "Content"
    }

    @objc private func refreshContent() {
        reloadContent()
    }
}
