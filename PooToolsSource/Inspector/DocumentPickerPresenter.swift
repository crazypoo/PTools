//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class DocumentPickerPresenter: NSObject, UIDocumentPickerDelegate {
    private let onPickDocumentHandler: ([URL]) -> Void

    init(onPickDocument: @escaping ([URL]) -> Void) {
        onPickDocumentHandler = onPickDocument
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        onPickDocumentHandler(urls)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}
