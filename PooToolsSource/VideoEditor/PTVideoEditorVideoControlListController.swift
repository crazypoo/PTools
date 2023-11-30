//
//  PTVideoEditorVideoControlListController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Combine
import SnapKit
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif

final class PTVideoEditorVideoControlListController: PTBaseViewController {

    // MARK: Inner Types

    enum Section: Hashable {
        case main
    }

    typealias Datasource = UICollectionViewDiffableDataSource<Section, PTVideoEditorVideoControlCellViewModel>

    // MARK: Public Properties

    var didSelectVideoControl = PassthroughSubject<PTVideoEditorVideoControl, Never>()

    // MARK: Private Properties

    private lazy var collectionView: UICollectionView = makeCollectionView()

    private var datasource: Datasource!

    private let viewFactory: PTVideoEditorViewFactoryProtocol
    private let store: PTVideoEditorVideoEditorStore

    // MARK: Init

    init(store: PTVideoEditorVideoEditorStore,
         viewFactory: PTVideoEditorViewFactoryProtocol) {
        self.store = store
        self.viewFactory = viewFactory
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

#if POOTOOLS_NAVBARCONTROLLER
        self.zx_hideBaseNavBar = true
#endif

        setupUI()

        loadVideoControls()
    }

}

// MARK: Data

fileprivate extension PTVideoEditorVideoControlListController {
    func loadVideoControls() {
        let viewModels = PTVideoEditorVideoControl.allCases.map(PTVideoEditorVideoControlCellViewModel.init)
        var snapshot = NSDiffableDataSourceSnapshot<Section, PTVideoEditorVideoControlCellViewModel>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModels, toSection: .main)
        datasource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: UI

fileprivate extension PTVideoEditorVideoControlListController {
    func setupUI() {
        setupView()
        setupConstraints()
        setupCollectionView()
    }

    func setupView() {
        view.backgroundColor = .background
        
        view.addSubview(collectionView)
    }

    func setupConstraints() {
        collectionView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.width.equalTo(270)
            make.centerX.equalToSuperview()
        }
    }

    func setupCollectionView() {
        let identifier = "VideoControlCell"
        collectionView.delegate = self
        collectionView.register(PTVideoEditorVideoControlCell.self, forCellWithReuseIdentifier: identifier)
        datasource = Datasource(collectionView: collectionView) { collectionView, indexPath, videoControl in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier,for: indexPath) as! PTVideoEditorVideoControlCell

            cell.configure(with: videoControl)
            cell.setNeedsLayout()
            cell.layoutIfNeeded()

            return cell
        }
    }

    func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2

        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.showsHorizontalScrollIndicator = false
        view.isScrollEnabled = false
        return view
    }
}

// MARK: Collection View Delegate Flow Layout

extension PTVideoEditorVideoControlListController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 90.0, height: 60.0)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let viewModel = datasource.itemIdentifier(for: indexPath) {
            didSelectVideoControl.send(viewModel.videoControl)
        }
    }
}
