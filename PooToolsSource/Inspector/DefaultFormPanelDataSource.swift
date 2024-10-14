//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

struct DefaultFormPanelDataSource: ElementInspectorFormPanelDataSource {
    private let sections: InspectorElementSections

    init(sections: InspectorElementSections) {
        self.sections = sections
    }

    var numberOfSections: Int {
        sections.count
    }

    func numberOfItems(in section: Int) -> Int {
        self.section(at: section).dataSources.count
    }

    func section(at section: Int) -> InspectorElementSection {
        sections[section]
    }

    func item(at indexPath: IndexPath) -> InspectorElementSectionDataSource {
        section(at: indexPath.section).dataSources[indexPath.row]
    }
}
