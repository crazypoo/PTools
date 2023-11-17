//
//  PTTipsDemoController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 17/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import TipKit
import SnapKit

//@available(iOS 17.0,*)
//struct CatTracksFeatureTip: Tip {
//    var title: Text { Text("Sample tip title")}
//    var message: Text? { Text("Sample tip message")}
//    var image: Image? { Image(systemName: "globe")}
//}
//
//@available(iOS 17.0,*)
//class PTTipsDemoController: PTBaseViewController {
//    private var catTracksFeatureTip = CatTracksFeatureTip()
//    private var tipObservationTask: Task<Void, Never>?
//    private weak var tipView: TipUIView?
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        tipObservationTask = tipObservationTask ?? Task { @MainActor in
//            for await shouldDisplay in catTracksFeatureTip.shouldDisplayUpdates {
//                if shouldDisplay {
//                    let tipHostingView = TipUIView(catTracksFeatureTip)
//                    tipHostingView.translatesAutoresizingMaskIntoConstraints = false
//
//                    view.addSubview(tipHostingView)
//                    tipHostingView.snp.makeConstraints { make in
//                        make.edges.equalToSuperview()
//                    }
//
//                    tipView = tipHostingView
//                } else {
//                    tipView?.removeFromSuperview()
//                    tipView = nil
//                }
//            }
//            PTNSLogConsole("12312312312312313")
//        }
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        tipObservationTask?.cancel()
//        tipObservationTask = nil
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//    }
//}

// MARK: - UIViewController
@available(iOS 17.0,*)
class PTTipsDemoController: PTBaseViewController {
    lazy var button: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        button.setTitle("显示Tip", for: .normal)
        button.center = view.center
        button.addTarget(self, action: #selector(showTip), for: .touchUpInside)
        return button
    }()
    // TipUIPopoverViewController
    var tipUIPopoverViewController: TipUIPopoverViewController?
    // TipUIView
    lazy var tipUIView: TipUIView = {
        let tipUIView = TipUIView(operationTip, arrowEdge: .bottom)
        tipUIView.backgroundColor = .black
        tipUIView.tintColor = .red
        tipUIView.cornerRadius = 6.0
        tipUIView.imageSize = CGSize(width: 40, height: 40)
        tipUIView.translatesAutoresizingMaskIntoConstraints = false
        return tipUIView
    }()

    // Tip
    var searchTip = SearchTip(tipTitles: "13123123123123")
    var operationTip = OperationTip()
    var searchTipObservationTask: Task<Void, Never>?
    var operationTipObservationTask: Task<Void, Never>?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemTeal
        view.addSubview(button)

        searchTip.actions.enumerated().forEach { index,value in
            if value.id == "id_more" {
                PTNSLogConsole("12312312312398989898989898989")
            }
        }
        Task {
            await SearchTip.appOpenedCount.donate()
        }
    }

    @objc func showTip() {
//        Task.init {
//            do {
//                try? Tips.resetDatastore()
//            }
//        }
        Tips.showAllTipsForTesting()

        SearchTip.showTip = true
        // 显隐TipUIPopoverViewController
        searchTipObservationTask = searchTipObservationTask ?? Task { @MainActor in
            for await shouldDisplay in searchTip.shouldDisplayUpdates {
                if shouldDisplay {
                    tipUIPopoverViewController = TipUIPopoverViewController(searchTip, sourceItem: button)
                    self.present(tipUIPopoverViewController!, animated: true)
                } else {
                    tipUIPopoverViewController?.dismiss(animated: true, completion: nil)
                }
            }
            
            for await status in searchTip.statusUpdates {
                PTNSLogConsole("\(status)")
            }
        }

//        // 显隐TipUIView
//        operationTipObservationTask = operationTipObservationTask ?? Task { @MainActor in
//            for await shouldDisplay in operationTip.shouldDisplayUpdates {
//                if shouldDisplay {
//                    view.addSubview(tipUIView)
//                    NSLayoutConstraint.activate([
//                        tipUIView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
//                        tipUIView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20.0),
//                        tipUIView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20.0)
//                    ])
//                } else {
//                    tipUIView.removeFromSuperview()
//                }
//            }
//        }
    }
}
