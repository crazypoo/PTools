//
//  PTDocumentViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 18/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

@available(iOS 17.0, *)
class PTDocumentViewController: PTBaseViewController {
    public var rootDirectoryPath = FileManager.pt.getFileDirectory(type: .Directory)

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let documentViewController = CustomDocumentViewController(document: UIDocument(fileURL: rootDirectoryPath))
        documentViewController.openDocument { _ in
            PTNSLogConsole("打开文档")
        }
        navigationController?.pushViewController(documentViewController, animated: true)
    }
}

@available(iOS 17.0, *)
class CustomDocumentViewController: UIDocumentViewController {
    override func documentDidOpen() {
        PTNSLogConsole(#function)
    }

    override func navigationItemDidUpdate() {
        navigationItem.title = "打开/关闭文档"
    }
}
