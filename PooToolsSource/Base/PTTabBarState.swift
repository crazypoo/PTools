// English: Keeps mutable tab selection and layout state separate from the view facade.
// Español: Mantiene separado del facade el estado mutable de selección y layout del tab.
// 中文：将 Tab 选择和布局的可变状态从 View 门面中拆出。

import UIKit

@MainActor
struct PTTabBarState {
    var currentIndex: Int = 0
    var layoutStyle: PTTabBarLayoutStyle = .normal
}
