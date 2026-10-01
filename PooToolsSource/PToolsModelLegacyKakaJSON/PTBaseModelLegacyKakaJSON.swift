//
//  PTBaseModelLegacyKakaJSON.swift
//
// English: Restore the historical PTBaseModel KakaJSON hooks only when the legacy adapter is selected.
// Español: Restaura los hooks históricos de KakaJSON de PTBaseModel solo al seleccionar el adaptador legacy.
// 中文：只有显式选择 legacy 适配器时，才恢复 PTBaseModel 原有的 KakaJSON hook。
//

import Foundation
import KakaJSON
#if SWIFT_PACKAGE
import ptools
#endif

extension PTBaseModel: Convertible {
    public func kj_modelKey(from property: KakaJSON.Property) -> ModelPropertyKey {
        property.name
    }

    public func kj_modelValue(from jsonValue: Any?, _ property: KakaJSON.Property) -> Any? {
        jsonValue
    }
}
