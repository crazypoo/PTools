//
//  PTVideoEditorToolsCropControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 12/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

class PTVideoEditorToolsCropControl: PTBaseViewController {

    var cropImageHandler:((CGSize,CGRect)->Void)!
    
    private var cropView: CropPickerView = {
        let view = CropPickerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.cropLineColor = .white
        view.dimBackgroundColor = UIColor(white: 0, alpha: 0.6)
        return view
    }()

    private let image: UIImage

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.clipsToBounds = true
        self.view.backgroundColor = .black
        self.view.addSubview(self.cropView)
        self.cropView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + 10)
        }

        DispatchQueue.main.async {
            self.cropView.image(self.image, isMin: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(self.closeTab(_:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Crop", style: .plain, target: self, action: #selector(self.cropTab(_:)))

        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = .black
        self.navigationController?.navigationBar.backgroundColor = .black
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }

    @objc private func closeTab(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func cropTab(_ sender: UIButton) {
        self.cropView.crop { [weak self] (crop) in
            guard let self = self else { return }
            if let error = crop.error {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Confirm", style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                }
                return
            }
            if let cropFrame = crop.cropFrame, let imageSize = crop.imageSize {
                self.dismiss(animated: true) {
                    self.cropImageHandler(imageSize,cropFrame)
                }
            }
        }
    }
}
