//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

protocol ElementInspectorFormPanelDataSource {
    var numberOfSections: Int { get }

    func numberOfItems(in section: Int) -> Int

    func section(at section: Int) -> InspectorElementSection

    func item(at indexPath: IndexPath) -> InspectorElementSectionDataSource
}
