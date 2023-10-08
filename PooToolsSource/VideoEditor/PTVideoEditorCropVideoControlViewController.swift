//
//  PTVideoEditorCropVideoControlViewController.swift
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

class PTVideoEditorCropVideoControlViewController: PTBaseViewController {
    // MARK: Inner Types

    enum Section: Hashable {
        case main
    }

    typealias Datasource = UICollectionViewDiffableDataSource<Section, PTVideoEditorCroppingPresetCellViewModel>

    // MARK: Public Properties

    var didSelectCroppingPreset = PassthroughSubject<PTVideoEditorCroppingPreset?, Never>()

    override var tabBarItem: UITabBarItem! {
        get {
            UITabBarItem(
                title: "Crop",
                image: UIImage.podBundleImage("Crop"),
                selectedImage: UIImage.podBundleImage("Crop")
            )
        }
        set {}
    }

    // MARK: Private Properties

    private lazy var collectionView: UICollectionView = makeCollectionView()

    private var datasource: Datasource!

    // MARK: Init

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_hideBaseNavBar = true
#endif
        setupUI()

        loadPresets()
    }

}

// MARK: Data

fileprivate extension PTVideoEditorCropVideoControlViewController {
    func loadPresets() {
        let viewModels = PTVideoEditorCroppingPreset.allCases.map(PTVideoEditorCroppingPresetCellViewModel.init)
        var snapshot = NSDiffableDataSourceSnapshot<Section, PTVideoEditorCroppingPresetCellViewModel>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModels, toSection: .main)
        datasource.apply(snapshot, animatingDifferences: true)
    }
}

fileprivate extension PTVideoEditorCropVideoControlViewController {
    func setupUI() {
        setupView()
        setupConstraints()
        setupCollectionView()
    }

    func setupView() {
        view.backgroundColor = .white

        view.addSubview(collectionView)
    }

    func setupConstraints() {
        collectionView.snp.makeConstraints { make in
            make.height.equalToSuperview()
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    func setupCollectionView() {
        let identifier = "CroppingPresetView"
        collectionView.delegate = self
        collectionView.register(PTVideoEditorCroppingPresetCell.self, forCellWithReuseIdentifier: identifier)
        datasource = Datasource(collectionView: collectionView) { collectionView, indexPath, preset in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: identifier,
                for: indexPath
            ) as! PTVideoEditorCroppingPresetCell

            cell.configure(with: preset)
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
        return view
    }
}

extension PTVideoEditorCropVideoControlViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 90, height: 100)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let cell = collectionView.cellForItem(at: indexPath) as? PTVideoEditorCroppingPresetCell else {
            return false
        }

        if cell.isSelected {
            collectionView.deselectItem(at: indexPath, animated: false)
            didSelectCroppingPreset.send(nil)
            return false
        } else {
            return true
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? PTVideoEditorCroppingPresetCell else {
            return
        }

        guard let viewModel = datasource.itemIdentifier(for: indexPath) else {
            return
        }

        if cell.isSelected {
            didSelectCroppingPreset.send(viewModel.croppingPreset)
        }
    }
}
