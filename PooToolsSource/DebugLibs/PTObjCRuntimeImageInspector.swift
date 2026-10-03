//
//  PTObjCRuntimeImageInspector.swift
//  PooTools
//
// English: Reports Objective-C runtime visibility explicitly; an empty result is not a load failure.
// Español: Informa explícitamente la visibilidad del runtime Objective-C; un resultado vacío no es un fallo de carga.
// 中文：明确表达 Objective-C Runtime 可见性，空结果不再代表镜像加载失败。
//

import Foundation
import ObjectiveC

enum PTObjCRuntimeImageInspector {
    static func inspect(path: String) -> PTObjCClassInspectionResult {
        guard !path.isEmpty else {
            return .unavailable(reason: "Image path unavailable")
        }

        var classCount: UInt32 = 0
        let result: PTObjCClassInspectionResult = path.withCString { imagePath in
            guard let classNames = objc_copyClassNamesForImage(imagePath, &classCount) else {
                return classCount == 0 ? .loaded([]) : .failed(message: "Runtime class buffer unavailable")
            }

            defer { free(classNames) }
            var names: [String] = []
            names.reserveCapacity(Int(classCount))
            for index in 0..<Int(classCount) {
                names.append(String(cString: classNames[index]))
            }
            return .loaded(names.sorted())
        }
        return result
    }
}
